// src/components/SearchPage/SearchPage.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { SearchPage } from './SearchPage';

const meta = {
  title: 'Pages/SearchPage',
  component: SearchPage,
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
} satisfies Meta<typeof SearchPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {},
};

export const Desktop: Story = {
  args: {},
  parameters: {
    viewport: {
      defaultViewport: 'desktop',
    },
  },
};

export const Tablet: Story = {
  args: {},
  parameters: {
    viewport: {
      defaultViewport: 'tablet',
    },
  },
};

export const Mobile: Story = {
  args: {},
  parameters: {
    viewport: {
      defaultViewport: 'mobile1',
    },
  },
};

