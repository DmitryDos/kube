'use client';

import { useVideoPlayback } from '../../contexts/VideoPlaybackContext';
import { AsyncTrackImage } from '../AsyncTrackImage/AsyncTrackImage';
import styles from './VideoModal.module.css';

export function VideoModal() {
  const { isVideoModalOpen, currentVideoId, currentVideoData, closeVideoModal } = useVideoPlayback();

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  };

  const handleBack = () => {
    closeVideoModal();
  };

  const handleOverlayClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      closeVideoModal();
    }
  };

  if (!isVideoModalOpen || !currentVideoId) {
    return null;
  }

  return (
    <div className={styles['modalOverlay']} onClick={handleOverlayClick}>
      <div className={styles['modalContent']}>
        <div className={styles['header']}>
          <button onClick={handleBack} className={styles['closeButton']}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 6L6 18M6 6l12 12" />
            </svg>
          </button>
        </div>

        {!currentVideoData ? (
          <div className={styles['errorContainer']}>
            <p>Видео не найдено</p>
          </div>
        ) : (
          <>
            <div className={styles['playerWrapper']}>
              <AsyncTrackImage video={currentVideoData} />
            </div>

            <div className={styles['info']}>
              <h1 className={styles['title']}>{currentVideoData.title}</h1>
              
              {currentVideoData.description && (
                <p className={styles['description']}>{currentVideoData.description}</p>
              )}

              <div className={styles['meta']}>
                <div className={styles['metaItem']}>
                  <span className={styles['metaLabel']}>Дата:</span>
                  <span>{formatDate(currentVideoData.created_at)}</span>
                </div>
                {currentVideoData.duration > 0 && (
                  <div className={styles['metaItem']}>
                    <span className={styles['metaLabel']}>Длительность:</span>
                    <span>
                      {Math.floor(currentVideoData.duration / 60)}:
                      {Math.floor(currentVideoData.duration % 60)
                        .toString()
                        .padStart(2, '0')}
                    </span>
                  </div>
                )}
                {currentVideoData.file_size > 0 && (
                  <div className={styles['metaItem']}>
                    <span className={styles['metaLabel']}>Размер:</span>
                    <span>{formatFileSize(currentVideoData.file_size)}</span>
                  </div>
                )}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

