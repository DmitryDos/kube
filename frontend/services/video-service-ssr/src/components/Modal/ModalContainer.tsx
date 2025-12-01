// src/components/Modal/ModalContainer.tsx
'use client';

import { ReactNode } from 'react';
import { useModal } from './ModalProvider';
import styles from './ModalContainer.module.css';

interface ModalContainerProps {
  title: string;
  leftButton?: ReactNode;
  bottomButton?: ReactNode;
  children: ReactNode;
}

export function ModalContainer({ title, leftButton, bottomButton, children }: ModalContainerProps) {
  const { dismiss } = useModal();

  return (
    <div className={styles['modal-container']} tabIndex={-1}>
      <div className={styles['modal-header']}>
        {leftButton ? (
          <div className={styles['modal-left-button']}>{leftButton}</div>
        ) : (
          <div className={styles['modal-spacer']} />
        )}
        
        <h2 className={styles['modal-title']}>{title}</h2>
        
        <button
          className={styles['modal-close-button']}
          onClick={dismiss}
          aria-label="Закрыть"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M18 6L6 18M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      <div className={styles['modal-content']}>
        {children}
      </div>
      
      {bottomButton && (
        <div className={styles['modal-bottom-button']}>
          {bottomButton}
        </div>
      )}
    </div>
  );
}

