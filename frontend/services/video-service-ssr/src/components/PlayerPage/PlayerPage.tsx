// src/components/PlayerPage/PlayerPage.tsx
'use client';

import { useState, useEffect } from 'react';
import { Player } from '../Player/Player';
import { Search } from '../Search/Search';
import { List } from '../List/List';
import { VideoCard } from '../VideoCard/VideoCard';
import { AuthorCard } from '../AuthorCard/AuthorCard';
import { useVideo } from '../../hooks/useVideo';
import { useSearch } from '../../hooks/useSearch';
import { Video, Author, SearchFilter, SearchResultItem } from '../../types';
import styles from './PlayerPage.module.css';

interface PlayerPageProps {
  videoId: string;
  onVideoClick?: (video: Video) => void;
  onAuthorClick?: (author: Author) => void;
}

function PlayerContent({ videoId }: { videoId: string }) {
  const { getVideo } = useVideo();
  const [video, setVideo] = useState<Video | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    setError(null);
    
    getVideo(videoId)
      .then((videoData) => {
        if (!cancelled) {
          setVideo(videoData);
          setIsLoading(false);
        }
      })
      .catch((err: any) => {
        if (!cancelled) {
          const errorMessage = err?.message || err?.networkError?.message || 'Ошибка загрузки видео. Проверьте подключение к интернету.';
          setError(errorMessage);
          setIsLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [videoId]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <Player 
      video={video} 
      authorName="Автор" 
      isLoading={isLoading}
      error={error}
    />
  );
}

function SearchResultsContent({ 
  searchQuery, 
  selectedFilter, 
  onVideoClick, 
  onAuthorClick 
}: { 
  searchQuery: string; 
  selectedFilter: SearchFilter;
  onVideoClick?: (video: Video) => void;
  onAuthorClick?: (author: Author) => void;
}) {
  const { search } = useSearch();
  const [results, setResults] = useState<SearchResultItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!searchQuery.trim()) {
      setResults([]);
      setIsLoading(false);
      return;
    }

    let cancelled = false;
    setIsLoading(true);
    setError(null);
    
    const timer = setTimeout(() => {
      search(searchQuery, 1, 20, selectedFilter)
        .then((response) => {
          if (!cancelled) {
            setResults(response.results);
            setIsLoading(false);
          }
        })
        .catch((err: any) => {
          if (!cancelled) {
            const errorMessage = err?.message || err?.networkError?.message || 'Ошибка поиска. Проверьте подключение к интернету.';
            setError(errorMessage);
            setIsLoading(false);
          }
        });
    }, 300);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [searchQuery, selectedFilter]); // eslint-disable-line react-hooks/exhaustive-deps

  const filteredResults = results.filter((item) => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'videos') return item.type === 'video';
    if (selectedFilter === 'authors') return item.type === 'author';
    return true;
  });

  if (isLoading && results.length === 0) {
    return (
      <div className={styles['loading']}>
        <div className={styles['spinner']}></div>
        <p>Ищем...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles['error']}>
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
        <p>{error}</p>
      </div>
    );
  }

  if (filteredResults.length === 0 && searchQuery) {
    return (
      <div className={styles['empty']}>
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.35-4.35" />
        </svg>
        <p>Ничего не найдено</p>
      </div>
    );
  }

  if (filteredResults.length === 0) {
    return null;
  }

  return (
    <List gap={12} columns={1}>
      {filteredResults.map((item) => {
        if (item.type === 'video') {
          return (
            <VideoCard
              key={item.data.id}
              video={item.data}
              onClick={onVideoClick}
            />
          );
        } else {
          return (
            <AuthorCard
              key={item.data.id}
              author={item.data}
              onClick={onAuthorClick}
            />
          );
        }
      })}
    </List>
  );
}

export function PlayerPage({ videoId, onVideoClick, onAuthorClick }: PlayerPageProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState<SearchFilter>('all');
  const [isWideFormat, setIsWideFormat] = useState(false);

  const handleSearchChange = (value: string) => {
    setSearchQuery(value);
  };

  const handleFilterChange = (filter: SearchFilter) => {
    setSelectedFilter(filter);
  };

  const handleToggleFormat = () => {
    setIsWideFormat(!isWideFormat);
  };

  return (
    <div className={`${styles['player-page']} ${isWideFormat ? styles['wide-format'] : ''}`}>
      <div className={styles['player-section']}>
        <PlayerContent videoId={videoId} />
        <button
          className={styles['format-toggle']}
          onClick={handleToggleFormat}
          aria-label={isWideFormat ? 'Узкий формат' : 'Широкий формат'}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            {isWideFormat ? (
              <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3" />
            ) : (
              <path d="M3 3h18v18H3z" />
            )}
          </svg>
        </button>
      </div>
      {!isWideFormat && (
        <div className={styles['search-section']}>
          <div className={styles['search-container']}>
            <Search
              searchQuery={searchQuery}
              selectedFilter={selectedFilter}
              onSearchChange={handleSearchChange}
              onFilterChange={handleFilterChange}
              onClear={() => setSearchQuery('')}
            />
            <div className={styles['search-results']}>
              <SearchResultsContent
                searchQuery={searchQuery}
                selectedFilter={selectedFilter}
                onVideoClick={onVideoClick}
                onAuthorClick={onAuthorClick}
              />
            </div>
          </div>
        </div>
      )}
      {isWideFormat && (
        <div className={styles['search-section-wide']}>
          <div className={styles['search-container']}>
            <Search
              searchQuery={searchQuery}
              selectedFilter={selectedFilter}
              onSearchChange={handleSearchChange}
              onFilterChange={handleFilterChange}
              onClear={() => setSearchQuery('')}
            />
            <div className={styles['search-results']}>
              <SearchResultsContent
                searchQuery={searchQuery}
                selectedFilter={selectedFilter}
                onVideoClick={onVideoClick}
                onAuthorClick={onAuthorClick}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

