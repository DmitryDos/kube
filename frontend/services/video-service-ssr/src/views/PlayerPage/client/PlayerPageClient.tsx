'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useVideo } from '../../../hooks/useVideo';
import { useVideoStream } from '../../../hooks/useVideoStream';
import { useVideoPlayback } from '../../../contexts/VideoPlaybackContext';
import { Video } from '../../../types';
import { Loading } from '../../../components/Loading/Loading';
import { Error } from '../../../components/Error/Error';
import styles from './PlayerPageClient.module.css';

interface PlayerPageClientProps {
  videoId: string;
  videoData?: Video; // Метаданные видео (если уже получены из search)
}

export function PlayerPageClient({ videoId, videoData }: PlayerPageClientProps) {
  const router = useRouter();
  const { getVideo } = useVideo();
  const { getVideoStreamURL } = useVideoStream();
  const { playVideoWithTime } = useVideoPlayback();
  const [video, setVideo] = useState<Video | null>(videoData || null);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const localVideoRef = useRef<HTMLVideoElement | null>(null);

  // Обновляем video если videoData изменился
  useEffect(() => {
    if (videoData) {
      setVideo(videoData);
    }
  }, [videoData]);

  useEffect(() => {
    const loadStreamUrl = async () => {
      if (!videoId) return;

      setIsLoading(true);
      setError(null);

      try {
        // Получаем только stream URL - метаданные должны быть переданы через пропсы
        const streamUrl = await getVideoStreamURL(videoId);
        setVideoUrl(streamUrl);
        
        // Если videoData не передан, делаем fallback запрос (но это должно быть редко)
        if (!video && !videoData) {
          const fetchedVideo = await getVideo(videoId);
          if (!fetchedVideo) {
            setError('Видео не найдено');
            setIsLoading(false);
            return;
          }
          setVideo(fetchedVideo);
        }
      } catch (err) {
        console.error('Error loading video:', err);
        setError('Не удалось загрузить видео');
      } finally {
        setIsLoading(false);
      }
    };

    loadStreamUrl();
  }, [videoId, getVideoStreamURL, getVideo, video, videoData]);

  // Устанавливаем URL для локального видео элемента
  useEffect(() => {
    const localVideo = localVideoRef.current;
    if (!localVideo || !videoUrl) return;

    if (localVideo.src !== videoUrl) {
      localVideo.src = videoUrl;
    }
  }, [videoUrl]);

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  };

  if (isLoading) {
    return (
      <div className={styles['container']}>
        <Loading message="Загрузка видео..." />
      </div>
    );
  }

  if (error || !video) {
    return (
      <div className={styles['container']}>
        <Error
          title="Ошибка загрузки"
          message={error || 'Видео не найдено'}
        />
        <Link href="/search" className={styles['backButton']}>
          Вернуться к поиску
        </Link>
      </div>
    );
  }

  const handleBack = async () => {
    const localVideo = localVideoRef.current;
    if (localVideo && video) {
      try {
        // Получаем текущее время воспроизведения
        const currentTime = localVideo.currentTime;
        // Передаем видео в глобальный плеер с текущим временем и открываем PiP
        await playVideoWithTime(video.id, currentTime, video);
      } catch (error) {
        console.error('Failed to transfer to global player:', error);
      }
    }
    // Используем router.back() вместо push, чтобы не было редиректа
    router.back();
  };

  return (
    <div className={styles['container']}>
      <div className={styles['header']}>
        <button onClick={handleBack} className={styles['backLink']}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M19 12H5M12 19l-7-7 7-7" />
          </svg>
          Назад
        </button>
      </div>

      <div className={styles['playerWrapper']}>
        {videoUrl && (
          <video
            ref={localVideoRef}
            src={videoUrl}
            controls
            autoPlay
            playsInline
            className={styles['video']}
          />
        )}
      </div>

      <div className={styles['info']}>
        <h1 className={styles['title']}>{video.title}</h1>
        
        {video.description && (
          <p className={styles['description']}>{video.description}</p>
        )}

        <div className={styles['meta']}>
          <div className={styles['metaItem']}>
            <span className={styles['metaLabel']}>Дата:</span>
            <span>{formatDate(video.created_at)}</span>
          </div>
          {video.duration > 0 && (
            <div className={styles['metaItem']}>
              <span className={styles['metaLabel']}>Длительность:</span>
              <span>
                {Math.floor(video.duration / 60)}:
                {Math.floor(video.duration % 60)
                  .toString()
                  .padStart(2, '0')}
              </span>
            </div>
          )}
          {video.file_size > 0 && (
            <div className={styles['metaItem']}>
              <span className={styles['metaLabel']}>Размер:</span>
              <span>{formatFileSize(video.file_size)}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

