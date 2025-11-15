// src/components/PlaylistsPage/PlaylistsPage.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { PlaylistsPage } from './PlaylistsPage';
import { ModalProvider } from '../Modal/ModalProvider';

const meta = {
  title: 'Pages/PlaylistsPage',
  component: PlaylistsPage,
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
      <ModalProvider>
        <div style={{ minHeight: '100vh', backgroundColor: 'var(--background-color)' }}>
          <Story />
        </div>
      </ModalProvider>
    ),
  ],
  tags: ['autodocs'],
  argTypes: {
    onVideoClick: { action: 'video clicked' },
  },
} satisfies Meta<typeof PlaylistsPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {},
};

