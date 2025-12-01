// src/components/ProfilePage/ProfilePage.tsx
'use client';

import { useAuth } from '../../hooks/useAuth';
import { UserAvatar } from '../UserAvatar/UserAvatar';
import { ProfileInfo } from '../ProfileInfo/ProfileInfo';
import { ProfileActions } from '../ProfileActions/ProfileActions';
import styles from './ProfilePage.module.css';

export function ProfilePage() {
  const { currentUser, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className={styles['profile-page']}>
        <div className={styles['loading']}>
          <div className={styles['spinner']}></div>
        </div>
      </div>
    );
  }

  if (!currentUser) {
    return null;
  }

  return (
    <div className={styles['profile-page']}>
      <div className={styles['profile-header']}>
        <UserAvatar user={currentUser} size={120} />
        <ProfileInfo user={currentUser} />
      </div>
      <ProfileActions />
    </div>
  );
}

