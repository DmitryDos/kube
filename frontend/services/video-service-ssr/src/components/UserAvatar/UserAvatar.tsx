// src/components/UserAvatar/UserAvatar.tsx
'use client';

import { User } from '../../types';
import styles from './UserAvatar.module.css';

interface UserAvatarProps {
  user: User | null;
  size?: number;
}

export function UserAvatar({ user, size = 100 }: UserAvatarProps) {
  const initials = user?.name
    ? user.name
        .split(' ')
        .map(n => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2)
    : '?';

  return (
    <div 
      className={styles['avatar']}
      style={{ width: size, height: size, fontSize: size * 0.4 }}
    >
      {user ? (
        <span className={styles['initials']}>{initials}</span>
      ) : (
        <svg 
          className={styles['icon']}
          viewBox="0 0 24 24" 
          fill="none" 
          stroke="currentColor" 
          strokeWidth="2"
        >
          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
          <circle cx="12" cy="7" r="4" />
        </svg>
      )}
    </div>
  );
}

