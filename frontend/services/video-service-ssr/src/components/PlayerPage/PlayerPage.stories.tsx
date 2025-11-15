// src/components/PlayerPage/PlayerPage.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { PlayerPage } from './PlayerPage';

const meta = {
  title: 'Pages/PlayerPage',
  component: PlayerPage,
  parameters: {
    layout: 'fullscreen',
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
      <div style={{ minHeight: '100vh', backgroundColor: 'var(--background-color)' }}>
        <Story />
      </div>
    ),
  ],
  tags: ['autodocs'],
  argTypes: {
    onVideoClick: { action: 'video clicked' },
    onAuthorClick: { action: 'author clicked' },
  },
} satisfies Meta<typeof PlayerPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    videoId: '550e8400-e29b-41d4-a716-446655440000',
  },
};

export const Desktop: Story = {
  args: {
    videoId: '550e8400-e29b-41d4-a716-446655440000',
  },
  parameters: {
    viewport: {
      defaultViewport: 'desktop',
    },
  },
};

export const Tablet: Story = {
  args: {
    videoId: '550e8400-e29b-41d4-a716-446655440000',
  },
  parameters: {
    viewport: {
      defaultViewport: 'tablet',
    },
  },
};

export const Mobile: Story = {
  args: {
    videoId: '550e8400-e29b-41d4-a716-446655440000',
  },
  parameters: {
    viewport: {
      defaultViewport: 'mobile1',
    },
  },
};

