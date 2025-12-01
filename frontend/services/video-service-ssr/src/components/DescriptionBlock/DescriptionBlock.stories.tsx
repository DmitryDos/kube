// src/components/DescriptionBlock/DescriptionBlock.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { DescriptionBlock } from './DescriptionBlock';

const meta = {
  title: 'Components/DescriptionBlock',
  component: DescriptionBlock,
  parameters: {
    layout: 'padded',
  },
  decorators: [
    (Story) => (
      <div style={{ display: 'flex', alignItems: 'flex-end', width: '600px', maxWidth: '100%', height: '80vh' }}>
        <Story />
      </div>
    ),
  ],
  tags: ['autodocs'],
} satisfies Meta<typeof DescriptionBlock>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    title: 'Как настроить Storybook за 5 минут',
    description: 'Полное руководство по настройке Storybook для React проектов с TypeScript и Next.js. В этом видео мы рассмотрим все основные шаги настройки, включая конфигурацию, создание stories и работу с декораторами.',
    authorName: 'Иван Иванов',
    createdAt: '2024-01-15T10:30:00Z',
    viewCount: 1250,
    likeCount: 89,
  },
};

export const LongDescription: Story = {
  args: {
    title: 'React Hooks: полное руководство',
    description: `Изучите все хуки React от useState до useReducer.

В этом подробном руководстве мы рассмотрим:
- useState - для управления состоянием компонента
- useEffect - для выполнения побочных эффектов
- useContext - для работы с контекстом
- useReducer - для сложной логики состояния
- useCallback и useMemo - для оптимизации производительности
- useRef - для работы с DOM и сохранения значений между рендерами
- И многое другое!

Каждый хук будет рассмотрен с примерами кода и практическими применениями.`,
    authorName: 'Мария Петрова',
    createdAt: '2024-01-20T14:15:00Z',
    viewCount: 3420,
    likeCount: 156,
  },
};

export const MinimalInfo: Story = {
  args: {
    title: 'Краткое видео',
    description: 'Короткое описание',
    authorName: 'Автор',
  },
};

export const WithoutDescription: Story = {
  args: {
    title: 'Видео без описания',
    authorName: 'Автор',
    viewCount: 500,
  },
};

