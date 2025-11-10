import { useCallback } from 'react';

export function useVideoStream() {
  const getVideoStreamURL = useCallback(
    async (videoId: string): Promise<string> => {
      // Идем напрямую через API Gateway - same origin, токен передается через cookie
      // Это быстрее, чем через Next.js proxy (минуем один хоп)
      return `/api/videos/${videoId}/stream/proxy`;
    },
    []
  );

  return { getVideoStreamURL };
}

