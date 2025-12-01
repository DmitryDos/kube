// src/hooks/__mocks__/useSearch.ts
import { SearchResponse, SearchFilter } from '../../types';
import { Video, Author } from '../../types';

const mockVideos: Video[] = [
  {
    id: '550e8400-e29b-41d4-a716-446655440000',
    title: 'Как настроить Storybook за 5 минут',
    description: 'Полное руководство по настройке Storybook для React проектов с TypeScript и Next.js',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 157286400,
    file_url: 'https://example.com/video.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1611224923853-80b023f02d71?w=400&h=225&fit=crop',
    status: 'published',
    duration: 854,
    is_private: false,
    created_at: '2024-01-15T10:30:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440002',
    title: 'React Hooks: полное руководство',
    description: 'Изучите все хуки React от useState до useReducer',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 200000000,
    file_url: 'https://example.com/video2.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1200,
    is_private: false,
    created_at: '2024-01-20T14:15:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440004',
    title: 'TypeScript для начинающих',
    description: 'Основы TypeScript и типизация в React',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 180000000,
    file_url: 'https://example.com/video3.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=225&fit=crop',
    status: 'published',
    duration: 960,
    is_private: false,
    created_at: '2024-01-25T09:00:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440005',
    title: 'Next.js 14: новые возможности',
    description: 'Обзор новых функций Next.js 14 и App Router',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 220000000,
    file_url: 'https://example.com/video4.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1100,
    is_private: false,
    created_at: '2024-02-01T11:30:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440006',
    title: 'GraphQL vs REST API',
    description: 'Сравнение GraphQL и REST API, когда что использовать',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 190000000,
    file_url: 'https://example.com/video5.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=225&fit=crop',
    status: 'published',
    duration: 980,
    is_private: false,
    created_at: '2024-02-05T15:20:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440007',
    title: 'Docker для разработчиков',
    description: 'Основы Docker, контейнеризация приложений',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 240000000,
    file_url: 'https://example.com/video6.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1605745341112-85968b19335b?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1250,
    is_private: false,
    created_at: '2024-02-10T09:45:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440008',
    title: 'CSS Grid и Flexbox',
    description: 'Современные техники верстки с CSS Grid и Flexbox',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 170000000,
    file_url: 'https://example.com/video7.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=225&fit=crop',
    status: 'published',
    duration: 890,
    is_private: false,
    created_at: '2024-02-15T13:10:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440009',
    title: 'Node.js и Express',
    description: 'Создание серверных приложений на Node.js с Express',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 210000000,
    file_url: 'https://example.com/video8.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1050,
    is_private: false,
    created_at: '2024-02-20T16:30:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440010',
    title: 'Тестирование React приложений',
    description: 'Jest, React Testing Library, unit и integration тесты',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 195000000,
    file_url: 'https://example.com/video9.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=225&fit=crop',
    status: 'published',
    duration: 920,
    is_private: false,
    created_at: '2024-02-25T11:15:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440011',
    title: 'Webpack и Vite',
    description: 'Сборка фронтенд проектов: Webpack vs Vite',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 185000000,
    file_url: 'https://example.com/video10.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=400&h=225&fit=crop',
    status: 'published',
    duration: 950,
    is_private: false,
    created_at: '2024-03-01T14:00:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440012',
    title: 'MongoDB и Mongoose',
    description: 'Работа с MongoDB через Mongoose ODM',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 200000000,
    file_url: 'https://example.com/video11.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1000,
    is_private: false,
    created_at: '2024-03-05T10:25:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440013',
    title: 'Redux Toolkit',
    description: 'Управление состоянием с Redux Toolkit',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 175000000,
    file_url: 'https://example.com/video12.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1611224923853-80b023f02d71?w=400&h=225&fit=crop',
    status: 'published',
    duration: 870,
    is_private: false,
    created_at: '2024-03-10T12:40:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440014',
    title: 'Git и GitHub',
    description: 'Версионирование кода: Git основы и работа с GitHub',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 160000000,
    file_url: 'https://example.com/video13.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=225&fit=crop',
    status: 'published',
    duration: 800,
    is_private: false,
    created_at: '2024-03-15T08:50:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440015',
    title: 'PostgreSQL и Prisma',
    description: 'Работа с PostgreSQL через Prisma ORM',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 230000000,
    file_url: 'https://example.com/video14.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1605745341112-85968b19335b?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1150,
    is_private: false,
    created_at: '2024-03-20T15:55:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440016',
    title: 'AWS и облачные сервисы',
    description: 'Основы работы с AWS: EC2, S3, Lambda',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 250000000,
    file_url: 'https://example.com/video15.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1300,
    is_private: false,
    created_at: '2024-03-25T11:20:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440017',
    title: 'CI/CD с GitHub Actions',
    description: 'Настройка автоматической сборки и деплоя',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 180000000,
    file_url: 'https://example.com/video16.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1618401471353-b98afee0b2eb?w=400&h=225&fit=crop',
    status: 'published',
    duration: 940,
    is_private: false,
    created_at: '2024-03-30T14:35:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440018',
    title: 'WebSocket и реальное время',
    description: 'Создание приложений реального времени с WebSocket',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 205000000,
    file_url: 'https://example.com/video17.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1020,
    is_private: false,
    created_at: '2024-04-05T09:10:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440019',
    title: 'JWT и аутентификация',
    description: 'Реализация JWT токенов для аутентификации',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 165000000,
    file_url: 'https://example.com/video18.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=400&h=225&fit=crop',
    status: 'published',
    duration: 850,
    is_private: false,
    created_at: '2024-04-10T16:45:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440020',
    title: 'Микросервисная архитектура',
    description: 'Проектирование и разработка микросервисов',
    user_id: '550e8400-e29b-41d4-a716-446655440001',
    file_size: 270000000,
    file_url: 'https://example.com/video19.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1400,
    is_private: false,
    created_at: '2024-04-15T12:00:00Z'
  },
  {
    id: '550e8400-e29b-41d4-a716-446655440021',
    title: 'Kubernetes для начинающих',
    description: 'Основы оркестрации контейнеров с Kubernetes',
    user_id: '550e8400-e29b-41d4-a716-446655440003',
    file_size: 290000000,
    file_url: 'https://example.com/video20.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&h=225&fit=crop',
    status: 'published',
    duration: 1500,
    is_private: false,
    created_at: '2024-04-20T10:15:00Z'
  },
];

const mockAuthors: Author[] = [
  {
    id: '1',
    name: 'Иван Иванов',
    title: 'Senior Frontend Developer',
    subtitle: 'Создатель образовательного контента по React и TypeScript',
    avatar_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    videoCount: 42,
    followerCount: 1500
  },
  {
    id: '2',
    name: 'Мария Петрова',
    title: 'Full Stack Developer',
    subtitle: 'Эксперт по Next.js и Node.js',
    avatar_url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop&crop=face',
    videoCount: 28,
    followerCount: 890
  },
];

export function useSearch() {
  const search = async (
    query: string = '',
    page: number = 1,
    limit: number = 20,
    filter: SearchFilter = 'all'
  ): Promise<SearchResponse> => {
    // Имитация задержки
    await new Promise(resolve => setTimeout(resolve, 300));

    let filteredVideos = mockVideos;
    let filteredAuthors = mockAuthors;

    if (query) {
      const lowerQuery = query.toLowerCase();
      filteredVideos = mockVideos.filter(v => 
        v.title.toLowerCase().includes(lowerQuery) ||
        v.description.toLowerCase().includes(lowerQuery)
      );
      filteredAuthors = mockAuthors.filter(a => 
        a.name?.toLowerCase().includes(lowerQuery) ||
        a.title?.toLowerCase().includes(lowerQuery) ||
        a.subtitle?.toLowerCase().includes(lowerQuery)
      );
    }

    const results = [];
    
    if (filter === 'all' || filter === 'videos') {
      results.push(...filteredVideos.map(v => ({ type: 'video' as const, data: v })));
    }
    
    if (filter === 'all' || filter === 'authors') {
      results.push(...filteredAuthors.map(a => ({ type: 'author' as const, data: a })));
    }

    return {
      results: results.slice((page - 1) * limit, page * limit),
      pagination: {
        page,
        limit,
        total: results.length
      }
    };
  };

  return {
    search,
    isLoading: false,
    error: null
  };
}

