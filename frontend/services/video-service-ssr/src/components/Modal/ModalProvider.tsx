// src/components/Modal/ModalProvider.tsx
'use client';

import { createContext, useContext, ReactNode, useState, useCallback, useEffect } from 'react';
import styles from './ModalProvider.module.css';

export interface ModalItem {
  id: string;
  content: ReactNode;
  onClose?: () => void;
}

interface ModalProviderContextType {
  modals: ModalItem[];
  show: (content: ReactNode, onClose?: () => void) => string;
  replace: (content: ReactNode, onClose?: () => void) => string;
  dismiss: () => void;
  dismissAll: () => void;
}

const ModalProviderContext = createContext<ModalProviderContextType | null>(null);

export function ModalProvider({ children }: { children: ReactNode }) {
  const [modals, setModals] = useState<ModalItem[]>([]);

  const show = useCallback((content: ReactNode, onClose?: () => void): string => {
    const id = `modal-${Date.now()}-${Math.random()}`;
    setModals((prev) => [...prev, { id, content, onClose }]);
    return id;
  }, []);

  const replace = useCallback((content: ReactNode, onClose?: () => void): string => {
    const id = `modal-${Date.now()}-${Math.random()}`;
    setModals((prev) => {
      const last = prev[prev.length - 1];
      if (last?.onClose) {
        last.onClose();
      }
      return [...prev.slice(0, -1), { id, content, onClose }];
    });
    return id;
  }, []);

  const dismiss = useCallback(() => {
    setModals((prev) => {
      if (prev.length === 0) return prev;
      const last = prev[prev.length - 1];
      if (last?.onClose) {
        last.onClose();
      }
      return prev.slice(0, -1);
    });
  }, []);

  const dismissAll = useCallback(() => {
    setModals((prev) => {
      prev.forEach((modal) => {
        if (modal.onClose) {
          modal.onClose();
        }
      });
      return [];
    });
  }, []);

  return (
    <ModalProviderContext.Provider value={{ modals, show, replace, dismiss, dismissAll }}>
      {children}
      <ModalProviderView modals={modals} dismiss={dismiss} />
    </ModalProviderContext.Provider>
  );
}

function ModalProviderView({ 
  modals,
  dismiss
}: { 
  modals: ModalItem[];
  dismiss: () => void;
}) {
  // Убираем фокус с активного элемента при открытии модалки
  useEffect(() => {
    if (modals.length > 0) {
      const activeElement = document.activeElement as HTMLElement;
      if (activeElement && activeElement.blur) {
        activeElement.blur();
      }
    }
  }, [modals.length]);

  const handleOverlayClick = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    // Проверяем, что клик был именно на overlay, а не на содержимом модалки
    if (e.target === e.currentTarget) {
      dismiss();
    }
  }, [dismiss]);

  const handleOverlayWheel = useCallback((e: React.WheelEvent<HTMLDivElement>) => {
    // Закрываем при скролле тачпада на фоне
    if (e.target === e.currentTarget) {
      dismiss();
    }
  }, [dismiss]);

  if (modals.length === 0) {
    return null;
  }

  return (
    <div 
      className={styles['modal-overlay']}
      onClick={handleOverlayClick}
      onWheel={handleOverlayWheel}
    >
      {modals.map((modal, index) => (
        <div
          key={modal.id}
          className={styles['modal-wrapper']}
          style={{
            zIndex: 1000 + index,
          }}
          onClick={(e) => {
            // Предотвращаем закрытие при клике на содержимое модалки
            e.stopPropagation();
          }}
          onWheel={(e) => {
            // Предотвращаем закрытие при скролле внутри модалки
            e.stopPropagation();
          }}
          onMouseDown={(e) => {
            // Предотвращаем фокус на wrapper при клике
            if (e.target === e.currentTarget) {
              e.preventDefault();
            }
          }}
        >
          {modal.content}
        </div>
      ))}
    </div>
  );
}

export function useModal() {
  const context = useContext(ModalProviderContext);
  if (!context) {
    throw new Error('useModal must be used within ModalProvider');
  }
  return context;
}

