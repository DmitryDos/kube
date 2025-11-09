import { useState, useEffect, useRef } from 'react';
import { Video } from '../types';
import { normalizeThumbnailUrl } from '../utils/url';

// Кэш изображений - храним blob, а не object URL
const imageCache = new Map<string, Blob>();

export function useTrackImage(video: Video) {
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);
  const objectUrlRef = useRef<string | null>(null);

  useEffect(() => {
    const loadImage = async () => {
      // Отменяем предыдущий запрос если есть
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }

      // Очищаем предыдущий object URL
      if (objectUrlRef.current) {
        URL.revokeObjectURL(objectUrlRef.current);
        objectUrlRef.current = null;
      }

      const controller = new AbortController();
      abortControllerRef.current = controller;

      setIsLoading(true);
      setError(null);

      try {
        // Нормализуем URL
        const normalizedUrl = normalizeThumbnailUrl(video.thumbnail_url, video.id);

        // Проверяем кэш blob
        let blob: Blob;
        if (imageCache.has(normalizedUrl)) {
          blob = imageCache.get(normalizedUrl)!;
        } else {
          // Загружаем изображение через прокси-роут (токен передается через cookie)
          const response = await fetch(normalizedUrl, {
            signal: controller.signal,
            credentials: 'include',
          });

          if (!response.ok) {
            throw new Error(`Failed to load image: ${response.statusText}`);
          }

          blob = await response.blob();
          
          // Сохраняем blob в кэш
          imageCache.set(normalizedUrl, blob);
        }

        // Создаём object URL из blob (каждый компонент создаёт свой)
        const objectUrl = URL.createObjectURL(blob);
        objectUrlRef.current = objectUrl;
        setImageUrl(objectUrl);
      } catch (err) {
        if (err instanceof Error && err.name === 'AbortError') {
          return; // Запрос был отменен
        }
        setError(err instanceof Error ? err.message : 'Ошибка загрузки изображения');
        setImageUrl(null);
      } finally {
        setIsLoading(false);
      }
    };

    loadImage();

    // Cleanup при размонтировании или изменении video
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
      
      // Очищаем object URL
      if (objectUrlRef.current) {
        URL.revokeObjectURL(objectUrlRef.current);
        objectUrlRef.current = null;
      }
    };
  }, [video.id, video.thumbnail_url]);

  return { imageUrl, isLoading, error };
}

