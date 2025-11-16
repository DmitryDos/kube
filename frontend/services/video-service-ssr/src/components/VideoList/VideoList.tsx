// src/components/VideoList/VideoList.tsx
'use client';

import { Video } from '../../types';
import { VideoCard } from '../VideoCard/VideoCard';
import { List } from '../List/List';
import styles from './VideoList.module.css';

interface VideoListProps {
  videos: Video[];
  gap?: number;
  onVideoClick?: (video: Video) => void;
  onVideoLongPress?: (video: Video) => void;
  showEditButton?: boolean;
}

export function VideoList({
  videos,
  gap = 12,
  onVideoClick,
  onVideoLongPress,
  showEditButton = false,
}: VideoListProps) {
  if (videos.length === 0) {
    return null;
  }

  return (
    <List gap={gap} autoHeight={true}>
      {videos.map((video) => (
        <div key={video.id} className={styles['video-wrapper']}>
          {showEditButton && (
            <button
              className={styles['video-edit-button']}
              onClick={(e) => {
                e.stopPropagation();
                onVideoLongPress?.(video);
              }}
              aria-label="Редактировать видео"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
              </svg>
            </button>
          )}
          <VideoCard
            video={video}
            onClick={onVideoClick}
          />
        </div>
      ))}
    </List>
  );
}

