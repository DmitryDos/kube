// src/components/AuthForm/AuthForm.tsx
'use client';

import { useState, useCallback, FormEvent } from 'react';
import { useAuth } from '../../hooks/useAuth';
import styles from './AuthForm.module.css';

interface AuthFormProps {
  isLogin: boolean;
  onToggleMode: () => void;
}

export function AuthForm({ isLogin, onToggleMode }: AuthFormProps) {
  const { login, register, error: authError } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = useCallback(async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      if (isLogin) {
        await login(email, password);
      } else {
        if (!name.trim()) {
          setError('Имя обязательно');
          setIsLoading(false);
          return;
        }
        await register(email, password, name);
      }
    } catch (err: any) {
      let errorMessage = isLogin ? 'Ошибка входа. Проверьте подключение к интернету.' : 'Ошибка регистрации. Проверьте подключение к интернету.';
      
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
    } finally {
      setIsLoading(false);
    }
  }, [isLogin, email, password, name, login, register]);

  const displayError = error || authError;

  return (
    <form className={styles['auth-form']} onSubmit={handleSubmit}>
      {displayError && (
        <div className={styles['error']}>
          {displayError}
        </div>
      )}

      {!isLogin && (
        <div className={styles['form-group']}>
          <label htmlFor="name" className={styles['label']}>Имя</label>
          <input
            id="name"
            type="text"
            className={styles['input']}
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Введите имя"
            required={!isLogin}
            disabled={isLoading}
            autoFocus={false}
          />
        </div>
      )}

      <div className={styles['form-group']}>
        <label htmlFor="email" className={styles['label']}>Email</label>
        <input
          id="email"
          type="email"
          className={styles['input']}
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="Введите email"
          required
          disabled={isLoading}
          autoFocus={false}
        />
      </div>

      <div className={styles['form-group']}>
        <label htmlFor="password" className={styles['label']}>Пароль</label>
        <input
          id="password"
          type="password"
          className={styles['input']}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="Введите пароль"
          required
          disabled={isLoading}
          autoFocus={false}
        />
      </div>

      <button
        type="submit"
        className={styles['submit-button']}
        disabled={isLoading}
      >
        {isLoading ? 'Загрузка...' : (isLogin ? 'Войти' : 'Зарегистрироваться')}
      </button>

      <div className={styles['toggle-mode']}>
        {isLogin ? (
          <>
            <span>Нет аккаунта?</span>
            <button
              type="button"
              className={styles['toggle-button']}
              onClick={onToggleMode}
              disabled={isLoading}
            >
              Зарегистрируйтесь
            </button>
          </>
        ) : (
          <>
            <span>Уже есть аккаунт?</span>
            <button
              type="button"
              className={styles['toggle-button']}
              onClick={onToggleMode}
              disabled={isLoading}
            >
              Войдите
            </button>
          </>
        )}
      </div>
    </form>
  );
}

