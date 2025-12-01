// src/components/EditPlaylistModal/EditPlaylistModal.tsx
'use client';

import { useState, useCallback, useEffect } from 'react';
import { ModalContainer } from '../Modal/ModalContainer';
import { useModal } from '../Modal/ModalProvider';
import { AddTrackModal } from '../AddTrackModal/AddTrackModal';
import { Playlist, Video } from '../../types';
import { VideoCard } from '../VideoCard/VideoCard';
import { List } from '../List/List';
import { useSearch } from '../../hooks/useSearch';
import styles from './EditPlaylistModal.module.css';

interface EditPlaylistModalProps {
  playlist: Playlist;
  onSave: (name: string, videoIds: string[]) => void;
  onDelete: () => void;
}

export function EditPlaylistModal({ playlist, onSave, onDelete }: EditPlaylistModalProps) {
  const { dismiss, show } = useModal();
  const [name, setName] = useState(playlist.name);
  const [selectedVideoIds, setSelectedVideoIds] = useState<Set<string>>(new Set(playlist.videoIds));
  const [availableVideos, setAvailableVideos] = useState<Video[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const { search } = useSearch();

  // Обновляем состояние при изменении playlist prop
  useEffect(() => {
    setName(playlist.name);
    setSelectedVideoIds(new Set(playlist.videoIds));
  }, [playlist.id, playlist.name, playlist.videoIds]);

  const loadAvailableVideos = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await search('', 1, 100, 'videos');
      const videos = response.results
        .filter((item) => item.type === 'video')
        .map((item) => item.data);
      setAvailableVideos(videos);
    } catch (error) {
      console.error('Error loading videos:', error);
    } finally {
      setIsLoading(false);
    }
  }, [search]);

  const handleToggleVideo = useCallback((videoId: string) => {
    setSelectedVideoIds((prev) => {
      const next = new Set(prev);
      if (next.has(videoId)) {
        next.delete(videoId);
      } else {
        next.add(videoId);
      }
      return next;
    });
  }, []);

  const handleSave = useCallback(() => {
    if (name.trim()) {
      onSave(name.trim(), Array.from(selectedVideoIds));
      dismiss();
    }
  }, [name, selectedVideoIds, onSave, dismiss]);

  const handleDelete = useCallback(() => {
    if (confirm(`Вы уверены, что хотите удалить плейлист "${playlist.name}"?`)) {
      onDelete();
      dismiss();
    }
  }, [playlist.name, onDelete, dismiss]);

  const handleAddNewTrack = useCallback(() => {
    show(<AddTrackModal onTrackAdded={(video: Video) => {
      setSelectedVideoIds((prev) => new Set([...prev, video.id]));
    }} />);
  }, [show]);

  return (
    <ModalContainer
      title={playlist.isSystem ? 'Просмотр плейлиста' : 'Редактировать плейлист'}
      leftButton={
        !playlist.isSystem ? (
          <button
            className={styles['delete-button']}
            onClick={handleDelete}
            aria-label="Удалить"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
            </svg>
          </button>
        ) : undefined
      }
      bottomButton={
        !playlist.isSystem ? (
          <button
            className={styles['save-button']}
            onClick={handleSave}
            disabled={!name.trim()}
          >
            Сохранить
          </button>
        ) : undefined
      }
    >
      <div className={styles['edit-playlist-content']}>
        <div className={styles['name-input-wrapper']}>
          <label className={styles['label']}>Название плейлиста</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Введите название"
            className={styles['name-input']}
            disabled={playlist.isSystem}
            autoFocus={false}
            tabIndex={0}
          />
        </div>

        <div className={styles['videos-section']}>
          <div className={styles['section-header']}>
            <h3 className={styles['section-title']}>Видео в плейлисте</h3>
            {!playlist.isSystem && (
              <button
                className={styles['add-button']}
                onClick={handleAddNewTrack}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 5v14M5 12h14" />
                </svg>
                Добавить новый трек
              </button>
            )}
          </div>

          {isLoading ? (
            <div className={styles['loading']}>Загрузка...</div>
          ) : availableVideos.length === 0 ? (
            <div className={styles['empty']}>
              <button
                className={styles['load-videos-button']}
                onClick={loadAvailableVideos}
              >
                Загрузить доступные видео
              </button>
            </div>
          ) : (
            <List gap={12}>
              {availableVideos.map((video) => (
                <div key={video.id} className={styles['video-item']}>
                  <label className={styles['checkbox-label']}>
                    <input
                      type="checkbox"
                      checked={selectedVideoIds.has(video.id)}
                      onChange={() => handleToggleVideo(video.id)}
                      disabled={playlist.isSystem}
                      className={styles['checkbox']}
                    />
                    <VideoCard video={video} compact />
                  </label>
                </div>
              ))}
            </List>
          )}
        </div>
      </div>
    </ModalContainer>
  );
}

