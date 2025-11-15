// src/components/Player/Player.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Player } from './Player';
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

const meta = {
  title: 'Components/Player',
  component: Player,
  parameters: {
    layout: 'padded',
    backgrounds: {
      default: 'dark',
      values: [
        {
          name: 'dark',
          value: '#000000',
        },
        {
          name: 'light',
          value: '#ffffff',
        },
      ],
    },
  },
  decorators: [
    (Story) => (
      <div style={{ maxWidth: '1000px', margin: '0 auto', padding: '20px' }}>
        <Story />
      </div>
    ),
  ],
  tags: ['autodocs'],
  argTypes: {
    onPlay: { action: 'play' },
    onPause: { action: 'pause' },
    onEnded: { action: 'ended' },
  },
} satisfies Meta<typeof Player>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    video: mockVideo,
    authorName: 'Иван Иванов',
  },
};

export const LongDescription: Story = {
  args: {
    video: {
      ...mockVideo,
      description: 'Это видео с очень длинным описанием. ' + 
        'В этом видео мы рассмотрим множество интересных тем, включая основы программирования, ' +
        'продвинутые техники разработки, лучшие практики и многое другое. ' +
        'Мы пройдем через все этапы создания приложения от начала до конца. ' +
        'Вы узнаете, как правильно структурировать код, как работать с различными библиотеками, ' +
        'как оптимизировать производительность и как писать тесты. ' +
        'Также мы рассмотрим работу с API, обработку ошибок и много других важных аспектов разработки. ' +
        'Это описание намеренно сделано длинным, чтобы продемонстрировать, как компонент обрабатывает большие объемы текста.',
    },
    authorName: 'Мария Петрова',
  },
};

export const ShortDescription: Story = {
  args: {
    video: {
      ...mockVideo,
      description: 'Краткое описание видео.',
    },
    authorName: 'Алексей Сидоров',
  },
};

export const WithoutAuthor: Story = {
  args: {
    video: mockVideo,
  },
};

export const Loading: Story = {
  args: {
    video: null,
    isLoading: true,
    authorName: 'Иван Иванов',
  },
};

export const Error: Story = {
  args: {
    video: null,
    isLoading: false,
    error: 'Не удалось загрузить видео',
    authorName: 'Иван Иванов',
  },
};

