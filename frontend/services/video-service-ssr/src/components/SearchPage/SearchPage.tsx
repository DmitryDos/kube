// src/components/SearchPage/SearchPage.tsx
'use client';

import { useState, useCallback, useEffect, useRef } from 'react';
import { Search } from '../Search/Search';
import { SearchResults } from '../SearchResults/SearchResults';
import { VideoCard } from '../VideoCard/VideoCard';
import { AuthorCard } from '../AuthorCard/AuthorCard';
import { useSearch } from '../../hooks/useSearch';
import { SearchFilter, SearchResultItem, Video, Author } from '../../types';
import styles from './SearchPage.module.css';

interface SearchPageProps {
  onVideoClick?: (video: Video) => void;
  onAuthorClick?: (author: Author) => void;
}

export function SearchPage({ onVideoClick, onAuthorClick }: SearchPageProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState<SearchFilter>('all');
  const { search } = useSearch();
  const [results, setResults] = useState<SearchResultItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [loadMoreError, setLoadMoreError] = useState<string | null>(null);
  const [hasInitialSearch, setHasInitialSearch] = useState(false);
  const [lastAutoLoadFailed, setLastAutoLoadFailed] = useState(false);
  const searchRef = useRef(search);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  
  // Обновляем ref при изменении search
  useEffect(() => {
    searchRef.current = search;
  }, [search]);

  const performSearch = useCallback(async (query: string, filter: SearchFilter, page: number = 1, append: boolean = false, isAutoLoad: boolean = false) => {
    if (append) {
      setIsLoadingMore(true);
      setLoadMoreError(null);
      setLastAutoLoadFailed(false);
    } else {
      setIsLoading(true);
      setError(null);
      setLastAutoLoadFailed(false);
    }
    
    try {
      const response = await searchRef.current(query, page, 20, filter);
      
      if (append) {
        setResults(prev => [...prev, ...response.results]);
        // Если автоматическая загрузка не дала результатов, отмечаем это
        if (isAutoLoad) {
          if (response.results.length === 0) {
            setLastAutoLoadFailed(true);
          } else {
            setLastAutoLoadFailed(false);
          }
        }
      } else {
        setResults(response.results);
        setLastAutoLoadFailed(false);
      }
      
      // Проверяем, есть ли ещё страницы
      const totalPages = Math.ceil((response.pagination?.total || 0) / 20);
      setHasMore(page < totalPages && response.results.length > 0);
      setCurrentPage(page);
    } catch (err: any) {
      const errorMessage = err?.message || 'Ошибка при выполнении поиска';
      if (append) {
        setLoadMoreError(errorMessage);
        if (isAutoLoad) {
          setLastAutoLoadFailed(true);
        }
      } else {
        setError(errorMessage);
        setResults([]);
      }
    } finally {
      if (append) {
        setIsLoadingMore(false);
      } else {
        setIsLoading(false);
      }
    }
  }, []);

  const handleSearchChange = useCallback((value: string) => {
    setSearchQuery(value);
  }, []);

  const handleFilterChange = useCallback((filter: SearchFilter) => {
    setSelectedFilter(filter);
  }, []);

  const handleLoadMore = useCallback(() => {
    if (!isLoadingMore && hasMore) {
      performSearch(searchQuery, selectedFilter, currentPage + 1, true, false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoadingMore, hasMore, currentPage, searchQuery, selectedFilter]);

  // Автоматическая загрузка при прокрутке к концу
  useEffect(() => {
    const scrollContainer = scrollContainerRef.current;
    if (!scrollContainer || !hasMore || isLoadingMore) return;

    const handleScroll = () => {
      const { scrollTop, scrollHeight, clientHeight } = scrollContainer;
      // Загружаем когда осталось 200px до конца
      const threshold = 200;
      
      if (scrollHeight - scrollTop - clientHeight < threshold) {
        if (hasMore && !isLoadingMore) {
          performSearch(searchQuery, selectedFilter, currentPage + 1, true, true);
        }
      }
    };

    scrollContainer.addEventListener('scroll', handleScroll);
    return () => scrollContainer.removeEventListener('scroll', handleScroll);
  }, [hasMore, isLoadingMore, currentPage, searchQuery, selectedFilter, performSearch]);

  const handleSubmit = useCallback(() => {
    // Всегда делаем запрос, даже с пустым запросом
    performSearch(searchQuery.trim(), selectedFilter, 1, false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchQuery, selectedFilter]);

  // Выполняем начальный поиск при монтировании только один раз с пустым запросом
  useEffect(() => {
    if (!hasInitialSearch) {
      setHasInitialSearch(true);
      // Делаем автоматический запрос при первой загрузке с пустым запросом
      performSearch('', selectedFilter, 1, false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasInitialSearch]);

  // Выполняем поиск при изменении фильтра (но не при изменении запроса - только по submit)
  useEffect(() => {
    if (!hasInitialSearch) {
      return;
    }

    // Поиск при изменении фильтра делаем всегда, даже с пустым запросом
    performSearch(searchQuery.trim(), selectedFilter, 1, false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedFilter, hasInitialSearch]);

  const filteredResults = results.filter((item) => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'videos') return item.type === 'video';
    if (selectedFilter === 'authors') return item.type === 'author';
    return true;
  });

  return (
    <div className={styles['search-page']}>
      <div className={styles['search-header']}>
        <Search
          searchQuery={searchQuery}
          selectedFilter={selectedFilter}
          onSearchChange={handleSearchChange}
          onFilterChange={handleFilterChange}
          onSubmit={handleSubmit}
        />
      </div>
      <div className={styles['search-content']}>
        <div className={styles['search-results']} ref={scrollContainerRef}>
          <SearchResults
            isLoading={isLoading && results.length === 0}
            error={error}
            isEmpty={!isLoading && !error && filteredResults.length === 0 && searchQuery.trim() !== ''}
            emptyMessage={
              searchQuery ? 'Ничего не найдено' : 'Начните поиск'
            }
            emptyHint={
              searchQuery
                ? 'Попробуйте изменить запрос или фильтр'
                : 'Введите запрос в поле поиска'
            }
            onRetry={() => performSearch(searchQuery, selectedFilter, 1, false)}
            gap={12}
          >
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
          </SearchResults>

          {filteredResults.length > 0 && hasMore && (loadMoreError || lastAutoLoadFailed) && (
            <div className={styles['load-more-container']}>
              <button
                onClick={handleLoadMore}
                disabled={isLoadingMore}
                className={styles['load-more-button']}
              >
                {isLoadingMore ? (
                  <>
                    <div className={styles['spinner']}></div>
                    <span>Загрузка...</span>
                  </>
                ) : (
                  'Загрузить ещё'
                )}
              </button>
              {loadMoreError && (
                <p className={styles['load-more-error']}>
                  Не удалось загрузить видео, попробуйте в другой раз
                </p>
              )}
            </div>
          )}
          
          {isLoadingMore && filteredResults.length > 0 && (
            <div className={styles['loading-more']}>
              <div className={styles['spinner']}></div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

