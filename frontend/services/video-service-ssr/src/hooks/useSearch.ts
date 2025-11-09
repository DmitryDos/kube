import { useState, useCallback } from 'react';
import { SearchResponse, SearchFilter } from '../types';
import { useApolloClients } from '../lib/apollo-client';
import { SEARCH_QUERY } from '../lib/graphql-queries';
import { gql } from '@apollo/client';

export function useSearch() {
  const clients = useApolloClients();
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
        const { data } = await clients.video.query({
          query: gql(SEARCH_QUERY),
          variables: {
            query,
            page,
            limit,
            filter,
          },
          fetchPolicy: 'network-only',
        });
        
        // Transform GraphQL response to expected format
        const searchData = data.search;
        return {
          results: searchData.results.map((item: any) => {
            const itemData = item.video || item.author;
            // Ensure author has all required fields
            if (item.type === 'author' && itemData) {
              return {
                type: item.type,
                data: {
                  ...itemData,
                  title: itemData.title || itemData.name,
                  name: itemData.name || itemData.title,
                },
              };
            }
            return {
              type: item.type,
              data: itemData,
            };
          }),
          pagination: {
            page: searchData.page || 1,
            limit: searchData.limit || 20,
            total: searchData.total || 0,
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
    [clients]
  );

  return { search, isLoading, error };
}

