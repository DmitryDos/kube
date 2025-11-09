'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useModal } from '../../contexts/ModalContext';
import styles from './AuthModal.module.css';

export function AuthModalContent() {
  const { login, register, error, isLoading, isAuthenticated } = useAuth();
  const { closeModal } = useModal();
  const [isRegistering, setIsRegistering] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');

  useEffect(() => {
    if (isAuthenticated) {
      closeModal('auth');
    }
  }, [isAuthenticated, closeModal]);

  const isFormValid = isRegistering
    ? name.trim() !== '' && email.trim() !== '' && email.includes('@') && password.trim() !== '' && password.length >= 6
    : email.trim() !== '' && password.trim() !== '';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      if (isRegistering) {
        await register(email, password, name);
      } else {
        await login(email, password);
      }
      setEmail('');
      setPassword('');
      setName('');
    } catch (err) {
      // Ошибка уже установлена в хуке
    }
  };

  const toggleMode = () => {
    setIsRegistering(!isRegistering);
    setEmail('');
    setPassword('');
    setName('');
  };

  return (
    <div className={styles['container']}>
      <div className={styles['icon']}>
        {isRegistering ? '👤➕' : '👤'}
      </div>
      <h2 className={styles['title']}>
        {isRegistering ? 'Регистрация' : 'Вход в YetMusic'}
      </h2>

      <form onSubmit={handleSubmit} className={styles['form']}>
        {isRegistering && (
          <div className={styles['field']}>
            <label htmlFor="name">Имя</label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Введите имя"
              required
            />
          </div>
        )}

        <div className={styles['field']}>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Введите email"
            required
          />
        </div>

        <div className={styles['field']}>
          <label htmlFor="password">Пароль</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Введите пароль"
            required
            minLength={isRegistering ? 6 : undefined}
          />
        </div>

        {error && (
          <div className={styles['error']}>{error}</div>
        )}

        <button
          type="button"
          onClick={toggleMode}
          className={styles['toggleButton']}
        >
          {isRegistering
            ? 'Уже есть аккаунт? Войти'
            : 'Нет аккаунта? Зарегистрироваться'}
        </button>
      </form>
    </div>
  );
}

