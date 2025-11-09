'use client';

import { ApolloClient, InMemoryCache, HttpLink, from } from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { onError } from '@apollo/client/link/error';
import { useMemo } from 'react';

function createClient(uri: string) {
  const httpLink = new HttpLink({
    uri: `${uri}/graphql`,
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
  const authBffUrl = process.env['NEXT_PUBLIC_AUTH_BFF_URL'] || 'http://localhost:3003';
  const videoBffUrl = process.env['NEXT_PUBLIC_VIDEO_BFF_URL'] || 'http://localhost:3002';

  return useMemo(() => ({
    auth: createClient(authBffUrl),
    video: createClient(videoBffUrl),
  }), [authBffUrl, videoBffUrl]);
}

