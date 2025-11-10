import { useState, useCallback } from 'react';
import { Video } from '../types';

// Используем REST API напрямую - быстрее чем GraphQL с limit=100
export function useVideo() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getVideo = useCallback(
    async (videoId: string): Promise<Video | null> => {
      setIsLoading(true);
      setError(null);

      try {
        // TODO: Добавить REST endpoint /api/videos/:id для получения одного видео
        // Пока используем search с большим limit и ищем по ID в результатах
        // Это быстрее, чем GraphQL запрос на 100 видео, но не идеально
        const params = new URLSearchParams({
          q: '', // Пустой запрос - получаем все видео
          page: '1',
          limit: '100', // Достаточно для поиска по ID
          filter: 'videos',
        });

        const response = await fetch(`/api/search?${params.toString()}`, {
          method: 'GET',
          credentials: 'include',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (!response.ok) {
          throw new Error(`Failed to fetch video: ${response.status}`);
        }

        const data = await response.json();
        
        // Ищем видео с нужным ID в результатах
        const videoResult = data.results?.find(
          (item: any) => item.type === 'video' && item.data?.id === videoId
        );

        return videoResult?.data || null;
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Ошибка загрузки видео';
        setError(errorMessage);
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  return { getVideo, isLoading, error };
}

