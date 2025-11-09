'use client';

import { useState, useEffect, useRef } from 'react';
import styles from './VideoPlayerControls.module.css';

const PLAYBACK_RATES = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

interface VideoPlayerControlsProps {
  videoElement: HTMLVideoElement | null;
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  volume: number;
  isMuted: boolean;
  playbackRate: number;
  onPlayPause: () => void;
  onSeek: (time: number) => void;
  onVolumeChange: (volume: number) => void;
  onMuteToggle: () => void;
  onPlaybackRateChange: (rate: number) => void;
  onSkipForward: () => void;
  onSkipBackward: () => void;
  onFullscreen?: () => void;
  onPictureInPicture?: () => void;
  isPipActive?: boolean;
  showFullscreen?: boolean;
  showPip?: boolean;
}

export function VideoPlayerControls({
  videoElement,
  isPlaying,
  currentTime,
  duration,
  volume,
  isMuted,
  playbackRate,
  onPlayPause,
  onSeek,
  onVolumeChange,
  onMuteToggle,
  onPlaybackRateChange,
  onSkipForward,
  onSkipBackward,
  onFullscreen,
  onPictureInPicture,
  isPipActive = false,
  showFullscreen = true,
  showPip = true,
}: VideoPlayerControlsProps) {
  const [showControls, setShowControls] = useState(true);
  const controlsTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!videoElement) return;

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

    const handleMouseLeave = () => {
      if (isPlaying) {
        controlsTimeoutRef.current = setTimeout(() => {
          setShowControls(false);
        }, 3000);
      }
    };

    document.addEventListener('mousemove', handleMouseMove);
    if (videoElement) {
      videoElement.addEventListener('mouseleave', handleMouseLeave);
    }

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      if (videoElement) {
        videoElement.removeEventListener('mouseleave', handleMouseLeave);
      }
      if (controlsTimeoutRef.current) {
        clearTimeout(controlsTimeoutRef.current);
      }
    };
  }, [videoElement, isPlaying]);

  const formatTime = (seconds: number): string => {
    if (isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newTime = parseFloat(e.target.value);
    if (!isNaN(newTime) && isFinite(newTime)) {
      onSeek(newTime);
    }
  };

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newVolume = parseFloat(e.target.value);
    onVolumeChange(newVolume);
  };

  const changePlaybackRate = () => {
    const currentIndex = PLAYBACK_RATES.indexOf(playbackRate);
    const nextIndex = (currentIndex + 1) % PLAYBACK_RATES.length;
    onPlaybackRateChange(PLAYBACK_RATES[nextIndex]);
  };

  return (
    <div className={`${styles['controls']} ${!showControls ? styles['controlsHidden'] : ''}`}>
      <div className={styles['progressBar']}>
        <input
          type="range"
          min="0"
          max={duration && !isNaN(duration) ? duration : 0}
          value={currentTime && !isNaN(currentTime) ? currentTime : 0}
          onChange={handleSeek}
          className={styles['progressSlider']}
          step="0.1"
        />
      </div>

      <div className={styles['controlsRow']}>
        <div className={styles['controlsLeft']}>
          <button onClick={onPlayPause} className={styles['controlButton']} aria-label={isPlaying ? 'Pause' : 'Play'}>
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

          <button onClick={onSkipBackward} className={styles['controlButton']} aria-label="Skip backward 10s">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8z" />
            </svg>
          </button>

          <button onClick={onSkipForward} className={styles['controlButton']} aria-label="Skip forward 10s">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 5V1l5 5-5 5V7c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6h2c0 4.42-3.58 8-8 8s-8-3.58-8-8 3.58-8 8-8z" />
            </svg>
          </button>

          <div className={styles['timeDisplay']}>
            {formatTime(currentTime)} / {formatTime(duration)}
          </div>
        </div>

        <div className={styles['controlsRight']}>
          <div className={styles['volumeControl']}>
            <button onClick={onMuteToggle} className={styles['controlButton']} aria-label={isMuted ? 'Unmute' : 'Mute'}>
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

          {showPip && (
            <button
              onClick={onPictureInPicture}
              className={styles['controlButton']}
              aria-label={isPipActive ? 'Exit Picture-in-Picture' : 'Enter Picture-in-Picture'}
              disabled={!document.pictureInPictureEnabled}
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M19 7h-8v6h8V7zm0-2c1.1 0 2 .9 2 2v6c0 1.1-.9 2-2 2h-8c-1.1 0-2-.9-2-2V7c0-1.1.9-2 2-2h8zM5 19h14v-2H5v2zm14-6H5V5h14v8z" />
              </svg>
            </button>
          )}

          {showFullscreen && onFullscreen && (
            <button onClick={onFullscreen} className={styles['controlButton']} aria-label="Fullscreen">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z" />
              </svg>
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

