// src/components/AuthorCard/AuthorCard.tsx
'use client';

import { Author } from '../../types';
import { Avatar } from '../Avatar/Avatar';
import styles from './AuthorCard.module.css';

interface AuthorCardProps {
  author: Author;
  onClick?: (author: Author) => void;
}

export function AuthorCard({ author, onClick }: AuthorCardProps) {
  const displayName = author.name || author.title || 'Автор';
  
  // Проверяем валидность URL для аватара
  const avatarUrl = author.avatar_url || author.imageURL;
  const isValidAvatarUrl = avatarUrl && (
    avatarUrl.startsWith('http://') || 
    avatarUrl.startsWith('https://') || 
    avatarUrl.startsWith('/') ||
    avatarUrl.startsWith('data:')
  );
  
  const authorVideo = {
    id: author.id,
    title: displayName,
    thumbnail_url: isValidAvatarUrl ? avatarUrl : undefined,
  } as any;

  return (
    <div className={styles['author-card']} onClick={() => onClick?.(author)}>
      <Avatar video={authorVideo} size={48} />
      
      <div className={styles['info']}>
        <h3 className={styles['name']}>{displayName}</h3>
        {author.subtitle && <p className={styles['subtitle']}>{author.subtitle}</p>}
      </div>
      
      <div className={styles['stats']}>
        {author.videoCount !== undefined && (
          <span>{author.videoCount} видео</span>
        )}
        {author.followerCount !== undefined && (
          <span>{author.followerCount} подписчиков</span>
        )}
      </div>
    </div>
  );
}