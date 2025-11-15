// src/components/AddTrackModal/AddTrackModal.tsx
'use client';

import { useState } from 'react';
import { ModalContainer } from '../Modal/ModalContainer';
import { useModal } from '../Modal/ModalProvider';
import { Video } from '../../types';
import styles from './AddTrackModal.module.css';

interface AddTrackModalProps {
  onTrackAdded?: (video: Video) => void;
}

export function AddTrackModal({ onTrackAdded }: AddTrackModalProps) {
  const { dismiss } = useModal();
  const [url, setUrl] = useState('');
  const [title, setTitle] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSave = async () => {
    // TODO: Реализовать загрузку трека
    setIsLoading(true);
    // Заглушка
    setTimeout(() => {
      setIsLoading(false);
      // onTrackAdded?.(mockVideo);
      dismiss();
    }, 1000);
  };

  return (
    <ModalContainer
      title="Добавить трек"
      bottomButton={
        <button
          className={styles['save-button']}
          onClick={handleSave}
          disabled={isLoading || !url.trim()}
        >
          {isLoading ? 'Загрузка...' : 'Сохранить трек'}
        </button>
      }
    >
      <div className={styles['add-track-content']}>
        <div className={styles['input-group']}>
          <label className={styles['label']}>URL видео или аудио</label>
          <input
            type="url"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="https://example.com/video"
            className={styles['input']}
          />
        </div>

        <div className={styles['input-group']}>
          <label className={styles['label']}>Название трека</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Введите название"
            className={styles['input']}
          />
        </div>

        <div className={styles['placeholder']}>
          <p>Заглушка модалки добавления трека</p>
          <p className={styles['placeholder-note']}>
            Здесь будет форма загрузки файла или URL
          </p>
        </div>
      </div>
    </ModalContainer>
  );
}

