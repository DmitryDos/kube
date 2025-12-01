import { ApolloClient, InMemoryCache, HttpLink, from } from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { onError } from '@apollo/client/link/error';
import { cookies } from 'next/headers';

function createClient(uri: string, cookieHeader?: string) {
  const httpLink = new HttpLink({
    uri: `${uri}/graphql`,
    credentials: 'include',
    fetch: (url, options) => {
      return fetch(url, {
        ...options,
        headers: {
          ...options?.headers,
          ...(cookieHeader && { cookie: cookieHeader }),
        },
      });
    },
  });

  const authLink = setContext((_, { headers }) => {
    return {
      headers: {
        ...headers,
        ...(cookieHeader && { cookie: cookieHeader }),
      },
    };
  });

  const errorLink = onError(({ graphQLErrors, networkError }) => {
    if (graphQLErrors) {
      graphQLErrors.forEach(({ message }) => {
        console.error(`[GraphQL error]: ${message}`);
      });
    }
    if (networkError) {
      console.error(`[Network error]: ${networkError}`);
    }
  });

  return new ApolloClient({
    link: from([errorLink, authLink, httpLink]),
    cache: new InMemoryCache(),
    ssrMode: true,
  });
}

export async function getServerApolloClients() {
  const cookieStore = await cookies();
  const cookieHeader = cookieStore.toString();
  
  const authBffUrl = process.env['AUTH_BFF_URL'] || 'http://localhost:3003';
  const videoBffUrl = process.env['VIDEO_BFF_URL'] || 'http://localhost:3002';

  return {
    auth: createClient(authBffUrl, cookieHeader),
    video: createClient(videoBffUrl, cookieHeader),
  };
}

