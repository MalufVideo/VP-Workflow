import React, { useState, useEffect, useMemo } from 'react';
import { 
  DndContext, 
  closestCorners, 
  KeyboardSensor, 
  PointerSensor, 
  useSensor, 
  useSensors, 
  DragOverlay,
  DragStartEvent,
  DragOverEvent,
  DragEndEvent,
} from '@dnd-kit/core';
import { 
  arrayMove, 
  SortableContext, 
  sortableKeyboardCoordinates, 
  verticalListSortingStrategy,
  horizontalListSortingStrategy,
  useSortable
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { CardData, ColumnData, LogAction, LogEntry } from '../types';
import { INITIAL_COLUMNS, createNewCard } from '../constants';
import { Plus, Video, Image as ImageIcon, GripVertical, Trash2, X } from 'lucide-react';
import CardModal from './CardModal';
import { useApp } from '../contexts/AppContext';

// --- Sortable Card Component ---
interface SortableCardProps {
  card: CardData;
  onClick: () => void;
  t: (key: any, ...args: any[]) => string;
}

const SortableCard: React.FC<SortableCardProps> = ({ card, onClick, t }) => {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: card.id, data: { type: 'Card', card } });

  const style = {
    transform: CSS.Translate.toString(transform),
    transition,
  };

  if (isDragging) {
    return (
      <div 
        ref={setNodeRef} 
        style={style} 
        className="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-lg opacity-40 h-[100px] border-2 border-blue-500"
      />
    );
  }

  const hasVideo = card.attachments.some(a => a.type === 'VIDEO');
  const hasImage = card.attachments.some(a => a.type === 'IMAGE');

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      onClick={onClick}
      className="bg-white dark:bg-slate-800 p-3 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 hover:border-gray-300 dark:hover:border-slate-600 hover:shadow-md transition-all cursor-grab active:cursor-grabbing group"
    >
      <h4 className="text-sm font-medium text-gray-800 dark:text-slate-200 mb-2 leading-tight">{card.title}</h4>
      <div className="flex justify-between items-end mt-2">
        <div className="flex gap-2">
           {hasImage && <div className="text-[10px] bg-purple-100 dark:bg-purple-900/40 text-purple-600 dark:text-purple-300 px-1.5 py-0.5 rounded flex items-center gap-1 border border-purple-200 dark:border-purple-800/50"><ImageIcon className="w-3 h-3"/> {t('image')}</div>}
           {hasVideo && <div className="text-[10px] bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-300 px-1.5 py-0.5 rounded flex items-center gap-1 border border-red-200 dark:border-red-800/50"><Video className="w-3 h-3"/> {t('video')}</div>}
        </div>
        <div className="text-[10px] text-gray-500 dark:text-slate-500">
           {card.comments.length > 0 && `${card.comments.length} ${t('comments_count')}`}
        </div>
      </div>
    </div>
  );
};

// --- Sortable Column Component ---
interface ColumnProps {
  column: ColumnData;
  cards: CardData[];
  onAddCard: () => void;
  onCardClick: (c: CardData) => void;
  onDeleteColumn: (id: string) => void;
  t: (key: any, ...args: any[]) => string;
}

const Column: React.FC<ColumnProps> = ({ column, cards, onAddCard, onCardClick, onDeleteColumn, t }) => {
  const { setNodeRef, attributes, listeners, transform, transition, isDragging } = useSortable({ 
    id: column.id, 
    data: { type: 'Column', column } 
  });

  const style = {
    transform: CSS.Translate.toString(transform),
    transition,
  };

  if (isDragging) {
    return (
        <div ref={setNodeRef} style={style} className="flex-shrink-0 w-72 bg-gray-100 dark:bg-slate-800/30 border-2 border-gray-200 dark:border-slate-700 border-dashed rounded-xl h-[500px]" />
    );
  }

  return (
    <div ref={setNodeRef} style={style} className="flex-shrink-0 w-72 flex flex-col max-h-full">
      <div className="bg-gray-100/80 dark:bg-slate-900/50 backdrop-blur-sm rounded-xl p-3 flex flex-col max-h-full border border-gray-200/60 dark:border-slate-800/60 group/column">
        {/* Header */}
        <div 
            {...attributes} 
            {...listeners}
            className="flex items-center justify-between mb-3 px-1 cursor-grab active:cursor-grabbing"
        >
            <div className="flex items-center gap-2">
                 <h3 className="font-semibold text-gray-700 dark:text-slate-300 text-sm uppercase tracking-wide">{column.title}</h3>
                <span className="text-xs font-mono text-gray-500 dark:text-slate-400 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 px-2 py-0.5 rounded-full">{cards.length}</span>
            </div>
            <button 
                onClick={(e) => {
                    e.preventDefault(); 
                    if(confirm(t('delete_column_confirm'))) onDeleteColumn(column.id);
                }}
                onMouseDown={(e) => e.stopPropagation()} // Prevent drag start
                className="text-gray-400 dark:text-slate-600 hover:text-red-500 dark:hover:text-red-400 opacity-0 group-hover/column:opacity-100 transition-opacity p-1"
            >
                <Trash2 className="w-4 h-4" />
            </button>
        </div>

        {/* Cards Area */}
        <div className="flex-1 overflow-y-auto space-y-2 min-h-[100px] pr-1">
          <SortableContext items={cards.map(c => c.id)} strategy={verticalListSortingStrategy}>
            {cards.map(card => (
              <SortableCard key={card.id} card={card} onClick={() => onCardClick(card)} t={t} />
            ))}
          </SortableContext>
        </div>

        {/* Footer */}
        <button 
          onClick={onAddCard}
          className="mt-3 flex items-center gap-2 text-gray-500 dark:text-slate-400 hover:text-gray-800 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-slate-800 p-2 rounded-lg transition-colors text-sm font-medium"
        >
          <Plus className="w-4 h-4" /> {t('add_card')}
        </button>
      </div>
    </div>
  );
};


export const Board: React.FC = () => {
  const { t } = useApp();
  const [columns, setColumns] = useState<ColumnData[]>(() => {
      const saved = localStorage.getItem('trackflow-columns');
      return saved ? JSON.parse(saved) : INITIAL_COLUMNS;
  });
  
  const [cards, setCards] = useState<CardData[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [selectedCardId, setSelectedCardId] = useState<string | null>(null);

  // Load initial card data
  useEffect(() => {
    const saved = localStorage.getItem('trackflow-cards');
    if (saved) {
      setCards(JSON.parse(saved));
    } else {
        setCards([createNewCard('col-todo', t('welcome_card'), t('card_created'))]);
    }
  }, []);

  // Persist cards
  useEffect(() => {
    if (cards.length > 0) {
        localStorage.setItem('trackflow-cards', JSON.stringify(cards));
    }
  }, [cards]);

  // Persist columns
  useEffect(() => {
    localStorage.setItem('trackflow-columns', JSON.stringify(columns));
  }, [columns]);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  const handleAddCard = (columnId: string) => {
    const title = prompt(t('enter_card_title'));
    if (!title) return;
    setCards([...cards, createNewCard(columnId, title, t('card_created'))]);
  };

  const handleAddColumn = () => {
    const title = prompt(t('enter_column_title'));
    if (!title) return;
    const newColumn: ColumnData = {
        id: `col-${Date.now()}`,
        title,
        order: columns.length
    };
    setColumns([...columns, newColumn]);
  };

  const handleDeleteColumn = (columnId: string) => {
      setColumns(columns.filter(c => c.id !== columnId));
      setCards(cards.filter(c => c.columnId !== columnId));
  };

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  const handleDragOver = (event: DragOverEvent) => {
    const { active, over } = event;
    if (!over) return;

    const activeId = active.id;
    const overId = over.id;

    if (activeId === overId) return;

    const isActiveTask = active.data.current?.type === 'Card';
    const isOverTask = over.data.current?.type === 'Card';

    if (!isActiveTask) return;

    // Implements dropping a task over another task
    if (isActiveTask && isOverTask) {
      setCards((cards) => {
        const activeIndex = cards.findIndex((t) => t.id === activeId);
        const overIndex = cards.findIndex((t) => t.id === overId);
        
        if (cards[activeIndex].columnId !== cards[overIndex].columnId) {
          cards[activeIndex].columnId = cards[overIndex].columnId;
          return arrayMove(cards, activeIndex, overIndex - 1);
        }

        return arrayMove(cards, activeIndex, overIndex);
      });
    }

    const isOverColumn = over.data.current?.type === 'Column';

    // Implements dropping a task over a column
    if (isActiveTask && isOverColumn) {
      setCards((cards) => {
        const activeIndex = cards.findIndex((t) => t.id === activeId);
        if (cards[activeIndex].columnId !== overId) {
            cards[activeIndex].columnId = overId as string;
            return [...cards]; 
        }
        return cards;
      });
    }
  };

  const handleDragEnd = (event: DragEndEvent) => {
    setActiveId(null);
    const { active, over } = event;
    if (!over) return;

    const activeId = active.id as string;
    const overId = over.id as string;

    // Handling Column Reordering
    if (active.data.current?.type === 'Column') {
        if (activeId !== overId) {
            setColumns((columns) => {
                const activeIndex = columns.findIndex(c => c.id === activeId);
                const overIndex = columns.findIndex(c => c.id === overId);
                return arrayMove(columns, activeIndex, overIndex);
            });
        }
        return;
    }

    // Handling Card Reordering / Moving
    const activeCardIndex = cards.findIndex(c => c.id === activeId);
    if (activeCardIndex === -1) return;

    const activeCard = cards[activeCardIndex];
    let newColumnId = activeCard.columnId;

    if (over.data.current?.type === 'Column') {
        newColumnId = overId;
    } else if (over.data.current?.type === 'Card') {
        newColumnId = cards.find(c => c.id === overId)?.columnId || activeCard.columnId;
    }

    if (activeCard.columnId !== newColumnId) {
        const now = Date.now();
        const oldColumnId = activeCard.columnId;
        const timeSpent = now - activeCard.lastMovedAt;
        
        const updatedTimeInColumns = {
            ...activeCard.timeInColumns,
            [oldColumnId]: (activeCard.timeInColumns[oldColumnId] || 0) + timeSpent
        };

        const oldColTitle = columns.find(c => c.id === oldColumnId)?.title;
        const newColTitle = columns.find(c => c.id === newColumnId)?.title;
        
        const logEntry: LogEntry = {
            id: `log-${now}`,
            action: LogAction.MOVED,
            timestamp: now,
            details: t('moved_from_to', oldColTitle || '?', newColTitle || '?')
        };

        const updatedCards = [...cards];
        updatedCards[activeCardIndex] = {
            ...activeCard,
            columnId: newColumnId,
            lastMovedAt: now,
            timeInColumns: updatedTimeInColumns,
            history: [logEntry, ...activeCard.history]
        };
        setCards(updatedCards);
    }
  };

  const handleCardUpdate = (updatedCard: CardData) => {
    setCards(cards.map(c => c.id === updatedCard.id ? updatedCard : c));
  };

  const activeColumn = activeId ? columns.find(c => c.id === activeId) : null;
  const activeCard = activeId ? cards.find(c => c.id === activeId) : null;
  const selectedCard = selectedCardId ? cards.find(c => c.id === selectedCardId) : null;

  return (
    <div className="flex h-full overflow-x-auto gap-6 p-6 items-start">
        <DndContext
            sensors={sensors}
            collisionDetection={closestCorners}
            onDragStart={handleDragStart}
            onDragOver={handleDragOver}
            onDragEnd={handleDragEnd}
        >
            <SortableContext items={columns.map(c => c.id)} strategy={horizontalListSortingStrategy}>
                {columns.map(col => (
                    <Column 
                        key={col.id} 
                        column={col} 
                        cards={cards.filter(c => c.columnId === col.id)}
                        onAddCard={() => handleAddCard(col.id)}
                        onCardClick={(c) => setSelectedCardId(c.id)}
                        onDeleteColumn={handleDeleteColumn}
                        t={t}
                    />
                ))}
            </SortableContext>

            {/* Add Column Button */}
            <button
                onClick={handleAddColumn}
                className="flex-shrink-0 w-12 h-12 flex items-center justify-center rounded-xl bg-gray-200 dark:bg-slate-800/50 border border-gray-300 dark:border-slate-700/50 hover:bg-gray-300 dark:hover:bg-slate-800 hover:text-gray-800 dark:hover:text-white text-gray-500 dark:text-slate-500 transition-colors"
                title={t('add_column')}
            >
                <Plus className="w-6 h-6" />
            </button>

            <DragOverlay>
                {activeColumn && (
                    <Column
                        column={activeColumn}
                        cards={cards.filter(c => c.columnId === activeColumn.id)}
                        onAddCard={() => {}}
                        onCardClick={() => {}}
                        onDeleteColumn={() => {}}
                        t={t}
                    />
                )}
                {activeCard && (
                    <div className="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-2xl border-2 border-blue-500 rotate-2 cursor-grabbing w-[280px]">
                        <h4 className="font-bold text-gray-800 dark:text-slate-100">{activeCard.title}</h4>
                    </div>
                )}
            </DragOverlay>
        </DndContext>

        {selectedCard && (
            <CardModal 
                card={selectedCard} 
                columns={columns}
                onClose={() => setSelectedCardId(null)}
                onUpdate={handleCardUpdate}
            />
        )}
    </div>
  );
};
