'use client';

import { Carousel2 } from '../../src/components/Carousel/Carousel2';
import { PlayerPage } from '../../src/components/PlayerPage/PlayerPage';
import { PlaylistsPage } from '../../src/components/PlaylistsPage/PlaylistsPage';
import { AuthPage } from '../../src/components/AuthPage/AuthPage';

export default function MainPage() {
  const pages = [
    <PlayerPage key="player" />,
    <PlaylistsPage key="playlists" />,
    <AuthPage key="auth" />,
  ];

  return (
    <div style={{ width: '100%', height: '100%', overflow: 'hidden' }}>
      <Carousel2 pages={pages} initialPage={0} />
    </div>
  );
}

