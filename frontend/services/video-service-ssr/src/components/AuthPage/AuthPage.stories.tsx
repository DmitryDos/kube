// src/components/AuthPage/AuthPage.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { AuthPage } from './AuthPage';
import { ModalProvider } from '../Modal/ModalProvider';
import { ApolloProviderWrapper } from '../../contexts/ApolloProvider';

const meta: Meta<typeof AuthPage> = {
  title: 'Pages/AuthPage',
  component: AuthPage,
  decorators: [
    (Story) => (
      <ApolloProviderWrapper>
        <ModalProvider>
          <Story />
        </ModalProvider>
      </ApolloProviderWrapper>
    ),
  ],
  parameters: {
    layout: 'fullscreen',
  },
};

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

