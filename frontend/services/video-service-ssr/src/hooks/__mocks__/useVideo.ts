// src/hooks/__mocks__/useVideo.ts
import { Video } from '../../types';

const mockVideo: Video = {
  id: '550e8400-e29b-41d4-a716-446655440000',
  title: 'Как настроить Storybook за 5 минут',
  description: 'Полное руководство по настройке Storybook для React проектов с TypeScript и Next.js. В этом видео мы рассмотрим все основные возможности Storybook, включая создание компонентов, настройку окружения, работу с пропсами и состояниями, а также интеграцию с различными инструментами разработки. Вы узнаете, как эффективно использовать Storybook для разработки и тестирования UI компонентов.',
  user_id: '550e8400-e29b-41d4-a716-446655440001',
  file_size: 157286400,
  file_url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  thumbnail_url: 'https://images.unsplash.com/photo-1611224923853-80b023f02d71?w=400&h=225&fit=crop',
  status: 'published',
  duration: 854,
  is_private: false,
  created_at: '2024-01-15T10:30:00Z'
};

export function useVideo() {
  const getVideo = async (videoId: string): Promise<Video | null> => {
    // Имитация задержки
    await new Promise(resolve => setTimeout(resolve, 300));
    
    // Возвращаем моковое видео для любого ID
    return mockVideo;
  };

  return {
    getVideo,
    isLoading: false,
    error: null
  };
}

