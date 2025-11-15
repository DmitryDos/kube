// src/components/PlaylistsSidebar/PlaylistsSidebar.tsx
'use client';

import { useState, useCallback } from 'react';
import { SearchBar } from '../SearchBar/SearchBar';
import { Playlist } from '../../types';
import styles from './PlaylistsSidebar.module.css';

interface PlaylistsSidebarProps {
  playlists: Playlist[];
  selectedPlaylistId: string | null;
  onPlaylistSelect: (playlistId: string) => void;
  onAddPlaylist: () => void;
  isOpen?: boolean;
  onClose?: () => void;
}

export function PlaylistsSidebar({
  playlists,
  selectedPlaylistId,
  onPlaylistSelect,
  onAddPlaylist,
  isOpen = true,
  onClose,
}: PlaylistsSidebarProps) {
  const [sidebarSearchQuery, setSidebarSearchQuery] = useState('');

  const filteredPlaylists = playlists.filter(playlist => {
    if (sidebarSearchQuery.trim() === '') return true;
    const query = sidebarSearchQuery.toLowerCase();
    return playlist.name.toLowerCase().includes(query);
  }).sort((a, b) => (a.order || 0) - (b.order || 0));

  const handlePlaylistClick = useCallback((playlistId: string) => {
    onPlaylistSelect(playlistId);
    onClose?.();
  }, [onPlaylistSelect, onClose]);

  return (
    <>
      <div className={`${styles['sidebar-overlay']} ${isOpen ? styles['overlay-open'] : ''}`} onClick={onClose} />
      <div className={`${styles['sidebar']} ${isOpen ? styles['sidebar-open'] : ''}`}>
        <div className={styles['sidebar-header']}>
          <div className={styles['search-container']}>
            <SearchBar
              value={sidebarSearchQuery}
              onChange={setSidebarSearchQuery}
              onClear={() => setSidebarSearchQuery('')}
              placeholder="Поиск плейлистов"
            />
          </div>
          {onClose && (
            <button
              className={styles['close-button']}
              onClick={onClose}
              aria-label="Закрыть"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M18 6L6 18M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
        <div className={styles['sidebar-content']}>
          <button
            className={styles['add-playlist-button']}
            onClick={onAddPlaylist}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 5v14M5 12h14" />
            </svg>
            <span>Добавить плейлист</span>
          </button>
          <div className={styles['playlists-list']}>
            {filteredPlaylists.map((playlist) => (
              <button
                key={playlist.id}
                className={`${styles['playlist-item']} ${selectedPlaylistId === playlist.id ? styles['selected'] : ''}`}
                onClick={() => handlePlaylistClick(playlist.id)}
              >
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
                <span className={styles['playlist-name']}>{playlist.name}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}

