'use client';

import { createContext, useContext, ReactNode, useState, useCallback } from 'react';
import { Video } from '../types';

interface PictureInPictureState {
  video: Video | null;
  videoUrl: string | null;
  isActive: boolean;
}

interface PictureInPictureContextType {
  pipState: PictureInPictureState;
  openPip: (video: Video, videoUrl: string) => void;
  closePip: () => void;
  expandPip: () => void;
}

const PictureInPictureContext = createContext<PictureInPictureContextType | null>(null);

export function PictureInPictureProvider({ children }: { children: ReactNode }) {
  const [pipState, setPipState] = useState<PictureInPictureState>({
    video: null,
    videoUrl: null,
    isActive: false,
  });

  const openPip = useCallback((video: Video, videoUrl: string) => {
    setPipState({
      video,
      videoUrl,
      isActive: true,
    });
  }, []);

  const closePip = useCallback(() => {
    setPipState({
      video: null,
      videoUrl: null,
      isActive: false,
    });
  }, []);

  const expandPip = useCallback(() => {
    if (pipState.video) {
      window.location.href = `/player/${pipState.video.id}`;
    }
    closePip();
  }, [pipState.video, closePip]);

  return (
    <PictureInPictureContext.Provider value={{ pipState, openPip, closePip, expandPip }}>
      {children}
    </PictureInPictureContext.Provider>
  );
}

export function usePictureInPicture() {
  const context = useContext(PictureInPictureContext);
  if (!context) {
    throw new Error('usePictureInPicture must be used within PictureInPictureProvider');
  }
  return context;
}

