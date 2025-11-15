// src/components/PlaylistSection/PlaylistSection.tsx
'use client';

import { useState, useRef, useCallback, useEffect } from 'react';
import { Playlist, Video } from '../../types';
import { SearchResults } from '../SearchResults/SearchResults';
import { VideoCard } from '../VideoCard/VideoCard';
import { useSearch } from '../../hooks/useSearch';
import styles from './PlaylistSection.module.css';

interface PlaylistSectionProps {
  playlist: Playlist;
  isEditing?: boolean;
  searchQuery?: string;
  onPlaylistLongPress?: (playlistId: string) => void;
  onVideoClick?: (video: Video) => void;
  onVideoLongPress?: (video: Video) => void;
}

export function PlaylistSection({
  playlist,
  isEditing = false,
  searchQuery = '',
  onPlaylistLongPress,
  onVideoClick,
  onVideoLongPress,
}: PlaylistSectionProps) {
  const [videos, setVideos] = useState<Video[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const { search } = useSearch();
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let cancelled = false;
    
    const loadVideos = async () => {
      if (playlist.videoIds.length === 0) {
        if (!cancelled) {
          setVideos([]);
          setIsLoading(false);
        }
        return;
      }

      if (!cancelled) {
        setIsLoading(true);
      }
      
      try {
        // Загружаем видео по ID из плейлиста
        // Пока используем поиск для получения видео
        const response = await search('', 1, 100, 'videos');
        const allVideos = response.results
          .filter((item) => item.type === 'video')
          .map((item) => item.data);
        
        // Фильтруем только те видео, которые есть в плейлисте
        const results = playlist.videoIds
          .map((videoId) => allVideos.find((v) => v.id === videoId))
          .filter((v): v is Video => v !== undefined);
        
        if (!cancelled) {
          setVideos(results);
          setIsLoading(false);
        }
      } catch (error) {
        console.error('Error loading videos:', error);
        if (!cancelled) {
          setVideos([]);
          setIsLoading(false);
        }
      }
    };

    // Загружаем только если видео еще не загружены или изменились ID
    const currentVideoIds = videos.map(v => v.id).sort().join(',');
    const playlistVideoIds = [...playlist.videoIds].sort().join(',');
    
    if (currentVideoIds !== playlistVideoIds || videos.length === 0) {
      loadVideos();
    }

    return () => {
      cancelled = true;
    };
  }, [playlist.videoIds]); // eslint-disable-line react-hooks/exhaustive-deps

  const filteredVideos = videos.filter((video) => {
    if (!searchQuery.trim()) return true;
    const query = searchQuery.toLowerCase();
    return (
      video.title.toLowerCase().includes(query) ||
      video.description.toLowerCase().includes(query)
    );
  });


  const handleLongPress = useCallback(() => {
    if (!playlist.isSystem && !isEditing) {
      onPlaylistLongPress?.(playlist.id);
    }
  }, [playlist.isSystem, playlist.id, isEditing, onPlaylistLongPress]);

  return (
    <div
      ref={sectionRef}
      className={styles['playlist-section']}
    >
      <div className={styles['playlist-header']}>
        <h2 className={styles['playlist-title']}>{playlist.name}</h2>
        {!playlist.isSystem && (
          <button
            className={styles['edit-button']}
            onClick={handleLongPress}
            aria-label="Редактировать"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
            </svg>
          </button>
        )}
        {playlist.isSystem && (
          <svg
            className={styles['lock-icon']}
            width="12"
            height="12"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
        )}
      </div>

      <div className={styles['playlist-content']}>
        <SearchResults
          isLoading={isLoading}
          isEmpty={!isLoading && filteredVideos.length === 0}
          emptyMessage={searchQuery ? 'Ничего не найдено' : 'Плейлист пуст'}
          columns={2}
          gap={12}
        >
          {filteredVideos.map((video) => (
            <div key={video.id} className={styles['video-wrapper']}>
              {onVideoLongPress && (
                <button
                  className={styles['video-edit-button']}
                  onClick={(e) => {
                    e.stopPropagation();
                    onVideoLongPress(video);
                  }}
                  aria-label="Редактировать видео"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                  </svg>
                </button>
              )}
              <VideoCard
                video={video}
                onClick={onVideoClick}
              />
            </div>
          ))}
        </SearchResults>
      </div>
    </div>
  );
}

