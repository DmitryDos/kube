// src/components/PlayerPage/PlayerPage.tsx
'use client';

import { useState, useEffect, useRef } from 'react';
import { Player } from '../Player/Player';
import { SearchPage } from '../SearchPage/SearchPage';
import { useVideo } from '../../hooks/useVideo';
import { Video, Author } from '../../types';
import styles from './PlayerPage.module.css';

interface PlayerPageProps {
  videoId?: string;
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


export function PlayerPage({ videoId: initialVideoId, onVideoClick, onAuthorClick }: PlayerPageProps) {
  const [selectedVideoId, setSelectedVideoId] = useState<string | undefined>(
    initialVideoId && initialVideoId.trim() !== '' ? initialVideoId : undefined
  );
  const [isWideFormat, setIsWideFormat] = useState(false);
  const pageRef = useRef<HTMLDivElement>(null);
  const searchContainerRef = useRef<HTMLDivElement>(null);
  const searchSectionRef = useRef<HTMLDivElement>(null);

  // Обновляем selectedVideoId при изменении initialVideoId
  useEffect(() => {
    setSelectedVideoId(
      initialVideoId && initialVideoId.trim() !== '' ? initialVideoId : undefined
    );
  }, [initialVideoId]);

  const handleVideoClick = (video: Video) => {
    setSelectedVideoId(video.id);
    onVideoClick?.(video);
  };

  const handleToggleFormat = () => {
    setIsWideFormat(!isWideFormat);
  };

  // Если видео не выбрано, показываем только SearchPage
  if (!selectedVideoId) {
    return (
      <div style={{ width: '100%', height: '100vh', overflow: 'auto' }}>
        <SearchPage
          onVideoClick={handleVideoClick}
          onAuthorClick={onAuthorClick}
        />
      </div>
    );
  }

  // Проверяем видимость секции для разрешения скролла (только когда видео выбрано)
  useEffect(() => {
    if (!selectedVideoId) return;
    
    const page = pageRef.current;
    const searchSection = searchSectionRef.current;
    const searchContainer = searchContainerRef.current;
    
    if (!page || !searchSection || !searchContainer) return;

    const checkVisibility = () => {
      const pageScrollTop = page.scrollTop;
      const pageHeight = page.clientHeight;
      const sectionTop = searchSection.offsetTop;
      const sectionHeight = searchSection.offsetHeight;
      const sectionBottom = sectionTop + sectionHeight;
      
      // Секция полностью видна, если её нижняя граница находится в видимой области
      const isVisible = pageScrollTop + pageHeight >= sectionBottom;
      
      // Управляем скроллом через класс на search-section
      if (isVisible) {
        searchSection.classList.add('scroll-enabled');
      } else {
        searchSection.classList.remove('scroll-enabled');
      }
    };

    checkVisibility();
    page.addEventListener('scroll', checkVisibility);
    window.addEventListener('resize', checkVisibility);
    
    return () => {
      page.removeEventListener('scroll', checkVisibility);
      window.removeEventListener('resize', checkVisibility);
    };
  }, [selectedVideoId]);


  // Каскадный скролл: когда скроллишь список вверх и он уже в начале, секция закрывается (только когда видео выбрано)
  useEffect(() => {
    if (!selectedVideoId) return;
    
    const page = pageRef.current;
    const searchContainer = searchContainerRef.current;
    
    if (!page || !searchContainer) return;

    const handleSearchResultsWheel = (e: WheelEvent) => {
      // Проверяем, видна ли секция полностью
      const searchSection = searchContainer.parentElement;
      if (!searchSection) return;
      
      const pageScrollTop = page.scrollTop;
      const pageHeight = page.clientHeight;
      const sectionTop = searchSection.offsetTop;
      const sectionHeight = searchSection.offsetHeight;
      const sectionBottom = sectionTop + sectionHeight;
      const isSectionFullyVisible = pageScrollTop + pageHeight >= sectionBottom;

      // Если секция не видна, блокируем скролл и перенаправляем на страницу
      if (!isSectionFullyVisible) {
        page.scrollTop += e.deltaY;
        e.preventDefault();
        e.stopPropagation();
        return;
      }

      // Находим элемент .search-results внутри SearchPage
      const searchResults = searchContainer.querySelector('.search-results') as HTMLElement;
      if (!searchResults) return;

      // Проверяем, можно ли скроллить результаты
      const resultsScrollTop = searchResults.scrollTop;
      const resultsScrollHeight = searchResults.scrollHeight;
      const resultsClientHeight = searchResults.clientHeight;
      
      // Если скроллим вверх и результаты уже в начале, передаем скролл на страницу
      if (e.deltaY < 0 && resultsScrollTop === 0) {
        page.scrollTop += e.deltaY;
        e.preventDefault();
        e.stopPropagation();
      }
      // Если скроллим вниз и результаты уже в конце, передаем скролл на страницу
      else if (e.deltaY > 0 && resultsScrollTop + resultsClientHeight >= resultsScrollHeight) {
        page.scrollTop += e.deltaY;
        e.preventDefault();
        e.stopPropagation();
      }
    };

    // Функция для добавления обработчика
    const addWheelHandler = () => {
      const searchResults = searchContainer.querySelector('.search-results') as HTMLElement;
      if (searchResults) {
        searchResults.addEventListener('wheel', handleSearchResultsWheel, { passive: false });
        return searchResults;
      }
      return null;
    };

    // Используем MutationObserver для отслеживания изменений в SearchPage
    const observer = new MutationObserver(() => {
      // Переподключаем обработчик при изменении DOM
      const searchResults = searchContainer.querySelector('.search-results') as HTMLElement;
      if (searchResults && !searchResults.hasAttribute('data-wheel-handler')) {
        searchResults.setAttribute('data-wheel-handler', 'true');
        searchResults.addEventListener('wheel', handleSearchResultsWheel, { passive: false });
      }
    });

    // Наблюдаем за изменениями в searchContainer
    observer.observe(searchContainer, {
      childList: true,
      subtree: true,
    });
    
    // Пытаемся добавить обработчик сразу и с небольшой задержкой
    let searchResults = addWheelHandler();
    if (searchResults) {
      searchResults.setAttribute('data-wheel-handler', 'true');
    }
    
    const timeoutId = setTimeout(() => {
      if (!searchResults) {
        searchResults = addWheelHandler();
        if (searchResults) {
          searchResults.setAttribute('data-wheel-handler', 'true');
        }
      }
    }, 100);
    
    return () => {
      clearTimeout(timeoutId);
      observer.disconnect();
      const allResults = searchContainer.querySelectorAll('.search-results[data-wheel-handler]');
      allResults.forEach((el) => {
        el.removeEventListener('wheel', handleSearchResultsWheel as EventListener);
        el.removeAttribute('data-wheel-handler');
      });
    };
  }, [selectedVideoId]);

  return (
    <div ref={pageRef} className={`${styles['player-page']} ${isWideFormat ? styles['wide-format'] : ''}`}>
      <div className={styles['player-section']}>
        <PlayerContent videoId={selectedVideoId} />
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
      <div ref={searchSectionRef} className={styles['search-section']}>
        <div ref={searchContainerRef} className={styles['search-container']}>
          <div data-embedded="true">
            <SearchPage
              onVideoClick={handleVideoClick}
              onAuthorClick={onAuthorClick}
            />
          </div>
        </div>
      </div>
    </div>
  );
}

