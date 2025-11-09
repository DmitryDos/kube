'use client';

import { useState, useCallback } from 'react';
import { SearchFilter } from '../../types';
import { PlayerBlock } from './PlayerBlock';
import { SearchBlock } from './SearchBlock';
import styles from './MainPageClient.module.css';

interface MainPageClientProps {
  initialQuery?: string;
  initialFilter?: SearchFilter;
}

export function MainPageClient({ initialQuery = '', initialFilter = 'all' }: MainPageClientProps) {
  const [isPlayerExpanded, setIsPlayerExpanded] = useState(false);
  const [currentVideoId, setCurrentVideoId] = useState<string | null>(null);

  const handleVideoClick = useCallback((videoId: string) => {
    setCurrentVideoId(videoId);
    if (!isPlayerExpanded) {
      setIsPlayerExpanded(true);
    }
  }, [isPlayerExpanded]);

  const handlePlayerToggle = useCallback(() => {
    setIsPlayerExpanded((prev) => !prev);
  }, []);

  return (
    <div className={`${styles['container']} ${isPlayerExpanded ? styles['withPlayer'] : ''}`}>
      <PlayerBlock
        videoId={currentVideoId}
        isExpanded={isPlayerExpanded}
        onToggle={handlePlayerToggle}
      />
      <SearchBlock
        initialQuery={initialQuery}
        initialFilter={initialFilter}
        isPlayerExpanded={isPlayerExpanded}
        onVideoClick={handleVideoClick}
      />
    </div>
  );
}

