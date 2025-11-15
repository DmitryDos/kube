// src/components/VideoCard/VideoCard.tsx
'use client';

import { formatDuration } from '../../lib/formatTime';
import { Video } from '../../types';
import { AsyncTrackImage } from '../AsyncTrackImage/AsyncTrackImage';
import styles from './VideoCard.module.css';

interface VideoCardProps {
  video: Video;
  authorName?: string;
  onClick?: (video: Video) => void;
  compact?: boolean;
  expanded?: boolean;
}

export function VideoCard({ video, authorName, onClick, compact = false, expanded = false }: VideoCardProps) {
  return (
    <div 
      className={`${styles['video-card']} ${compact ? styles['compact'] : ''} ${expanded ? styles['expanded'] : ''}`}
      onClick={() => onClick?.(video)}
    >
      <div className={styles['thumbnail']}>
        <AsyncTrackImage video={video} />
        <span className={styles['duration']}>{formatDuration(video.duration)}</span>
        {!expanded && (
          <div className={styles['overlay-info']}>
            <div className={styles['author']}>{authorName || 'Автор'}</div>
            <div className={styles['title']}>{video.title}</div>
          </div>
        )}
      </div>
      {expanded && (
        <div className={styles['expanded-content']}>
          <div className={styles['expanded-header']}>
            <h3 className={styles['expanded-title']}>{video.title}</h3>
            <div className={styles['expanded-author']}>{authorName || 'Автор'}</div>
          </div>
          {video.description && (
            <p className={styles['expanded-description']}>{video.description}</p>
          )}
          <div className={styles['expanded-meta']}>
            <span className={styles['expanded-date']}>
              {new Date(video.created_at).toLocaleDateString('ru-RU')}
            </span>
            <span className={styles['expanded-duration']}>
              {formatDuration(video.duration)}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}