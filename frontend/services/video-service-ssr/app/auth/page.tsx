// app/auth/page.tsx
'use client';

import { AuthPage } from '../../src/components/AuthPage/AuthPage';
import { ProfilePage } from '../../src/components/ProfilePage/ProfilePage';
import { useAuth } from '../../src/hooks/useAuth';
import styles from './page.module.css';

export default function AuthRoute() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className={styles['loading-container']}>
        <div className={styles['spinner']}></div>
      </div>
    );
  }

  if (isAuthenticated) {
    return <ProfilePage />;
  }

  return <AuthPage />;
}

