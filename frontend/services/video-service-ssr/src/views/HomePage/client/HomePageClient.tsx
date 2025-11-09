'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import dynamic from 'next/dynamic';
import { useSearch } from '../../../hooks/useSearch';
import { useVideo } from '../../../hooks/useVideo';
import { useVideoStream } from '../../../hooks/useVideoStream';
import { useVideoPlayback } from '../../../contexts/VideoPlaybackContext';
import { useModal } from '../../../contexts/ModalContext';
import { SearchResultItem, SearchFilter, Video } from '../../../types';
import { Loading } from '../../../components/Loading/Loading';
import { Error } from '../../../components/Error/Error';
import { Empty } from '../../../components/Empty/Empty';
import { VideoPlayerControls } from '../../../components/VideoPlayerControls/VideoPlayerControls';
import { AuthModalContent } from '../../../components/AuthModal/AuthModal';
import styles from './HomePageClient.module.css';

const SearchBar = dynamic(() => import('../../../components/SearchBar/SearchBar'), { ssr: false });
const FilterChips = dynamic(() => import('../../../components/FilterChips/FilterChips'), { ssr: false });
const VideoCard = dynamic(() => import('../../../components/VideoCard/VideoCard'), { ssr: false });
const AuthorCard = dynamic(() => import('../../../components/AuthorCard/AuthorCard'), { ssr: false });

interface HomePageClientProps {
  initialQuery?: string;
  initialFilter?: SearchFilter;
}

export function HomePageClient({ initialQuery = '', initialFilter = 'all' }: HomePageClientProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { search, isLoading: searchLoading, error: searchError } = useSearch();
  const { getVideo } = useVideo();
  const { getVideoStreamURL } = useVideoStream();
  const { videoElement, setVideoElement, setVideoUrl, requestPip, isPipActive, setOnVideoClick } = useVideoPlayback();
  const { openModal, closeModal } = useModal();
  
  const [searchText, setSearchText] = useState(initialQuery);
  const [selectedFilter, setSelectedFilter] = useState<SearchFilter>(initialFilter);
  const [results, setResults] = useState<SearchResultItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  
  // Player state
  const [isPlayerExpanded, setIsPlayerExpanded] = useState(false);
  const [currentVideo, setCurrentVideo] = useState<Video | null>(null);
  const [videoUrl, setVideoUrlState] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [playbackRate, setPlaybackRate] = useState(1);
  const [isFullscreen, setIsFullscreen] = useState(false);
  
  const playerVideoRef = useRef<HTMLVideoElement | null>(null);
  const searchContainerRef = useRef<HTMLDivElement>(null);
  const playerContainerRef = useRef<HTMLDivElement>(null);
  const isMobile = typeof window !== 'undefined' && window.innerWidth < 768;

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

  // Video element setup
  useEffect(() => {
    const video = playerVideoRef.current;
    if (!video) return;

    const updateTime = () => setCurrentTime(video.currentTime);
    const updateDuration = () => setDuration(video.duration);
    const handlePlay = () => {
      setIsPlaying(true);
    };
    const handlePause = () => {
      setIsPlaying(false);
    };
    const handlePlaying = () => setIsPlaying(true);
    const handleWaiting = () => setIsPlaying(false);
    const handleFullscreenChange = () => {
      const isFullscreenNow = !!document.fullscreenElement;
      setIsFullscreen(isFullscreenNow);
      
      // Восстанавливаем стили при выходе из полноэкранного режима
      if (!isFullscreenNow && video) {
        video.style.position = '';
        video.style.top = '';
        video.style.left = '';
        video.style.width = '';
        video.style.height = '';
        video.style.zIndex = '';
        video.style.backgroundColor = '';
        closeModal('search-fullscreen');
      }
    };

    // Устанавливаем начальное состояние
    setIsPlaying(!video.paused);

    video.addEventListener('timeupdate', updateTime);
    video.addEventListener('loadedmetadata', updateDuration);
    video.addEventListener('play', handlePlay);
    video.addEventListener('playing', handlePlaying);
    video.addEventListener('pause', handlePause);
    video.addEventListener('waiting', handleWaiting);
    document.addEventListener('fullscreenchange', handleFullscreenChange);

    return () => {
      video.removeEventListener('timeupdate', updateTime);
      video.removeEventListener('loadedmetadata', updateDuration);
      video.removeEventListener('play', handlePlay);
      video.removeEventListener('playing', handlePlaying);
      video.removeEventListener('pause', handlePause);
      video.removeEventListener('waiting', handleWaiting);
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
    };
  }, [closeModal]);

  // Set video URL
  useEffect(() => {
    const video = playerVideoRef.current;
    if (!video || !videoUrl) return;
    if (video.src !== videoUrl) {
      video.src = videoUrl;
    }
  }, [videoUrl]);

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (searchText) params.set('q', searchText);
    if (selectedFilter !== 'all') params.set('filter', selectedFilter);
    router.push(`/?${params.toString()}`);
  };

  const handleClear = () => {
    setSearchText('');
    router.push('/');
  };

  const handleFilterChange = (filter: SearchFilter) => {
    setSelectedFilter(filter);
    const params = new URLSearchParams();
    if (searchText) params.set('q', searchText);
    if (filter !== 'all') params.set('filter', filter);
    router.push(`/?${params.toString()}`);
  };

  const handleLoadMore = () => {
    if (!searchLoading && hasMore) {
      performSearch(searchText, selectedFilter, page + 1, true);
    }
  };

  const handleVideoClick = useCallback(async (video: Video) => {
    if (isPlayerExpanded && currentVideo?.id === video.id) {
      // Если плеер уже открыт с этим видео - ничего не делаем
      return;
    }

    // Загружаем видео
    const streamUrl = await getVideoStreamURL(video.id);
    setCurrentVideo(video);
    setVideoUrlState(streamUrl);
    
    // Если плеер развернут - переключаем видео
    if (isPlayerExpanded && playerVideoRef.current) {
      playerVideoRef.current.src = streamUrl;
      playerVideoRef.current.play().catch(console.error);
    } else if (!isPlayerExpanded && !currentVideo) {
      // Если плеер свернут и это первое видео - раскрываем плеер
      setIsPlayerExpanded(true);
    }
    // Если плеер свернут и уже есть видео - только меняем ссылку (не раскрываем)
  }, [isPlayerExpanded, currentVideo, getVideoStreamURL]);

  // Устанавливаем обработчик клика по видео
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

  const handlePlayerToggle = async () => {
    if (isPlayerExpanded) {
      // Сворачиваем плеер и открываем PiP
      if (playerVideoRef.current && !playerVideoRef.current.paused) {
        try {
          await requestPip();
        } catch (err) {
          console.error('Failed to enter PIP:', err);
        }
      }
      setIsPlayerExpanded(false);
    } else {
      // Раскрываем плеер и закрываем PiP
      if (isPipActive && document.pictureInPictureElement) {
        try {
          await document.exitPictureInPicture();
        } catch (err) {
          console.error('Failed to exit PIP:', err);
        }
      }
      setIsPlayerExpanded(true);
    }
  };

  const handleFullscreen = async () => {
    const video = playerVideoRef.current;
    if (!video) return;

    try {
      if (!isFullscreen) {
        // Делаем видео на весь экран
        video.style.position = 'fixed';
        video.style.top = '0';
        video.style.left = '0';
        video.style.width = '100vw';
        video.style.height = '100vh';
        video.style.zIndex = '9998';
        video.style.backgroundColor = '#000';
        setIsFullscreen(true);
        
        // Функция для открытия модалки поиска
        const openSearchModal = () => {
          openModal({
            id: 'search-fullscreen',
            title: 'Поиск',
            content: (
              <div className={styles['fullscreenSearch']}>
                <SearchBar
                  value={searchText}
                  onChange={setSearchText}
                  onSubmit={handleSearch}
                  onClear={handleClear}
                />
                <FilterChips selected={selectedFilter} onChange={handleFilterChange} />
                <div className={styles['fullscreenResults']}>
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
              </div>
            ),
            leftButton: {
              label: 'Выйти из полноэкранного режима',
              onClick: async () => {
                if (document.exitFullscreen) {
                  await document.exitFullscreen();
                }
              },
            },
          });
        };
        
        // Открываем модалку поиска справа при наведении или клике
        const handleMouseMove = (e: MouseEvent) => {
          if (e.clientX > window.innerWidth - 100) {
            openSearchModal();
            document.removeEventListener('mousemove', handleMouseMove);
          }
        };
        
        const handleClick = (e: MouseEvent) => {
          if (e.clientX > window.innerWidth - 100) {
            openSearchModal();
          }
        };
        
        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('click', handleClick);
      } else {
        // Выход из полноэкранного режима
        if (document.exitFullscreen) {
          await document.exitFullscreen();
        }
      }
    } catch (error) {
      console.error('Fullscreen error:', error);
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
      <div
        ref={searchContainerRef}
        className={`${styles['searchContainer']} ${isPlayerExpanded ? (isMobile ? styles['collapsedVertical'] : styles['collapsedHorizontal']) : ''}`}
      >
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

      <div
        ref={playerContainerRef}
        className={`${styles['playerContainer']} ${isPlayerExpanded ? styles['expanded'] : styles['collapsed']}`}
      >
        {currentVideo && videoUrl && (
          <>
            <button
              className={styles['toggleButton']}
              onClick={handlePlayerToggle}
              aria-label={isPlayerExpanded ? 'Свернуть' : 'Развернуть'}
            >
              {isPlayerExpanded ? (
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M19 12H5M12 19l-7-7 7-7" />
                </svg>
              ) : (
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M5 12h14M12 5l7 7-7 7" />
                </svg>
              )}
            </button>
            <div className={styles['playerWrapper']}>
              <video
                ref={playerVideoRef}
                playsInline
                className={styles['video']}
              />
              <VideoPlayerControls
                videoElement={playerVideoRef.current}
                isPlaying={isPlaying}
                currentTime={currentTime}
                duration={duration}
                volume={volume}
                isMuted={isMuted}
                playbackRate={playbackRate}
                onPlayPause={() => {
                  const video = playerVideoRef.current;
                  if (!video) return;
                  if (video.paused) {
                    video.play().catch(console.error);
                  } else {
                    video.pause();
                  }
                }}
                onSeek={(time) => {
                  const video = playerVideoRef.current;
                  if (!video) return;
                  video.currentTime = time;
                }}
                onVolumeChange={(vol) => {
                  const video = playerVideoRef.current;
                  if (!video) return;
                  video.volume = vol;
                  setVolume(vol);
                  setIsMuted(vol === 0);
                }}
                onMuteToggle={() => {
                  const video = playerVideoRef.current;
                  if (!video) return;
                  video.muted = !isMuted;
                  setIsMuted(!isMuted);
                }}
                onPlaybackRateChange={(rate) => {
                  const video = playerVideoRef.current;
                  if (!video) return;
                  video.playbackRate = rate;
                  setPlaybackRate(rate);
                }}
                onSkipForward={() => {
                  const video = playerVideoRef.current;
                  if (!video) return;
                  video.currentTime = Math.min(video.currentTime + 10, duration);
                }}
                onSkipBackward={() => {
                  const video = playerVideoRef.current;
                  if (!video) return;
                  video.currentTime = Math.max(video.currentTime - 10, 0);
                }}
                onFullscreen={handleFullscreen}
                onPictureInPicture={requestPip}
                isPipActive={isPipActive}
                showFullscreen={true}
                showPip={true}
              />
            </div>
            {currentVideo && (
              <div className={styles['videoInfo']}>
                <h3 className={styles['videoTitle']}>{currentVideo.title}</h3>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

