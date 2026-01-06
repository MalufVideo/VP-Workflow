export enum AttachmentType {
  IMAGE = 'IMAGE',
  VIDEO = 'VIDEO',
  FILE = 'FILE'
}

export interface Attachment {
  id: string;
  type: AttachmentType;
  url: string; // In a real app, this would be a Supabase Storage URL
  name: string;
  createdAt: number;
}

export interface Comment {
  id: string;
  text: string;
  author: string;
  createdAt: number;
}

export enum LogAction {
  CREATED = 'CREATED',
  MOVED = 'MOVED',
  COMMENT_ADDED = 'COMMENT_ADDED',
  ATTACHMENT_ADDED = 'ATTACHMENT_ADDED',
  UPDATED = 'UPDATED'
}

export interface LogEntry {
  id: string;
  action: LogAction;
  timestamp: number;
  details: string; // e.g., "Moved from To Do to Done"
}

export interface CardData {
  id: string;
  columnId: string;
  title: string;
  description: string;
  attachments: Attachment[];
  comments: Comment[];
  history: LogEntry[];
  
  // Time Tracking
  createdAt: number;
  lastMovedAt: number; // Timestamp when it entered the current column
  timeInColumns: Record<string, number>; // Map of ColumnID -> Total Milliseconds spent
}

export interface ColumnData {
  id: string;
  title: string;
  order: number;
}
