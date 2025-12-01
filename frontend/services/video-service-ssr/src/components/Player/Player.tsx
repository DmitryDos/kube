// src/components/Player/Player.tsx
'use client';

import { VideoPlayer } from '../VideoPlayer/VideoPlayer';
import { DescriptionBlock } from '../DescriptionBlock/DescriptionBlock';
import { Video } from '../../types';
import styles from './Player.module.css';

interface PlayerProps {
  video: Video | null;
  authorName?: string;
  isLoading?: boolean;
  error?: string | null;
  onPlay?: () => void;
  onPause?: () => void;
  onEnded?: () => void;
}

export function Player({ video, authorName, isLoading = false, error, onPlay, onPause, onEnded }: PlayerProps) {
  return (
    <div className={styles['player']}>
      <div className={styles['video-section']}>
        {error ? (
          <div className={styles['error']}>
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <p>{error}</p>
          </div>
        ) : isLoading || !video ? (
          <div className={styles['video-placeholder']}>
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <rect x="2" y="4" width="20" height="16" rx="2" />
              <polygon points="23 7 16 12 23 17 23 7" />
            </svg>
            <p>Загрузка видео...</p>
          </div>
        ) : (
          <VideoPlayer
            videoUrl={`/api/videos/${video.id}/stream/proxy`}
            thumbnailUrl={video.thumbnail_url}
            title={video.title}
            onPlay={onPlay}
            onPause={onPause}
            onEnded={onEnded}
          />
        )}
      </div>
      <div className={styles['description-section']}>
        <DescriptionBlock
          title={video?.title || ''}
          description={video?.description}
          authorName={authorName}
          createdAt={video?.created_at}
        />
      </div>
    </div>
  );
}

