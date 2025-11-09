'use client';

import { ReactNode } from 'react';
import { ApolloProvider } from '@apollo/client';
import { useApolloClients } from '../lib/apollo-client';

export function ApolloProviderWrapper({ children }: { children: ReactNode }) {
  const clients = useApolloClients();
  
  return (
    <ApolloProvider client={clients.auth}>
      {children}
    </ApolloProvider>
  );
}

