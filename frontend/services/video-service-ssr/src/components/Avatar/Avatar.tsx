// src/components/Avatar/Avatar.tsx
'use client';

import { Video } from '../../types';
import { AsyncTrackImage } from '../AsyncTrackImage/AsyncTrackImage';
import styles from './Avatar.module.css';

interface AvatarProps {
  video: Video;
  size?: number;
  fallback?: string;
}

export function Avatar({ video, size = 36, fallback }: AvatarProps) {
  return (
    <div 
      className={styles['avatar']}
      style={{ width: size, height: size }}
    >
      <AsyncTrackImage video={video} fallback={fallback} />
    </div>
  );
}