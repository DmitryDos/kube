import { useState, useCallback } from 'react';
import { Video } from '../types';
import { useApolloClients } from '../lib/apollo-client';
import { SEARCH_QUERY } from '../lib/graphql-queries';
import { gql } from '@apollo/client';

export function useVideo() {
  const clients = useApolloClients();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getVideo = useCallback(
    async (videoId: string): Promise<Video | null> => {
      setIsLoading(true);
      setError(null);

      try {
        const { data } = await clients.video.query({
          query: gql(SEARCH_QUERY),
          variables: {
            query: '',
            page: 1,
            limit: 100,
            filter: 'videos',
          },
          fetchPolicy: 'network-only',
        });
        
        const videoResult = data.search.results.find(
          (item: any) => item.type === 'video' && item.video?.id === videoId
        );

        return videoResult?.video || null;
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Ошибка загрузки видео';
        setError(errorMessage);
        return null;
      } finally {
        setIsLoading(false);
      }
    },
    [clients]
  );

  return { getVideo, isLoading, error };
}

