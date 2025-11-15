// src/components/List/List.tsx
'use client';

import { ReactNode } from 'react';
import styles from './List.module.css';

interface ListProps {
  children: ReactNode;
  gap?: number;
  columns?: number;
  className?: string;
  autoHeight?: boolean;
}

export function List({ children, gap = 16, columns, className, autoHeight = false }: ListProps) {
  const gridStyle = { 
    '--gap': `${gap}px`,
    '--columns': columns || 'auto'
  } as React.CSSProperties;

  return (
    <div 
      className={`${styles['list']} ${className || ''} ${columns ? styles['list-grid'] : ''} ${autoHeight ? styles['auto-height'] : ''}`}
      style={gridStyle}
      data-columns={columns}
    >
      {children}
    </div>
  );
}

