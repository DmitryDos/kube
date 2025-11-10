'use client';

import { useState, useEffect, useRef } from 'react';
import { useVideoStream } from '../../hooks/useVideoStream';
import { useVideo } from '../../hooks/useVideo';
import { Video } from '../../types';
import { VideoPlayerControls } from '../../components/VideoPlayerControls/VideoPlayerControls';
import styles from './PlayerBlock.module.css';

interface PlayerBlockProps {
  videoId: string | null;
  isExpanded: boolean;
  onToggle: () => void;
}

export function PlayerBlock({ videoId, isExpanded, onToggle }: PlayerBlockProps) {
  const { getVideoStreamURL } = useVideoStream();
  
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [currentVideo, setCurrentVideo] = useState<Video | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [playbackRate, setPlaybackRate] = useState(1);
  const [localPipActive, setLocalPipActive] = useState(false);
  
  const playerVideoRef = useRef<HTMLVideoElement | null>(null);

  // Track local PiP state
  useEffect(() => {
    const video = playerVideoRef.current;
    if (!video) return;

    const handleEnterPip = () => {
      setLocalPipActive(true);
    };

    const handleLeavePip = () => {
      setLocalPipActive(false);
    };

    video.addEventListener('enterpictureinpicture', handleEnterPip);
    video.addEventListener('leavepictureinpicture', handleLeavePip);

    return () => {
      video.removeEventListener('enterpictureinpicture', handleEnterPip);
      video.removeEventListener('leavepictureinpicture', handleLeavePip);
    };
  }, []);

  // Метаданные видео должны передаваться из результатов search, а не запрашиваться заново
  // Если videoId изменился, нужно только получить stream URL
  useEffect(() => {
    if (!videoId) {
      setVideoUrl(null);
      setCurrentVideo(null);
      return;
    }

    // Получаем только stream URL - метаданные уже есть в результатах search
    const loadStreamUrl = async () => {
      try {
        const streamUrl = await getVideoStreamURL(videoId);
        setVideoUrl(streamUrl);
        // Метаданные должны быть переданы через пропсы или из контекста
        // Если их нет, оставляем null - они придут из search результатов
      } catch (err) {
        console.error('Failed to load stream URL:', err);
      }
    };

    loadStreamUrl();
  }, [videoId, getVideoStreamURL]);

  useEffect(() => {
    const video = playerVideoRef.current;
    if (!video) return;

    const updateTime = () => {
      setCurrentTime(video.currentTime);
    };
    const updateDuration = () => {
      if (video.duration && !isNaN(video.duration)) {
        setDuration(video.duration);
      }
    };
    const handlePlay = () => setIsPlaying(true);
    const handlePause = () => setIsPlaying(false);
    const handlePlaying = () => setIsPlaying(true);
    const handleWaiting = () => setIsPlaying(false);
    const handleVolumeChange = () => {
      setVolume(video.volume);
      setIsMuted(video.muted);
    };
    const handleRateChange = () => {
      setPlaybackRate(video.playbackRate);
    };

    // Initialize state from video element
    setIsPlaying(!video.paused);
    setCurrentTime(video.currentTime || 0);
    if (video.duration && !isNaN(video.duration)) {
      setDuration(video.duration);
    }
    setVolume(video.volume);
    setIsMuted(video.muted);
    setPlaybackRate(video.playbackRate);

    // Add event listeners
    video.addEventListener('timeupdate', updateTime);
    video.addEventListener('loadedmetadata', updateDuration);
    video.addEventListener('durationchange', updateDuration);
    video.addEventListener('play', handlePlay);
    video.addEventListener('playing', handlePlaying);
    video.addEventListener('pause', handlePause);
    video.addEventListener('waiting', handleWaiting);
    video.addEventListener('volumechange', handleVolumeChange);
    video.addEventListener('ratechange', handleRateChange);

    return () => {
      video.removeEventListener('timeupdate', updateTime);
      video.removeEventListener('loadedmetadata', updateDuration);
      video.removeEventListener('durationchange', updateDuration);
      video.removeEventListener('play', handlePlay);
      video.removeEventListener('playing', handlePlaying);
      video.removeEventListener('pause', handlePause);
      video.removeEventListener('waiting', handleWaiting);
      video.removeEventListener('volumechange', handleVolumeChange);
      video.removeEventListener('ratechange', handleRateChange);
    };
  }, [videoUrl]);

  useEffect(() => {
    const video = playerVideoRef.current;
    if (!video || !videoUrl) return;
    if (video.src !== videoUrl) {
      video.src = videoUrl;
      video.load();
      setCurrentTime(0);
      setIsPlaying(false);
    }
  }, [videoUrl]);

  const handlePlayerToggle = async () => {
    const video = playerVideoRef.current;
    if (isExpanded) {
      if (video && !video.paused) {
        try {
          if (document.pictureInPictureEnabled && video) {
            await video.requestPictureInPicture();
          }
        } catch (err) {
          console.error('Failed to enter PIP:', err);
        }
      }
    } else {
      if (localPipActive && document.pictureInPictureElement === video) {
        try {
          await document.exitPictureInPicture();
        } catch (err) {
          console.error('Failed to exit PIP:', err);
        }
      }
    }
    onToggle();
  };

  if (!videoId || !videoUrl) {
    return null;
  }

  return (
    <div className={`${styles['playerContainer']} ${isExpanded ? styles['expanded'] : styles['collapsed']}`}>
      <button className={styles['toggleButton']} onClick={handlePlayerToggle}>
        {isExpanded ? (
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
        <video ref={playerVideoRef} playsInline className={styles['video']} />
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
            if (video.paused) video.play().catch(console.error);
            else video.pause();
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
          onPictureInPicture={async () => {
            const video = playerVideoRef.current;
            if (!video) return;
            try {
              if (document.pictureInPictureElement === video) {
                await document.exitPictureInPicture();
              } else {
                await video.requestPictureInPicture();
              }
            } catch (err) {
              console.error('Failed to toggle PIP:', err);
            }
          }}
          isPipActive={localPipActive}
          showFullscreen={false}
          showPip={true}
        />
      </div>
      {currentVideo && (
        <div className={styles['videoInfo']}>
          <h3 className={styles['videoTitle']}>{currentVideo.title}</h3>
        </div>
      )}
    </div>
  );
}

