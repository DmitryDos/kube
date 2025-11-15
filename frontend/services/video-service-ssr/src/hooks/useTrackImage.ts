// src/hooks/useTrackImage.ts
import { useState, useEffect, useRef } from 'react';
import { Video } from '../types';

// Кэш для Object URLs
const imageUrlCache = new Map<string, string>();

export function useTrackImage(video: Video) {
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    if (!video.thumbnail_url) {
      setImageUrl(null);
      setIsLoading(false);
      setError('No thumbnail URL');
      return;
    }

    // Проверяем кэш
    const cachedUrl = imageUrlCache.get(video.thumbnail_url);
    if (cachedUrl) {
      setImageUrl(cachedUrl);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    // Создаем Image для предзагрузки
    const img = new Image();
    
    img.onload = () => {
      // Сохраняем оригинальный URL в кэш (не создаем Object URL)
      imageUrlCache.set(video.thumbnail_url!, video.thumbnail_url!);
      setImageUrl(video.thumbnail_url!);
      setIsLoading(false);
    };
    
    img.onerror = () => {
      setError('Failed to load image');
      setIsLoading(false);
    };
    
    img.src = video.thumbnail_url;

  }, [video.thumbnail_url]);

  return { imageUrl, isLoading, error };
}