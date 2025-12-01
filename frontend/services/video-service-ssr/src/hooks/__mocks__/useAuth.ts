// src/hooks/__mocks__/useAuth.ts
import { User } from '../../types';

const mockUser: User = {
  id: '550e8400-e29b-41d4-a716-446655440010',
  email: 'user@example.com',
  name: 'Иван Иванов',
  created_at: '2024-01-15T10:30:00Z',
};

export function useAuth() {
  return {
    isAuthenticated: false,
    currentUser: null,
    isLoading: false,
    error: null,
    login: async (email: string, password: string): Promise<void> => {
      await new Promise(resolve => setTimeout(resolve, 500));
      // В реальности здесь будет установка состояния через setState
      console.log('Login:', email, password);
    },
    register: async (email: string, password: string, name: string): Promise<void> => {
      await new Promise(resolve => setTimeout(resolve, 500));
      console.log('Register:', email, password, name);
    },
    logout: async (): Promise<void> => {
      await new Promise(resolve => setTimeout(resolve, 200));
      console.log('Logout');
    },
  };
}

