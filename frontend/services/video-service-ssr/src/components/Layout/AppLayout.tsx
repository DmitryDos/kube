'use client';

import { ReactNode } from 'react';
import { Header } from './Header/Header';
import styles from './AppLayout.module.css';

interface AppLayoutProps {
  children: ReactNode;
}

export function AppLayout({ children }: AppLayoutProps) {
  return (
    <div className={styles['appLayout']}>
      <Header />
      <main className={styles['mainContent']}>
        {children}
      </main>
    </div>
  );
}

