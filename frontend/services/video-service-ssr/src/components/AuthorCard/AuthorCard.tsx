'use client';

import { Author } from '../../types';
import Link from 'next/link';
import Image from 'next/image';
import styles from './AuthorCard.module.css';

interface AuthorCardProps {
  author: Author;
}

export default function AuthorCard({ author }: AuthorCardProps) {
  const displayName = author.title || author.name || 'Автор';
  const avatarUrl = author.imageURL || author.avatar_url;
  const initial = displayName.charAt(0).toUpperCase();
  
  return (
    <Link href={`/author/${author.id}`} className={styles['authorCard']}>
      <div className={styles['avatarWrapper']}>
        {avatarUrl ? (
          <Image
            src={avatarUrl}
            alt={displayName}
            width={80}
            height={80}
            className={styles['avatar']}
          />
        ) : (
          <div className={styles['avatarPlaceholder']}>
            {initial}
          </div>
        )}
      </div>
      <div className={styles['info']}>
        <h3 className={styles['title']}>{displayName}</h3>
        {author.subtitle && (
          <p className={styles['subtitle']}>{author.subtitle}</p>
        )}
        <div className={styles['stats']}>
          {author.videoCount !== undefined && (
            <span>{author.videoCount} видео</span>
          )}
          {author.followerCount !== undefined && (
            <span>{author.followerCount} подписчиков</span>
          )}
        </div>
      </div>
    </Link>
  );
}
