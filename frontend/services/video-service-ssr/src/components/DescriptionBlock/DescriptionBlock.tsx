// src/components/DescriptionBlock/DescriptionBlock.tsx
'use client';

import { useState, useRef, useEffect } from 'react';
import styles from './DescriptionBlock.module.css';

interface DescriptionBlockProps {
  title: string;
  description?: string;
  authorName?: string;
  createdAt?: string;
  viewCount?: number;
  likeCount?: number;
}

export function DescriptionBlock({
  title,
  description,
  authorName,
  createdAt,
  viewCount,
  likeCount
}: DescriptionBlockProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const expandedRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isExpanded && expandedRef.current && containerRef.current) {
      const containerRect = containerRef.current.getBoundingClientRect();
      const availableHeight = containerRect.top;
      const minHeight = Math.max(250, window.innerHeight * 0.3); // Минимум 250px или 30% экрана
      const maxHeight = Math.min(availableHeight, window.innerHeight * 0.425); // Максимум 42.5% экрана или доступная высота
      expandedRef.current.style.minHeight = `${minHeight}px`;
      expandedRef.current.style.maxHeight = `${maxHeight}px`;
      expandedRef.current.style.bottom = `${window.innerHeight - containerRect.bottom}px`;
    }
  }, [isExpanded]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (isExpanded && expandedRef.current && !expandedRef.current.contains(e.target as Node) && containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsExpanded(false);
      }
    };

    if (isExpanded) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isExpanded]);

  const handleToggle = () => {
    setIsExpanded(!isExpanded);
  };

  return (
    <div ref={containerRef} className={styles['description-container']}>
      <div 
        className={styles['description-preview']}
        onClick={handleToggle}
      >
        <div className={styles['description-content']}>
          <h3 className={styles['title']}>{title}</h3>
          {authorName && (
            <span className={styles['author']}>{authorName}</span>
          )}
          {description && (
            <p className={styles['description-text']}>{description}</p>
          )}
        </div>
        {description && (
          <button
            className={styles['expand-button']}
            onClick={(e) => {
              e.stopPropagation();
              handleToggle();
            }}
            aria-label={isExpanded ? 'Свернуть' : 'Развернуть'}
          >
            <svg 
              width="16" 
              height="16" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="currentColor" 
              strokeWidth="2"
              className={isExpanded ? styles['expanded-icon'] : ''}
            >
              <path d="M6 9l6 6 6-6" />
            </svg>
          </button>
        )}
      </div>
      {isExpanded && (
        <>
          <div 
            className={styles['description-overlay']}
            onClick={() => setIsExpanded(false)}
          />
          <div 
            ref={expandedRef}
            className={styles['description-expanded']}
            onClick={(e) => e.stopPropagation()}
          >
          <div className={styles['expanded-content']}>
            <div className={styles['expanded-header']}>
              <h3 className={styles['expanded-title']}>{title}</h3>
              {authorName && (
                <div className={styles['expanded-author']}>{authorName}</div>
              )}
              {(viewCount !== undefined || likeCount !== undefined || createdAt) && (
                <div className={styles['expanded-meta']}>
                  {viewCount !== undefined && (
                    <span>{viewCount.toLocaleString()} просмотров</span>
                  )}
                  {likeCount !== undefined && (
                    <span>{likeCount.toLocaleString()} лайков</span>
                  )}
                  {createdAt && (
                    <span>{new Date(createdAt).toLocaleDateString('ru-RU')}</span>
                  )}
                </div>
              )}
            </div>
            {description && (
              <div className={styles['expanded-description']}>
                {description.split('\n').map((paragraph, index) => (
                  <p key={index}>{paragraph}</p>
                ))}
              </div>
            )}
          </div>
        </div>
        </>
      )}
    </div>
  );
}

