'use client';

import { createContext, useContext, ReactNode, useCallback, useRef, useState, useEffect } from 'react';
import { Video } from '../types';

interface VideoPlaybackContextType {
  videoElement: HTMLVideoElement | null;
  setVideoElement: (element: HTMLVideoElement | null) => void;
  setVideoUrl: (url: string) => void;
  requestPip: () => Promise<void>;
  openVideoModal: (videoId: string, videoData?: Video) => void;
  closeVideoModal: () => void;
  playVideo: (videoId: string, videoData?: Video) => void;
  playVideoWithTime: (videoId: string, currentTime: number, videoData?: Video) => Promise<void>;
  onVideoClick?: (video: Video) => void;
  setOnVideoClick?: (handler: ((video: Video) => void) | undefined) => void;
  isVideoModalOpen: boolean;
  currentVideoId: string | null;
  currentVideoData: Video | null;
  isPipActive: boolean;
  hasActiveVideo: boolean;
}

const VideoPlaybackContext = createContext<VideoPlaybackContextType | null>(null);

export function VideoPlaybackProvider({ children }: { children: ReactNode }) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const [isVideoModalOpen, setIsVideoModalOpen] = useState(false);
  const [currentVideoId, setCurrentVideoId] = useState<string | null>(null);
  const [currentVideoData, setCurrentVideoData] = useState<Video | null>(null);
  const [isPipActive, setIsPipActive] = useState(false);
  const [onVideoClick, setOnVideoClick] = useState<((video: Video) => void) | undefined>(undefined);

  const setVideoElement = useCallback((element: HTMLVideoElement | null) => {
    videoRef.current = element;
  }, []);

  const setVideoUrl = useCallback((url: string) => {
    const video = videoRef.current;
    if (!video || video.src === url) return;
    video.src = url;
  }, []);

  const requestPip = useCallback(async () => {
    const video = videoRef.current;
    if (!video) return;
    await video.requestPictureInPicture().catch(() => {});
  }, []);

  const openVideoModal = useCallback((videoId: string, videoData?: Video) => {
    setCurrentVideoId(videoId);
    setCurrentVideoData(videoData || null);
    setIsVideoModalOpen(true);
  }, []);

  const closeVideoModal = useCallback(async () => {
    const video = videoRef.current;
    if (video && !video.paused && document.pictureInPictureEnabled) {
      await video.requestPictureInPicture().catch(() => {});
    }
    setIsVideoModalOpen(false);
  }, []);

  // Отслеживаем состояние PIP
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const handleEnterPip = () => {
      setIsPipActive(true);
    };

    const handleLeavePip = () => {
      setIsPipActive(false);
      // Если PIP закрыт, очищаем состояние (глобальный плеер закроется)
      setCurrentVideoId(null);
      setCurrentVideoData(null);
    };

    video.addEventListener('enterpictureinpicture', handleEnterPip);
    video.addEventListener('leavepictureinpicture', handleLeavePip);

    return () => {
      video.removeEventListener('enterpictureinpicture', handleEnterPip);
      video.removeEventListener('leavepictureinpicture', handleLeavePip);
    };
  }, [currentVideoId]);

  const playVideo = useCallback((videoId: string, videoData?: Video) => {
    const video = videoRef.current;
    if (!video) {
      console.error('Video element not found');
      return;
    }

    setCurrentVideoId(videoId);
    setCurrentVideoData(videoData || null);
    
    // Проверяем, активен ли PIP ДО переключения видео
    const pipActive = !!document.pictureInPictureElement;
    
    // Формируем URL синхронно
    const videoUrl = `/api/proxy/videos/${videoId}/stream/proxy`;
    
    // Устанавливаем src (как в Swift: replaceCurrentItem)
    const currentSrc = video.src ? video.src.split('?')[0] : '';
    const newSrc = videoUrl.split('?')[0];
    
    if (currentSrc !== newSrc) {
      video.src = videoUrl;
    }
    
    // Если видео уже готово - сразу запускаем
    if (video.readyState >= 3 && video.src === videoUrl) {
      video.play().then(() => {
        // Если PIP был активен, переводим новое видео в PIP
        if (pipActive) {
          setTimeout(() => {
            video.requestPictureInPicture().catch((err) => {
              console.error('Failed to enter PIP:', err);
            });
          }, 100);
        }
      }).catch((err) => {
        console.error('Failed to play video:', err);
      });
      return;
    }
    
    // Ждем готовности к воспроизведению и запускаем
    const checkReady = () => {
      if (video.readyState >= 3) {
        video.removeEventListener('canplay', checkReady);
        video.removeEventListener('canplaythrough', checkReady);
        video.play().then(() => {
          // Если PIP был активен, переводим новое видео в PIP
          if (pipActive) {
            setTimeout(() => {
              video.requestPictureInPicture().catch((err) => {
                console.error('Failed to enter PIP:', err);
              });
            }, 100);
          }
        }).catch((err) => {
          console.error('Failed to play video:', err);
        });
      }
    };
    
    video.addEventListener('canplay', checkReady);
    video.addEventListener('canplaythrough', checkReady);
    setTimeout(() => {
      video.removeEventListener('canplay', checkReady);
      video.removeEventListener('canplaythrough', checkReady);
      if (video.readyState >= 3) {
        video.play().then(() => {
          // Если PIP был активен, переводим новое видео в PIP
          if (pipActive) {
            setTimeout(() => {
              video.requestPictureInPicture().catch((err) => {
                console.error('Failed to enter PIP:', err);
              });
            }, 100);
          }
        }).catch((err) => {
          console.error('Failed to play video:', err);
        });
      }
    }, 3000);
  }, []);

  const playVideoWithTime = useCallback(async (videoId: string, currentTime: number, videoData?: Video) => {
    const video = videoRef.current;
    if (!video) {
      console.error('Video element not found');
      return;
    }

    setCurrentVideoId(videoId);
    setCurrentVideoData(videoData || null);
    
    // Формируем URL синхронно
    const videoUrl = `/api/proxy/videos/${videoId}/stream/proxy`;
    
    // Устанавливаем src
    const currentSrc = video.src ? video.src.split('?')[0] : '';
    const newSrc = videoUrl.split('?')[0];
    
    if (currentSrc !== newSrc) {
      video.src = videoUrl;
    }
    
    // Ждем готовности к воспроизведению
    const waitForReady = (): Promise<void> => {
      return new Promise((resolve) => {
        if (video.readyState >= 3) {
          resolve();
          return;
        }
        
        const checkReady = () => {
          if (video.readyState >= 3) {
            video.removeEventListener('canplay', checkReady);
            video.removeEventListener('canplaythrough', checkReady);
            video.removeEventListener('loadedmetadata', checkReady);
            resolve();
          }
        };
        
        video.addEventListener('canplay', checkReady);
        video.addEventListener('canplaythrough', checkReady);
        video.addEventListener('loadedmetadata', checkReady);
        
        // Fallback timeout
        setTimeout(() => {
          video.removeEventListener('canplay', checkReady);
          video.removeEventListener('canplaythrough', checkReady);
          video.removeEventListener('loadedmetadata', checkReady);
          if (video.readyState >= 3) {
            resolve();
          }
        }, 3000);
      });
    };
    
    await waitForReady();
    
    // Устанавливаем время воспроизведения и ждем завершения перемотки
    const seekToTime = (): Promise<void> => {
      return new Promise((resolve) => {
        if (Math.abs(video.currentTime - currentTime) < 0.1) {
          resolve();
          return;
        }
        
        const handleSeeked = () => {
          video.removeEventListener('seeked', handleSeeked);
          resolve();
        };
        
        video.addEventListener('seeked', handleSeeked);
        video.currentTime = currentTime;
        
        // Fallback timeout
        setTimeout(() => {
          video.removeEventListener('seeked', handleSeeked);
          resolve();
        }, 2000);
      });
    };
    
    await seekToTime();
    
    // Делаем video элемент видимым для PiP (PiP требует видимый элемент)
    const originalVisibility = video.style.visibility;
    const originalOpacity = video.style.opacity;
    const originalWidth = video.style.width;
    const originalHeight = video.style.height;
    const originalPosition = video.style.position;
    
    video.style.visibility = 'visible';
    video.style.opacity = '1';
    video.style.width = '320px';
    video.style.height = '180px';
    video.style.position = 'fixed';
    video.style.top = '10px';
    video.style.right = '10px';
    video.style.zIndex = '9999';
    
    // Запускаем воспроизведение
    await video.play().catch((err) => {
      console.error('Failed to play video:', err);
    });
    
    // Открываем PiP - важно сделать это ДО закрытия страницы
    if (document.pictureInPictureEnabled) {
      try {
        await video.requestPictureInPicture();
        // После открытия PiP можно вернуть стили (PiP использует свой рендер)
        video.style.visibility = originalVisibility;
        video.style.opacity = originalOpacity;
        video.style.width = originalWidth;
        video.style.height = originalHeight;
        video.style.position = originalPosition;
      } catch (err) {
        console.error('Failed to enter PIP:', err);
        // Восстанавливаем стили в случае ошибки
        video.style.visibility = originalVisibility;
        video.style.opacity = originalOpacity;
        video.style.width = originalWidth;
        video.style.height = originalHeight;
        video.style.position = originalPosition;
      }
    } else {
      // Восстанавливаем стили, если PiP не поддерживается
      video.style.visibility = originalVisibility;
      video.style.opacity = originalOpacity;
      video.style.width = originalWidth;
      video.style.height = originalHeight;
      video.style.position = originalPosition;
    }
  }, []);

  const setOnVideoClickHandler = useCallback((handler: ((video: Video) => void) | undefined) => {
    setOnVideoClick(() => handler);
  }, []);

  return (
    <VideoPlaybackContext.Provider
      value={{
        videoElement: videoRef.current,
        setVideoElement,
        setVideoUrl,
        requestPip,
        openVideoModal,
        closeVideoModal,
        playVideo,
        playVideoWithTime,
        onVideoClick,
        setOnVideoClick: setOnVideoClickHandler,
        isVideoModalOpen,
        currentVideoId,
        currentVideoData,
        isPipActive,
        hasActiveVideo: !!currentVideoId,
      }}
    >
      {children}
    </VideoPlaybackContext.Provider>
  );
}

export function useVideoPlayback() {
  const context = useContext(VideoPlaybackContext);
  if (!context) {
    throw new Error('useVideoPlayback must be used within VideoPlaybackProvider');
  }
  return context;
}

