// src/components/EditVideoModal/EditVideoModal.tsx
'use client';

import { useState } from 'react';
import { ModalContainer } from '../Modal/ModalContainer';
import { useModal } from '../Modal/ModalProvider';
import { Video } from '../../types';
import { AsyncTrackImage } from '../AsyncTrackImage/AsyncTrackImage';
import styles from './EditVideoModal.module.css';

interface EditVideoModalProps {
  video: Video;
}

export function EditVideoModal({ video }: EditVideoModalProps) {
  const { dismiss } = useModal();
  const [title, setTitle] = useState(video.title);
  const [description, setDescription] = useState(video.description);
  const [hasChanges, setHasChanges] = useState(false);

  const handleSave = () => {
    // TODO: Реализовать сохранение изменений
    if (hasChanges) {
      console.log('Saving changes:', { title, description });
    }
    dismiss();
  };

  const handleDelete = () => {
    if (confirm(`Вы уверены, что хотите удалить видео "${video.title}"?`)) {
      // TODO: Реализовать удаление
      dismiss();
    }
  };

  return (
    <ModalContainer
      title="Редактировать трек"
      leftButton={
        <button
          className={styles['delete-button']}
          onClick={handleDelete}
          aria-label="Удалить"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
          </svg>
        </button>
      }
      bottomButton={
        <button
          className={styles['save-button']}
          onClick={handleSave}
          disabled={!hasChanges}
        >
          Сохранить
        </button>
      }
    >
      <div className={styles['edit-video-content']}>
        <div className={styles['thumbnail-wrapper']}>
          <AsyncTrackImage video={video} />
          <button
            className={styles['thumbnail-edit-button']}
            aria-label="Изменить обложку"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z" />
              <circle cx="12" cy="13" r="3" />
            </svg>
          </button>
        </div>

        <div className={styles['input-group']}>
          <label className={styles['label']}>Название</label>
          <input
            type="text"
            value={title}
            onChange={(e) => {
              setTitle(e.target.value);
              setHasChanges(title !== e.target.value || description !== video.description);
            }}
            placeholder="Введите название"
            className={styles['input']}
            autoFocus={false}
            tabIndex={0}
          />
        </div>

        <div className={styles['input-group']}>
          <label className={styles['label']}>Описание</label>
          <textarea
            value={description}
            onChange={(e) => {
              setDescription(e.target.value);
              setHasChanges(title !== video.title || description !== e.target.value);
            }}
            placeholder="Введите описание"
            className={styles['textarea']}
            rows={4}
            autoFocus={false}
            tabIndex={0}
          />
        </div>

        <div className={styles['meta-info']}>
          <div className={styles['meta-item']}>
            <span className={styles['meta-label']}>Длительность</span>
            <span className={styles['meta-value']}>
              {Math.floor(video.duration / 60)}:{(video.duration % 60).toFixed(0).padStart(2, '0')}
            </span>
          </div>
          <div className={styles['meta-item']}>
            <span className={styles['meta-label']}>Добавлен</span>
            <span className={styles['meta-value']}>
              {new Date(video.created_at).toLocaleDateString('ru-RU')}
            </span>
          </div>
        </div>
      </div>
    </ModalContainer>
  );
}

