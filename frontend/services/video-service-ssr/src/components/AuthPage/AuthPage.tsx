// src/components/AuthPage/AuthPage.tsx
'use client';

import { useState } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { AuthForm } from '../AuthForm/AuthForm';
import { UserAvatar } from '../UserAvatar/UserAvatar';
import styles from './AuthPage.module.css';

export function AuthPage() {
  const { isLoading } = useAuth();
  const [isLogin, setIsLogin] = useState(true);

  if (isLoading) {
    return (
      <div className={styles['auth-page']}>
        <div className={styles['loading']}>
          <div className={styles['spinner']}></div>
        </div>
      </div>
    );
  }


  return (
    <div className={styles['auth-page']}>
      <UserAvatar user={null} size={120} />
      <AuthForm isLogin={isLogin} onToggleMode={() => setIsLogin(!isLogin)} />
    </div>
  );
}

