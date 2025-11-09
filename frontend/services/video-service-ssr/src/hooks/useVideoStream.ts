import { useCallback } from 'react';

export function useVideoStream() {
  const getVideoStreamURL = useCallback(
    async (videoId: string): Promise<string> => {
      // Используем прокси-роут Next.js, который добавит токен из cookie
      return `/api/proxy/videos/${videoId}/stream/proxy`;
    },
    []
  );

  return { getVideoStreamURL };
}

