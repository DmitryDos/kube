// src/components/AsyncTrackImage/AsyncTrackImage.tsx
'use client';

import { useState, Suspense } from 'react';
import { Video } from '../../types';
import { useTrackImage } from '../../hooks/useTrackImage';
import styles from './AsyncTrackImage.module.css';

interface AsyncTrackImageProps {
  video: Video;
  fallback?: string;
}

function AsyncTrackImageContent({ video, fallback }: AsyncTrackImageProps) {
  const { imageUrl, isLoading } = useTrackImage(video);
  const finalImageUrl = imageUrl || fallback;
  const [hasError, setHasError] = useState(false);

  // Проверяем валидность URL
  const isValidUrl = finalImageUrl && (
    finalImageUrl.startsWith('http://') || 
    finalImageUrl.startsWith('https://') || 
    finalImageUrl.startsWith('/') ||
    finalImageUrl.startsWith('data:')
  );

  // Показываем fallback только если нет изображения, невалидный URL или ошибка загрузки
  const showFallback = (!finalImageUrl || !isValidUrl || hasError) && !isLoading;

  return (
    <>
      {finalImageUrl && isValidUrl && !hasError && (
        <img
          src={finalImageUrl}
          alt={video.title || ''}
          className={styles['image']}
          loading="lazy"
          onError={() => setHasError(true)}
          onLoad={() => setHasError(false)}
        />
      )}
      {showFallback && (
        <div className={styles['no-image']}>
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="2" y="4" width="20" height="16" rx="2" fill="rgba(255, 255, 255, 0.1)" stroke="rgba(255, 255, 255, 0.3)" strokeWidth="1.5"/>
            <path d="M8 12L12 9L16 12V18H8V12Z" fill="rgba(255, 255, 255, 0.4)" stroke="rgba(255, 255, 255, 0.5)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            <circle cx="9" cy="8" r="1.5" fill="rgba(255, 255, 255, 0.4)"/>
          </svg>
        </div>
      )}
    </>
  );
}

export function AsyncTrackImage(props: AsyncTrackImageProps) {
  return (
    <div className={styles['container']}>
      <Suspense
        fallback={
          <div className={styles['no-image']}>
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="2" y="4" width="20" height="16" rx="2" fill="rgba(255, 255, 255, 0.1)" stroke="rgba(255, 255, 255, 0.3)" strokeWidth="1.5"/>
              <path d="M8 12L12 9L16 12V18H8V12Z" fill="rgba(255, 255, 255, 0.4)" stroke="rgba(255, 255, 255, 0.5)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              <circle cx="9" cy="8" r="1.5" fill="rgba(255, 255, 255, 0.4)"/>
            </svg>
          </div>
        }
      >
        <AsyncTrackImageContent {...props} />
      </Suspense>
    </div>
  );
}