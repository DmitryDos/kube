'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import dynamic from 'next/dynamic';
import { useSearch } from '../../hooks/useSearch';
import { useVideoPlayback } from '../../contexts/VideoPlaybackContext';
import { SearchResultItem, SearchFilter, Video } from '../../types';
import { Loading } from '../../components/Loading/Loading';
import { Error } from '../../components/Error/Error';
import { Empty } from '../../components/Empty/Empty';
import styles from './SearchBlock.module.css';

const SearchBar = dynamic(() => import('../../components/SearchBar/SearchBar'), { ssr: false });
const FilterChips = dynamic(() => import('../../components/FilterChips/FilterChips'), { ssr: false });
const VideoCard = dynamic(() => import('../../components/VideoCard/VideoCard'), { ssr: false });
const AuthorCard = dynamic(() => import('../../components/AuthorCard/AuthorCard'), { ssr: false });

interface SearchBlockProps {
  initialQuery?: string;
  initialFilter?: SearchFilter;
  isPlayerExpanded: boolean;
  onVideoClick: (videoId: string) => void;
}

export function SearchBlock({ initialQuery = '', initialFilter = 'all', isPlayerExpanded, onVideoClick }: SearchBlockProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { search, isLoading: searchLoading, error: searchError } = useSearch();
  const { setOnVideoClick } = useVideoPlayback();
  
  const [searchText, setSearchText] = useState(initialQuery);
  const [selectedFilter, setSelectedFilter] = useState<SearchFilter>(initialFilter);
  const [results, setResults] = useState<SearchResultItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  const performSearch = useCallback(
    async (query: string, filter: SearchFilter, pageNum: number = 1, append: boolean = false) => {
      setError(null);
      console.log('Performing search:', { query, filter, pageNum });
      try {
        const response = await search(query, pageNum, 20, filter);
        console.log('Search response:', response);
        if (append) {
          setResults((prev) => [...prev, ...response.results]);
        } else {
          setResults(response.results);
        }
        setHasMore(response.results.length >= 20);
        setPage(pageNum);
      } catch (err: unknown) {
        console.error('Search error:', err);
        if (err && typeof err === 'object' && 'message' in err) {
          const errorMessage = (err as { message?: string }).message;
          setError(errorMessage?.includes('Network Error') ? 'Не удалось подключиться к серверу' : `Ошибка: ${errorMessage}`);
        } else {
          setError('Ошибка загрузки результатов');
        }
        if (!append) setResults([]);
      }
    },
    [search]
  );

  useEffect(() => {
    console.log('SearchBlock mounted, initialQuery:', initialQuery, 'initialFilter:', initialFilter);
    const query = searchParams.get('q') || initialQuery;
    const filter = (searchParams.get('filter') as SearchFilter) || initialFilter;
    console.log('Setting search params:', { query, filter });
    setSearchText(query);
    setSelectedFilter(filter);
    // Всегда выполняем поиск, даже если запрос пустой (для популярных видео)
    console.log('Calling performSearch with:', { query, filter });
    performSearch(query, filter, 1, false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams, initialQuery, initialFilter]);

  const handleVideoClick = useCallback((video: Video) => {
    onVideoClick(video.id);
  }, [onVideoClick]);

  useEffect(() => {
    if (setOnVideoClick) {
      setOnVideoClick(handleVideoClick);
    }
    return () => {
      if (setOnVideoClick) {
        setOnVideoClick(undefined);
      }
    };
  }, [handleVideoClick, setOnVideoClick]);

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (searchText) params.set('q', searchText);
    if (selectedFilter !== 'all') params.set('filter', selectedFilter);
    router.push(`/main?${params.toString()}`);
  };

  const handleFilterChange = (filter: SearchFilter) => {
    setSelectedFilter(filter);
    const params = new URLSearchParams();
    if (searchText) params.set('q', searchText);
    if (filter !== 'all') params.set('filter', filter);
    router.push(`/main?${params.toString()}`);
  };

  const filteredResults = results.filter((item) => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'videos') return item.type === 'video';
    if (selectedFilter === 'authors') return item.type === 'author';
    return true;
  });

  const isMobile = typeof window !== 'undefined' && window.innerWidth < 768;
  const shouldFixWidth = !isMobile && isPlayerExpanded;

  return (
    <div className={`${styles['searchContainer']} ${shouldFixWidth ? styles['withPlayer'] : ''}`}>
      <SearchBar
        value={searchText}
        onChange={setSearchText}
        onSubmit={handleSearch}
        onClear={() => {
          setSearchText('');
          router.push('/main');
        }}
      />
      <FilterChips selected={selectedFilter} onChange={handleFilterChange} />
      <main className={`${styles['main']} ${shouldFixWidth ? styles['withPlayer'] : ''}`}>
        {searchLoading && results.length === 0 ? (
          <Loading message="Ищем..." />
        ) : (error || searchError) ? (
          <Error title="Ошибка поиска" message={error || searchError || 'Ошибка загрузки'} onRetry={handleSearch} />
        ) : filteredResults.length === 0 ? (
          <Empty
            title={searchText ? 'Ничего не найдено' : 'Популярные видео'}
            message={searchText ? 'Попробуйте изменить запрос' : 'Начните поиск'}
          />
        ) : (
          <>
            <div className={`${styles['results']} ${shouldFixWidth ? styles['withPlayer'] : ''}`}>
              {filteredResults.map((item, index) => (
                <div key={`${item.type}-${item.data?.id || index}`}>
                  {item.type === 'video' && item.data ? (
                    <VideoCard video={item.data} />
                  ) : item.type === 'author' && item.data ? (
                    <AuthorCard author={item.data} />
                  ) : null}
                </div>
              ))}
            </div>
            {hasMore && (
              <div className={styles['loadMore']}>
                {searchLoading ? (
                  <div className={styles['spinner']}></div>
                ) : (
                  <button onClick={() => performSearch(searchText, selectedFilter, page + 1, true)} className={styles['loadMoreButton']}>
                    Загрузить еще
                  </button>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}

