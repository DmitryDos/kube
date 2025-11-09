'use client';

import React, { useEffect, useRef, useState } from 'react';
import { useVideoPlayback } from '../../contexts/VideoPlaybackContext';
import styles from './VideoPlayer.module.css';

interface VideoPlayerProps {
  videoUrl: string;
  title?: string;
  autoPlay?: boolean;
}

const PLAYBACK_RATES = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

const VideoPlayer = React.forwardRef<HTMLVideoElement, VideoPlayerProps>(
  ({ videoUrl, autoPlay = false }, ref) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const videoWrapperRef = useRef<HTMLDivElement>(null);
  const { videoElement, setVideoUrl, requestPip } = useVideoPlayback();
  
  // Устанавливаем URL у скрытого элемента
  useEffect(() => {
    if (videoUrl) {
      setVideoUrl(videoUrl);
    }
  }, [videoUrl, setVideoUrl]);

  // Просто показываем контейнер в модалке - video остается в скрытом контейнере
  useEffect(() => {
    if (!videoElement || !videoWrapperRef.current) return;

    // Если элемент в PIP, скрываем контейнер
    if (document.pictureInPictureElement === videoElement) {
      videoWrapperRef.current.style.display = 'none';
      return;
    }

    // Показываем контейнер - video остается в скрытом контейнере и продолжает играть
    videoWrapperRef.current.style.display = 'block';
    videoWrapperRef.current.style.width = '100%';
    videoWrapperRef.current.style.height = '100%';
    videoWrapperRef.current.style.backgroundColor = '#000';
    videoWrapperRef.current.style.position = 'relative';

    // Sync external ref
    if (typeof ref === 'function') {
      ref(videoElement);
    } else if (ref) {
      ref.current = videoElement;
    }
  }, [videoElement, ref]);
  const [isPlaying, setIsPlaying] = useState(autoPlay);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isPip, setIsPip] = useState(false);
  const [volume, setVolume] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [playbackRate, setPlaybackRate] = useState(1);
  const [showControls, setShowControls] = useState(true);
  const controlsTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!videoElement) return;

    const updateTime = () => setCurrentTime(videoElement.currentTime);
    const updateDuration = () => setDuration(videoElement.duration);
    const handlePlay = () => setIsPlaying(true);
    const handlePause = () => setIsPlaying(false);
    const handleFullscreenChange = () => setIsFullscreen(!!document.fullscreenElement);
    const handleEnterPictureInPicture = () => {
      setIsPip(true);
    };
    const handleLeavePictureInPicture = () => {
      setIsPip(false);
    };
    const handleMouseMove = () => {
      setShowControls(true);
      if (controlsTimeoutRef.current) {
        clearTimeout(controlsTimeoutRef.current);
      }
      if (isPlaying) {
        controlsTimeoutRef.current = setTimeout(() => {
          setShowControls(false);
        }, 3000);
      }
    };

    videoElement.addEventListener('timeupdate', updateTime);
    videoElement.addEventListener('loadedmetadata', updateDuration);
    videoElement.addEventListener('play', handlePlay);
    videoElement.addEventListener('pause', handlePause);
    videoElement.addEventListener('enterpictureinpicture', handleEnterPictureInPicture);
    videoElement.addEventListener('leavepictureinpicture', handleLeavePictureInPicture);
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    document.addEventListener('mousemove', handleMouseMove);

    // Set initial playback rate
    videoElement.playbackRate = playbackRate;

    return () => {
      videoElement.removeEventListener('timeupdate', updateTime);
      videoElement.removeEventListener('loadedmetadata', updateDuration);
      videoElement.removeEventListener('play', handlePlay);
      videoElement.removeEventListener('pause', handlePause);
      videoElement.removeEventListener('enterpictureinpicture', handleEnterPictureInPicture);
      videoElement.removeEventListener('leavepictureinpicture', handleLeavePictureInPicture);
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
      document.removeEventListener('mousemove', handleMouseMove);
      if (controlsTimeoutRef.current) {
        clearTimeout(controlsTimeoutRef.current);
      }
    };
  }, [videoElement, playbackRate, isPlaying]);

  const togglePlay = () => {
    if (!videoElement) return;

    if (isPlaying) {
      videoElement.pause();
    } else {
      videoElement.play();
    }
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!videoElement) return;

    const newTime = parseFloat(e.target.value);
    videoElement.currentTime = newTime;
    setCurrentTime(newTime);
  };

  const toggleFullscreen = async () => {
    const container = containerRef.current;
    if (!container) return;

    try {
      if (!isFullscreen) {
        if (container.requestFullscreen) {
          await container.requestFullscreen();
        }
      } else {
        if (document.exitFullscreen) {
          await document.exitFullscreen();
        }
      }
    } catch (error) {
      console.error('Fullscreen error:', error);
    }
  };

  const togglePictureInPicture = async () => {
    if (!videoElement) return;

    try {
      if (isPip) {
        if (document.pictureInPictureElement) {
          await document.exitPictureInPicture();
        }
      } else {
        await requestPip();
      }
    } catch (error) {
      console.error('Picture-in-Picture error:', error);
    }
  };

  const changePlaybackRate = () => {
    if (!videoElement) return;

    const currentIndex = PLAYBACK_RATES.indexOf(playbackRate);
    const nextIndex = (currentIndex + 1) % PLAYBACK_RATES.length;
    const newRate = PLAYBACK_RATES[nextIndex];
    videoElement.playbackRate = newRate;
    setPlaybackRate(newRate);
  };

  const toggleMute = () => {
    if (!videoElement) return;

    videoElement.muted = !isMuted;
    setIsMuted(!isMuted);
  };

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!videoElement) return;

    const newVolume = parseFloat(e.target.value);
    videoElement.volume = newVolume;
    setVolume(newVolume);
    setIsMuted(newVolume === 0);
  };

  const formatTime = (seconds: number): string => {
    if (isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div 
      ref={containerRef}
      className={styles['playerContainer']}
      onMouseEnter={() => setShowControls(true)}
      onMouseLeave={() => {
        if (isPlaying) {
          setShowControls(false);
        }
      }}
    >
      <div 
        ref={videoWrapperRef}
        className={styles['video']}
      />
      
      <div className={`${styles['controls']} ${!showControls ? styles['controlsHidden'] : ''}`}>
        <div className={styles['progressBar']}>
          <input
            type="range"
            min="0"
            max={duration || 0}
            value={currentTime}
            onChange={handleSeek}
            className={styles['progressSlider']}
          />
        </div>

        <div className={styles['controlsRow']}>
          <div className={styles['controlsLeft']}>
            <button onClick={togglePlay} className={styles['controlButton']} aria-label={isPlaying ? 'Pause' : 'Play'}>
              {isPlaying ? (
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                  <rect x="6" y="4" width="4" height="16" />
                  <rect x="14" y="4" width="4" height="16" />
                </svg>
              ) : (
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                  <polygon points="5 3 19 12 5 21 5 3" />
                </svg>
              )}
            </button>

            <div className={styles['timeDisplay']}>
              {formatTime(currentTime)} / {formatTime(duration)}
            </div>
          </div>

          <div className={styles['controlsRight']}>
            <div className={styles['volumeControl']}>
              <button onClick={toggleMute} className={styles['controlButton']} aria-label={isMuted ? 'Unmute' : 'Mute'}>
                {isMuted || volume === 0 ? (
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z" />
                  </svg>
                ) : volume < 0.5 ? (
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.5 12c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM5 9v6h4l5 5V4L9 9H5z" />
                  </svg>
                ) : (
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z" />
                  </svg>
                )}
              </button>
              <input
                type="range"
                min="0"
                max="1"
                step="0.01"
                value={isMuted ? 0 : volume}
                onChange={handleVolumeChange}
                className={styles['volumeSlider']}
              />
            </div>

            <button 
              onClick={changePlaybackRate} 
              className={styles['controlButton']} 
              aria-label="Playback speed"
              title={`Скорость: ${playbackRate}x`}
            >
              {playbackRate}x
            </button>

            <button 
              onClick={togglePictureInPicture} 
              className={styles['controlButton']} 
              aria-label={isPip ? 'Exit Picture-in-Picture' : 'Enter Picture-in-Picture'}
              disabled={!document.pictureInPictureEnabled}
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M19 7h-8v6h8V7zm0-2c1.1 0 2 .9 2 2v6c0 1.1-.9 2-2 2h-8c-1.1 0-2-.9-2-2V7c0-1.1.9-2 2-2h8zM5 19h14v-2H5V5h14V3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2z" />
              </svg>
            </button>

            <button onClick={toggleFullscreen} className={styles['controlButton']} aria-label="Fullscreen">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                {isFullscreen ? (
                  <path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z" />
                ) : (
                  <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z" />
                )}
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
});

VideoPlayer.displayName = 'VideoPlayer';

export default VideoPlayer;

