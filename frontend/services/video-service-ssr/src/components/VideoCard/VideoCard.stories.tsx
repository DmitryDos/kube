// src/components/VideoCard/VideoCard.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { VideoCard } from './VideoCard';
import { Video } from '../../types';

const mockVideo: Video = {
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
};

const meta = {
  title: 'Components/VideoCard',
  component: VideoCard,
  parameters: {
    layout: 'padded',
  },
  decorators: [
    (Story) => (
      <div style={{ maxWidth: '100%' }}>
        <Story />
      </div>
    ),
  ],
  tags: ['autodocs'],
  argTypes: {
    onClick: { action: 'clicked' },
  },
} satisfies Meta<typeof VideoCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    video: mockVideo,
    authorName: 'Иван Иванов',
  },
  decorators: [
    (Story) => (
      <div style={{ width: '100%', maxWidth: '400px' }}>
        <Story />
      </div>
    ),
  ],
};

export const WithoutThumbnail: Story = {
  args: {
    video: {
      ...mockVideo,
      thumbnail_url: undefined,
    },
    authorName: 'Иван Иванов',
  },
  decorators: [
    (Story) => (
      <div style={{ width: '100%', maxWidth: '400px' }}>
        <Story />
      </div>
    ),
  ],
};

export const LongContent: Story = {
  args: {
    video: {
      ...mockVideo,
      title: 'Очень длинное название видео которое должно обрезаться и показываться в несколько строк с многоточием в конце',
      description: 'Также очень длинное описание которое должно обрезаться после двух строк и показывать многоточие чтобы не занимать слишком много места в интерфейсе',
    },
    authorName: 'Иван Иванов',
  },
  decorators: [
    (Story) => (
      <div style={{ width: '100%', maxWidth: '400px' }}>
        <Story />
      </div>
    ),
  ],
};

export const Expanded: Story = {
  args: {
    video: mockVideo,
    authorName: 'Иван Иванов',
    expanded: true,
  },
};