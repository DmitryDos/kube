'use client';

import { ApolloClient, InMemoryCache, HttpLink, from } from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { onError } from '@apollo/client/link/error';
import { useMemo } from 'react';

function createClient(uri: string) {
  // URI уже содержит полный путь (например, /graphql/auth или /graphql/video)
  const httpLink = new HttpLink({
    uri: uri,
    credentials: 'include',
  });

  const authLink = setContext((_, { headers }) => {
    return {
      headers: {
        ...headers,
      },
    };
  });

  const errorLink = onError(({ graphQLErrors, networkError, operation, forward }) => {
    if (graphQLErrors) {
      graphQLErrors.forEach(({ message, locations, path, extensions }) => {
        console.error(`[GraphQL error]:`, {
          message,
          locations: JSON.stringify(locations),
          path: JSON.stringify(path),
          extensions: JSON.stringify(extensions),
          operation: operation?.operationName,
          variables: JSON.stringify(operation?.variables),
        });
      });
    }
    if (networkError) {
      console.error(`[Network error]:`, {
        message: networkError.message,
        stack: networkError.stack,
        name: networkError.name,
        operation: operation?.operationName,
        variables: JSON.stringify(operation?.variables),
      });
    }
  });

  return new ApolloClient({
    link: from([errorLink, authLink, httpLink]),
    cache: new InMemoryCache(),
    defaultOptions: {
      watchQuery: {
        fetchPolicy: 'cache-and-network',
      },
    },
  });
}

export function useApolloClients() {
  // SSR доступен только через API Gateway, поэтому используем относительные пути
  // Все запросы идут через API Gateway - same origin, CORS не нужен
  // API Gateway проксирует GraphQL запросы:
  // /graphql/auth -> auth-service-bff/graphql
  // /graphql/video -> video-service-bff/graphql
  
  return useMemo(() => {
    // Относительные пути - same origin через API Gateway
    const authGraphQLUrl = '/graphql/auth';
    const videoGraphQLUrl = '/graphql/video';
    
    return {
      auth: createClient(authGraphQLUrl),
      video: createClient(videoGraphQLUrl),
    };
  }, []);
}

