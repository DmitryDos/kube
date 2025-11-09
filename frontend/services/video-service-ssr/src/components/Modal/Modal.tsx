'use client';

import { useEffect, useRef } from 'react';
import { useModal } from '../../contexts/ModalContext';
import styles from './Modal.module.css';

export function Modal() {
  const { modals, closeModal } = useModal();
  const modalRefs = useRef<Map<string, HTMLDivElement>>(new Map());

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && modals.length > 0) {
        closeModal(modals[modals.length - 1].id);
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [modals, closeModal]);

  if (modals.length === 0) return null;

  return (
    <>
      {modals.map((modal, index) => (
        <div
          key={modal.id}
          className={styles['overlay']}
          style={{ zIndex: 1000 + index }}
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              closeModal(modal.id);
            }
          }}
        >
          <div
            ref={(el) => {
              if (el) modalRefs.current.set(modal.id, el);
            }}
            className={styles['modal']}
            onClick={(e) => e.stopPropagation()}
          >
            <div className={styles['header']}>
              {modal.leftButton && (
                <button
                  className={styles['leftButton']}
                  onClick={modal.leftButton.onClick}
                >
                  {modal.leftButton.label}
                </button>
              )}
              {modal.title && (
                <h2 className={styles['title']}>{modal.title}</h2>
              )}
              <button
                className={styles['closeButton']}
                onClick={() => closeModal(modal.id)}
                aria-label="Закрыть"
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M18 6L6 18M6 6l12 12" />
                </svg>
              </button>
            </div>
            <div className={styles['content']}>
              {modal.iframeUrl ? (
                <iframe
                  src={modal.iframeUrl}
                  className={styles['iframe']}
                  frameBorder="0"
                  allowFullScreen
                />
              ) : (
                modal.content
              )}
            </div>
            {modal.bottomButton && (
              <div className={styles['footer']}>
                <button
                  className={styles['bottomButton']}
                  onClick={modal.bottomButton.onClick}
                >
                  {modal.bottomButton.label}
                </button>
              </div>
            )}
          </div>
        </div>
      ))}
    </>
  );
}

