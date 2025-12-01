// src/components/ProfileInfo/ProfileInfo.tsx
'use client';

import { User } from '../../types';
import styles from './ProfileInfo.module.css';

interface ProfileInfoProps {
  user: User;
}

export function ProfileInfo({ user }: ProfileInfoProps) {
  const formattedDate = user.created_at
    ? new Date(user.created_at).toLocaleDateString('ru-RU', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      })
    : null;

  return (
    <div className={styles['profile-info']}>
      <h1 className={styles['name']}>{user.name}</h1>
      <p className={styles['email']}>{user.email}</p>
      {formattedDate && (
        <p className={styles['date']}>Зарегистрирован: {formattedDate}</p>
      )}
    </div>
  );
}

