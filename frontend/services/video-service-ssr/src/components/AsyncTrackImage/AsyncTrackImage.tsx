'use client';

import { Video } from '../../types';
import { useTrackImage } from '../../hooks/useTrackImage';
import Image from 'next/image';
import styles from './AsyncTrackImage.module.css';

interface AsyncTrackImageProps {
  video: Video;
  width?: number;
  height?: number;
  cornerRadius?: number;
  className?: string;
}

export function AsyncTrackImage({
  video,
  width,
  height,
  cornerRadius = 8,
  className,
}: AsyncTrackImageProps) {
  const { imageUrl, isLoading, error } = useTrackImage(video);

  return (
    <div
      className={`${styles['container']} ${className || ''}`}
      style={{
        width: width ? `${width}px` : '100%',
        height: height ? `${height}px` : 'auto',
        borderRadius: `${cornerRadius}px`,
        overflow: 'hidden',
        position: 'relative',
        aspectRatio: '16/9',
      }}
    >
      {isLoading && (
        <div className={styles['placeholder']}>
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
          </svg>
        </div>
      )}

      {error && !imageUrl && (
        <div className={styles['placeholder']}>
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <polygon points="23 7 16 12 23 17 23 7" />
            <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
          </svg>
        </div>
      )}

      {imageUrl && (
        <Image
          src={imageUrl}
          alt={video.title}
          fill
          className={styles['image']}
          sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
          style={{ objectFit: 'cover' }}
        />
      )}
    </div>
  );
}

