'use client';

import { useRef } from 'react';
import { useRouter } from 'next/navigation';
import { Video } from '../../types';
import { useVideoPlayback } from '../../contexts/VideoPlaybackContext';
import { AsyncTrackImage } from '../AsyncTrackImage/AsyncTrackImage';
import styles from './VideoCard.module.css';

interface VideoCardProps {
  video: Video;
}

export default function VideoCard({ video }: VideoCardProps) {
  const router = useRouter();
  const { openVideoModal, playVideo, hasActiveVideo, isPipActive, onVideoClick } = useVideoPlayback();
  const longPressTimerRef = useRef<NodeJS.Timeout | null>(null);
  const isLongPressRef = useRef(false);

  const formatDuration = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const handlePointerDown = (e: React.PointerEvent) => {
    isLongPressRef.current = false;
    longPressTimerRef.current = setTimeout(() => {
      isLongPressRef.current = true;
      openVideoModal(video.id, video);
    }, 500);
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    if (longPressTimerRef.current) {
      clearTimeout(longPressTimerRef.current);
      longPressTimerRef.current = null;
    }
    
    // Если не было долгого нажатия
    if (!isLongPressRef.current) {
      // Если есть кастомный обработчик (например, на главной странице) - используем его
      if (onVideoClick) {
        onVideoClick(video);
      } else if (hasActiveVideo || isPipActive) {
        // Если есть активное видео или PIP - просто переключаем видео
        playVideo(video.id, video);
      } else {
        // Если ничего не играет - открываем страницу плеера
        router.push(`/player/${video.id}`);
      }
    }
    
    isLongPressRef.current = false;
  };

  const handlePointerCancel = () => {
    if (longPressTimerRef.current) {
      clearTimeout(longPressTimerRef.current);
      longPressTimerRef.current = null;
    }
    isLongPressRef.current = false;
  };

  return (
    <div 
      onPointerDown={handlePointerDown}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerCancel}
      className={styles['videoCard']} 
      style={{ cursor: 'pointer' }}
    >
      <div className={styles['thumbnailWrapper']}>
        <AsyncTrackImage video={video} />
        {video.duration > 0 && (
          <div className={styles['duration']}>
            {formatDuration(video.duration)}
          </div>
        )}
      </div>
      <div className={styles['info']}>
        <h3 className={styles['title']}>{video.title}</h3>
        {video.description && (
          <p className={styles['description']}>{video.description}</p>
        )}
        <div className={styles['meta']}>
          <span className={styles['date']}>{formatDate(video.created_at)}</span>
        </div>
      </div>
    </div>
  );
}

