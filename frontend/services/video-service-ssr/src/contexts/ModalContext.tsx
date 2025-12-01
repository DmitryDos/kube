'use client';

import { createContext, useContext, ReactNode, useState, useCallback } from 'react';

export interface ModalConfig {
  id: string;
  title?: string;
  content?: ReactNode;
  iframeUrl?: string;
  leftButton?: {
    label: string;
    onClick: () => void;
  };
  bottomButton?: {
    label: string;
    onClick: () => void;
  };
  onClose?: () => void;
}

interface ModalContextType {
  modals: ModalConfig[];
  openModal: (config: ModalConfig) => void;
  closeModal: (id: string) => void;
  closeAllModals: () => void;
}

const ModalContext = createContext<ModalContextType | null>(null);

export function ModalProvider({ children }: { children: ReactNode }) {
  const [modals, setModals] = useState<ModalConfig[]>([]);

  const openModal = useCallback((config: ModalConfig) => {
    setModals((prev) => [...prev, config]);
  }, []);

  const closeModal = useCallback((id: string) => {
    setModals((prev) => {
      const modal = prev.find((m) => m.id === id);
      if (modal?.onClose) {
        modal.onClose();
      }
      return prev.filter((m) => m.id !== id);
    });
  }, []);

  const closeAllModals = useCallback(() => {
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
    <ModalContext.Provider value={{ modals, openModal, closeModal, closeAllModals }}>
      {children}
    </ModalContext.Provider>
  );
}

export function useModal() {
  const context = useContext(ModalContext);
  if (!context) {
    throw new Error('useModal must be used within ModalProvider');
  }
  return context;
}

