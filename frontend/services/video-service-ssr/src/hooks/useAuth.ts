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
        setError(null);
      } else {
        clearSession();
        setError(null);
      }
    } catch (err: any) {
      // При восстановлении сессии ошибки не критичны - просто очищаем сессию
      clearSession();
      // Не устанавливаем ошибку при восстановлении - это нормально, если пользователь не авторизован
      setError(null);
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
        let errorMessage = 'Ошибка входа. Проверьте подключение к интернету.';
        
        if (err?.graphQLErrors && err.graphQLErrors.length > 0) {
          errorMessage = err.graphQLErrors[0].message;
        } else if (err?.networkError) {
          const networkErr = err.networkError;
          if (networkErr.message?.includes('Failed to fetch') || networkErr.message?.includes('NetworkError')) {
            errorMessage = 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
          } else {
            errorMessage = networkErr.message || errorMessage;
          }
        } else if (err?.message) {
          errorMessage = err.message;
        }
        
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
        let errorMessage = 'Ошибка регистрации. Проверьте подключение к интернету.';
        
        if (err?.graphQLErrors && err.graphQLErrors.length > 0) {
          errorMessage = err.graphQLErrors[0].message;
        } else if (err?.networkError) {
          const networkErr = err.networkError;
          if (networkErr.message?.includes('Failed to fetch') || networkErr.message?.includes('NetworkError')) {
            errorMessage = 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
          } else {
            errorMessage = networkErr.message || errorMessage;
          }
        } else if (err?.message) {
          errorMessage = err.message;
        }
        
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

