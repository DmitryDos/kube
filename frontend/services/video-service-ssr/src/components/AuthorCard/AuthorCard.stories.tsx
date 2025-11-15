// src/components/AuthorCard/AuthorCard.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { AuthorCard } from './AuthorCard';
import { Author } from '../../types';

const mockAuthor: Author = {
  id: '1',
  name: 'Иван Иванов',
  title: 'Senior Frontend Developer',
  subtitle: 'Создатель образовательного контента по React и TypeScript',
  avatar_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
  videoCount: 42,
  followerCount: 1500
};

const meta = {
  title: 'Components/AuthorCard',
  component: AuthorCard,
  parameters: {
    layout: 'padded',
  },
  decorators: [
    (Story) => (
      <div style={{ width: '400px', maxWidth: '100%' }}>
        <Story />
      </div>
    ),
  ],
  tags: ['autodocs'],
  argTypes: {
    onClick: { action: 'clicked' },
  },
} satisfies Meta<typeof AuthorCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    author: mockAuthor,
  },
};

export const WithoutAvatar: Story = {
  args: {
    author: {
      ...mockAuthor,
      avatar_url: undefined,
      imageURL: undefined,
    },
  },
};

export const MinimalInfo: Story = {
  args: {
    author: {
      id: '2',
      name: 'Анонимный автор',
    },
  },
};