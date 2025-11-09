'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import dynamic from 'next/dynamic';
import { useSearch } from '../../../hooks/useSearch';
import { SearchResultItem, SearchFilter } from '../../../types';
import { Loading } from '../../../components/Loading/Loading';
import { Error } from '../../../components/Error/Error';
import { Empty } from '../../../components/Empty/Empty';
import styles from './SearchPageClient.module.css';

const SearchBar = dynamic(() => import('../../../components/SearchBar/SearchBar'), { ssr: false });
const FilterChips = dynamic(() => import('../../../components/FilterChips/FilterChips'), { ssr: false });
const VideoCard = dynamic(() => import('../../../components/VideoCard/VideoCard'), { ssr: false });
const AuthorCard = dynamic(() => import('../../../components/AuthorCard/AuthorCard'), { ssr: false });

interface SearchPageClientProps {
  initialQuery?: string;
  initialFilter?: SearchFilter;
}

export function SearchPageClient({ initialQuery = '', initialFilter = 'all' }: SearchPageClientProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { search, isLoading: searchLoading, error: searchError } = useSearch();
  const [searchText, setSearchText] = useState(initialQuery);
  const [selectedFilter, setSelectedFilter] = useState<SearchFilter>(initialFilter);
  const [results, setResults] = useState<SearchResultItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  const performSearch = useCallback(
    async (query: string = searchText, filter: SearchFilter = selectedFilter, pageNum: number = 1, append: boolean = false) => {
      setError(null);

      try {
        const response = await search(query, pageNum, 20, filter);
        
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
          if (errorMessage?.includes('Network Error') || errorMessage?.includes('ERR_NETWORK')) {
            setError('Не удалось подключиться к серверу. Проверьте, что API Gateway запущен на порту 8080.');
          } else {
            setError(`Ошибка загрузки результатов: ${errorMessage}`);
          }
        } else {
          setError('Ошибка загрузки результатов');
        }
        if (!append) {
          setResults([]);
        }
      }
    },
    [search, searchText, selectedFilter]
  );

  useEffect(() => {
    const query = searchParams.get('q') || initialQuery;
    const filter = (searchParams.get('filter') as SearchFilter) || initialFilter;
    
    setSearchText(query);
    setSelectedFilter(filter);
    performSearch(query, filter, 1, false);
  }, [searchParams, initialQuery, initialFilter, performSearch]);

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (searchText) params.set('q', searchText);
    if (selectedFilter !== 'all') params.set('filter', selectedFilter);
    router.push(`/search?${params.toString()}`);
  };

  const handleClear = () => {
    setSearchText('');
    router.push('/search');
  };

  const handleFilterChange = (filter: SearchFilter) => {
    setSelectedFilter(filter);
    const params = new URLSearchParams();
    if (searchText) params.set('q', searchText);
    if (filter !== 'all') params.set('filter', filter);
    router.push(`/search?${params.toString()}`);
  };

  const handleLoadMore = () => {
    if (!searchLoading && hasMore) {
      performSearch(searchText, selectedFilter, page + 1, true);
    }
  };

  const filteredResults = results.filter((item) => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'videos') return item.type === 'video';
    if (selectedFilter === 'authors') return item.type === 'author';
    return true;
  });

  return (
    <div className={styles['container']}>
      <SearchBar
        value={searchText}
        onChange={setSearchText}
        onSubmit={handleSearch}
        onClear={handleClear}
      />
      
      <FilterChips selected={selectedFilter} onChange={handleFilterChange} />

      <main className={styles['main']}>
        {searchLoading && results.length === 0 ? (
          <Loading message="Ищем..." />
        ) : (error || searchError) ? (
          <Error title="Ошибка поиска" message={error || searchError || 'Ошибка загрузки'} onRetry={handleSearch} />
        ) : filteredResults.length === 0 ? (
          <Empty
            title={searchText ? 'Ничего не найдено' : 'Популярные видео'}
            message={
              searchText
                ? 'Попробуйте изменить запрос или фильтр'
                : 'Начните поиск чтобы найти видео и авторов'
            }
          />
        ) : (
          <>
            <div className={styles['results']}>
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
                  <button onClick={handleLoadMore} className={styles['loadMoreButton']}>
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

