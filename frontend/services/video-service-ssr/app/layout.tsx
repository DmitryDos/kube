import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { PropsWithChildren } from 'react';
import { ApolloProviderWrapper } from '../src/contexts/ApolloProvider';
import { ModalProvider } from '../src/components/Modal/ModalProvider';
import { VideoPlaybackProvider } from '../src/contexts/VideoPlaybackContext';
import './globals.css';

const inter = Inter({ subsets: ['latin', 'cyrillic'] });

export const metadata: Metadata = {
  title: 'YetMusic - Видео платформа',
  description: 'Платформа для поиска и просмотра видео',
};

type RootLayoutProps = PropsWithChildren;

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="ru">
      <body className={inter.className}>
        <ApolloProviderWrapper>
          <ModalProvider>
            <VideoPlaybackProvider>
                {children}
            </VideoPlaybackProvider>
          </ModalProvider>
        </ApolloProviderWrapper>
      </body>
    </html>
  );
}

