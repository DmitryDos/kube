// src/components/PlaylistsPage/PlaylistsPage.tsx
'use client';

import { useState, useCallback, useEffect } from 'react';
import { SearchBar } from '../SearchBar/SearchBar';
import { PlaylistSection } from '../PlaylistSection/PlaylistSection';
import { PlaylistsSidebar } from '../PlaylistsSidebar/PlaylistsSidebar';
import { useModal } from '../Modal/ModalProvider';
import { EditPlaylistModal } from '../EditPlaylistModal/EditPlaylistModal';
import { EditVideoModal } from '../EditVideoModal/EditVideoModal';
import { Playlist, Video } from '../../types';
import styles from './PlaylistsPage.module.css';

interface PlaylistsPageProps {
  onVideoClick?: (video: Video) => void;
}

export function PlaylistsPage({ onVideoClick }: PlaylistsPageProps) {
  const [playlists, setPlaylists] = useState<Playlist[]>([]);
  const [selectedPlaylistId, setSelectedPlaylistId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [editingPlaylistId, setEditingPlaylistId] = useState<string | null>(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isDesktop, setIsDesktop] = useState(false);
  const { show } = useModal();

  // Устанавливаем "Избранное" по умолчанию при загрузке
  useEffect(() => {
    if (!selectedPlaylistId && playlists.length > 0) {
      const favoritePlaylist = playlists.find(p => p.name === 'Избранное' || p.isSystem) || playlists[0];
      if (favoritePlaylist) {
        setSelectedPlaylistId(favoritePlaylist.id);
      }
    }
  }, [playlists, selectedPlaylistId]);

  useEffect(() => {
    const checkDesktop = () => {
      setIsDesktop(window.innerWidth >= 1064);
    };
    
    checkDesktop();
    window.addEventListener('resize', checkDesktop);
    return () => window.removeEventListener('resize', checkDesktop);
  }, []);

  // На десктопе sidebar всегда открыт
  const sidebarIsOpen = isDesktop || isSidebarOpen;

  const handleSearchChange = useCallback((value: string) => {
    setSearchQuery(value);
  }, []);

  const handlePlaylistSelect = useCallback((playlistId: string) => {
    setSelectedPlaylistId(playlistId);
  }, []);

  const handlePlaylistLongPress = useCallback((playlistId: string) => {
    const playlist = playlists.find(p => p.id === playlistId);
    if (!playlist || playlist.isSystem) return;
    
    setEditingPlaylistId(playlistId);
    
    show(
      <EditPlaylistModal
        playlist={playlist}
        onSave={(name, videoIds) => {
          setPlaylists(prev => prev.map(p => 
            p.id === playlistId 
              ? { ...p, name, videoIds }
              : p
          ));
          setEditingPlaylistId(null);
        }}
        onDelete={() => {
          setPlaylists(prev => prev.filter(p => p.id !== playlistId));
          setEditingPlaylistId(null);
        }}
      />,
      () => {
        // Сбрасываем editingPlaylistId при закрытии модалки
        setEditingPlaylistId(null);
      }
    );
  }, [playlists, show]);

  const handleVideoLongPress = useCallback((video: Video) => {
    show(<EditVideoModal video={video} />);
  }, [show]);

  const handleAddPlaylist = useCallback(() => {
    const newPlaylist: Playlist = {
      id: `playlist-${Date.now()}`,
      name: 'Новый плейлист',
      isSystem: false,
      videoIds: [],
      order: playlists.length,
    };
    setPlaylists(prev => [...prev, newPlaylist]);
    setEditingPlaylistId(newPlaylist.id);
    
    show(
      <EditPlaylistModal
        playlist={newPlaylist}
        onSave={(name, videoIds) => {
          setPlaylists(prev => prev.map(p => 
            p.id === newPlaylist.id 
              ? { ...p, name, videoIds }
              : p
          ));
          setEditingPlaylistId(null);
        }}
        onDelete={() => {
          setPlaylists(prev => prev.filter(p => p.id !== newPlaylist.id));
          setEditingPlaylistId(null);
        }}
      />,
      () => {
        // Сбрасываем editingPlaylistId при закрытии модалки
        setEditingPlaylistId(null);
      }
    );
  }, [playlists, show]);

  const selectedPlaylist = selectedPlaylistId 
    ? playlists.find(p => p.id === selectedPlaylistId)
    : null;

  return (
    <div className={styles['playlists-page']}>
      <div className={styles['playlists-container']}>
        <PlaylistsSidebar
          playlists={playlists}
          selectedPlaylistId={selectedPlaylistId}
          onPlaylistSelect={handlePlaylistSelect}
          onAddPlaylist={handleAddPlaylist}
          isOpen={sidebarIsOpen}
          onClose={() => !isDesktop && setIsSidebarOpen(false)}
        />
        
        <div className={styles['playlists-main']}>
          <div className={styles['playlists-header']}>
            <button
              className={styles['menu-button']}
              onClick={() => setIsSidebarOpen(true)}
              aria-label="Открыть меню"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M3 12h18M3 6h18M3 18h18" />
              </svg>
            </button>
            <div className={styles['search-wrapper']}>
              <SearchBar
                value={searchQuery}
                onChange={handleSearchChange}
                placeholder="Поиск видео"
              />
            </div>
          </div>
          
          <div className={styles['playlists-content']}>
            {selectedPlaylist && (
              <PlaylistSection
                playlist={selectedPlaylist}
                isEditing={editingPlaylistId === selectedPlaylist.id}
                searchQuery={searchQuery}
                onPlaylistLongPress={handlePlaylistLongPress}
                onVideoClick={onVideoClick}
                onVideoLongPress={handleVideoLongPress}
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

