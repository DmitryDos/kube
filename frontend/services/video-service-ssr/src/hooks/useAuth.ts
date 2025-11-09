import { useState, useCallback, useEffect } from 'react';
import { User } from '../types';
import { useApolloClients } from '../lib/apollo-client';
import { ME_QUERY, LOGIN_MUTATION, REGISTER_MUTATION, LOGOUT_MUTATION } from '../lib/graphql-queries';
import { gql } from '@apollo/client';

export function useAuth() {
  const clients = useApolloClients();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const clearSession = () => {
    setCurrentUser(null);
    setIsAuthenticated(false);
  };

  const restoreSession = useCallback(async () => {
    try {
      const { data } = await clients.auth.query({
        query: gql(ME_QUERY),
        fetchPolicy: 'network-only',
      });

      if (data?.me) {
        setCurrentUser(data.me);
        setIsAuthenticated(true);
      } else {
        clearSession();
      }
    } catch (err) {
      clearSession();
    } finally {
      setIsLoading(false);
    }
  }, [clients]);

  useEffect(() => {
    restoreSession();
  }, [restoreSession]);

  const login = useCallback(
    async (email: string, password: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const { data } = await clients.auth.mutate({
          mutation: gql(LOGIN_MUTATION),
          variables: {
            input: { email, password },
          },
        });

        if (data?.login?.user) {
          setCurrentUser(data.login.user);
          setIsAuthenticated(true);
          await restoreSession();
        } else {
          throw new Error('Login failed');
        }
      } catch (err: any) {
        const errorMessage = err.message || 'Ошибка входа';
        setError(errorMessage);
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    [clients, restoreSession]
  );

  const register = useCallback(
    async (email: string, password: string, name: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const { data } = await clients.auth.mutate({
          mutation: gql(REGISTER_MUTATION),
          variables: {
            input: { email, password, name },
          },
        });

        if (data?.register?.user) {
          setCurrentUser(data.register.user);
          setIsAuthenticated(true);
          await restoreSession();
        } else {
          throw new Error('Registration failed');
        }
      } catch (err: any) {
        const errorMessage = err.message || 'Ошибка регистрации';
        setError(errorMessage);
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    [clients, restoreSession]
  );

  const logout = useCallback(async () => {
    try {
      await clients.auth.mutate({
        mutation: gql(LOGOUT_MUTATION),
      });
    } catch (err) {
    } finally {
      clearSession();
    }
  }, [clients]);

  return {
    isAuthenticated,
    currentUser,
    isLoading,
    error,
    login,
    register,
    logout,
  };
}

