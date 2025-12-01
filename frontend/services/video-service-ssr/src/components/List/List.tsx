// src/components/List/List.tsx
'use client';

import { ReactNode } from 'react';
import styles from './List.module.css';

interface ListProps {
  children: ReactNode;
  gap?: number;
  className?: string;
  autoHeight?: boolean;
  useGrid?: boolean;
}

export function List({ children, gap = 16, className, autoHeight = false, useGrid = true }: ListProps) {
  const gridStyle = { 
    '--gap': `${gap}px`
  } as React.CSSProperties;

  return (
    <div 
      className={`${styles['list']} ${className || ''} ${useGrid ? styles['list-grid'] : ''} ${autoHeight ? styles['auto-height'] : ''}`}
      style={gridStyle}
    >
      {children}
    </div>
  );
}

