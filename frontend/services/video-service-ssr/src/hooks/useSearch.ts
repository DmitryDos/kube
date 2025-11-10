import { useState, useCallback } from 'react';
import { SearchResponse, SearchFilter } from '../types';

// Используем REST API напрямую, как Swift - быстрее чем через GraphQL (минуем video-service-bff)
export function useSearch() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const search = useCallback(
    async (
      query: string = '',
      page: number = 1,
      limit: number = 20,
      filter: SearchFilter = 'all'
    ): Promise<SearchResponse> => {
      setIsLoading(true);
      setError(null);

      try {
        // Идем напрямую к REST API через API Gateway (same origin)
        // Это быстрее, чем через GraphQL (минуем video-service-bff)
        const params = new URLSearchParams({
          q: query || '',
          page: page.toString(),
          limit: limit.toString(),
          filter: filter === 'all' ? 'all' : filter,
        });

        const response = await fetch(`/api/search?${params.toString()}`, {
          method: 'GET',
          credentials: 'include', // Для передачи cookies с токеном
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (!response.ok) {
          throw new Error(`Search failed: ${response.status} ${response.statusText}`);
        }

        const data = await response.json();
        
        // API Gateway возвращает: { results: [{ type: "video", data: {...} }], pagination: {...} }
        // Формат уже правильный, просто возвращаем как есть
        return {
          results: data.results || [],
          pagination: data.pagination || {
            page: data.page || 1,
            limit: data.limit || 20,
            total: data.total || 0,
          },
        };
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Ошибка поиска';
        setError(errorMessage);
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  return { search, isLoading, error };
}

