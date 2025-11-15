// src/components/SearchResults/SearchResults.tsx
'use client';

import { ReactNode, Children } from 'react';
import { List } from '../List/List';
import styles from './SearchResults.module.css';

interface SearchResultsProps {
  children: ReactNode;
  isLoading?: boolean;
  error?: string | null;
  isEmpty?: boolean;
  emptyMessage?: string;
  emptyHint?: string;
  onRetry?: () => void;
  columns?: number;
  gap?: number;
}

export function SearchResults({
  children,
  isLoading = false,
  error = null,
  isEmpty = false,
  emptyMessage,
  emptyHint,
  onRetry,
  columns = 2,
  gap = 12,
}: SearchResultsProps) {
  if (isLoading) {
    return (
      <div className={styles['loading']}>
        <div className={styles['spinner']}></div>
        <p>Ищем...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles['error']}>
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
        <p>{error}</p>
        {onRetry && (
          <button onClick={onRetry} className={styles['retry-button']}>
            Повторить
          </button>
        )}
      </div>
    );
  }

  // Проверяем, есть ли children
  const hasChildren = Children.count(children) > 0;

  if (isEmpty) {
    return (
      <div className={styles['empty']}>
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.35-4.35" />
        </svg>
        {emptyMessage && <p>{emptyMessage}</p>}
        {emptyHint && <p className={styles['empty-hint']}>{emptyHint}</p>}
      </div>
    );
  }

  if (!hasChildren) {
    return null;
  }

  return (
    <List gap={gap} columns={columns} autoHeight={true}>
      {children}
    </List>
  );
}

