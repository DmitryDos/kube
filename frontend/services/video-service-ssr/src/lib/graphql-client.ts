import { getServerApolloClients } from './apollo-client-server';
import { gql } from '@apollo/client';

export async function authGraphQL<T>(query: string, variables?: Record<string, any>): Promise<T> {
  const clients = await getServerApolloClients();
  const { data } = await clients.auth.query({
    query: gql(query),
    variables,
    fetchPolicy: 'no-cache',
  });
  return data as T;
}

export async function videoGraphQL<T>(query: string, variables?: Record<string, any>): Promise<T> {
  const clients = await getServerApolloClients();
  const { data } = await clients.video.query({
    query: gql(query),
    variables,
    fetchPolicy: 'no-cache',
  });
  return data as T;
}

