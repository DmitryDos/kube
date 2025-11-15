import type { Preview } from '@storybook/react';
import React from 'react';
import {sb} from 'storybook/test';
import '../app/globals.css';

sb.mock(import('../src/hooks/useSearch.ts'));
sb.mock(import('../src/hooks/useVideo.ts'));
sb.mock(import('../src/hooks/useAuth.ts'));

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
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
      <div data-theme="dark" style={{ minHeight: '100vh' }}>
        <Story />
      </div>
    ),
  ],
};

export default preview;