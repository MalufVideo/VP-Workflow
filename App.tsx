import React from 'react';
import { Board } from './components/Board';
import { Layout, Sun, Moon, Languages } from 'lucide-react';
import { AppProvider, useApp } from './contexts/AppContext';

const AppContent: React.FC = () => {
  const { t, theme, toggleTheme, language, setLanguage } = useApp();

  return (
    <div className="flex flex-col h-screen bg-gray-50 dark:bg-slate-950 text-gray-900 dark:text-slate-100 transition-colors duration-300">
      {/* Navbar */}
      <header className="h-16 bg-white dark:bg-slate-900 border-b border-gray-200 dark:border-slate-800 flex items-center px-6 shadow-sm z-10 flex-shrink-0 transition-colors duration-300">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-600 rounded-lg shadow-sm">
            <Layout className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-800 dark:text-white tracking-tight">{t('app_title')}</h1>
            <p className="text-xs text-gray-500 dark:text-slate-400">{t('app_subtitle')}</p>
          </div>
        </div>
        
        <div className="ml-auto flex items-center gap-4">
             {/* Language Toggle */}
             <button 
                onClick={() => setLanguage(language === 'pt' ? 'en' : 'pt')}
                className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-gray-100 dark:bg-slate-800 hover:bg-gray-200 dark:hover:bg-slate-700 text-xs font-medium text-gray-700 dark:text-slate-300 transition-colors"
             >
                <Languages className="w-4 h-4" />
                <span>{language === 'pt' ? 'BR' : 'EN'}</span>
             </button>

             {/* Theme Toggle */}
             <button 
                onClick={toggleTheme}
                className="p-2 rounded-full bg-gray-100 dark:bg-slate-800 hover:bg-gray-200 dark:hover:bg-slate-700 text-gray-600 dark:text-yellow-400 transition-colors"
             >
                {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
             </button>

             <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-blue-500 to-purple-600 border-2 border-white dark:border-slate-700 shadow-sm"></div>
        </div>
      </header>

      {/* Main Board Area */}
      <main className="flex-1 overflow-hidden relative">
          <div className="absolute inset-0 overflow-x-auto overflow-y-hidden">
             <Board />
          </div>
      </main>
    </div>
  );
};

const App: React.FC = () => {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
}

export default App;
