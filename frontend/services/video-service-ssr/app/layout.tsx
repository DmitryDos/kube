import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { PropsWithChildren } from 'react';
import { ApolloProviderWrapper } from '../src/contexts/ApolloProvider';
import { VideoPlaybackProvider } from '../src/contexts/VideoPlaybackContext';
import { ModalProvider } from '../src/contexts/ModalContext';
import { Modal } from '../src/components/Modal/Modal';
import { VideoModal } from '../src/components/VideoModal/VideoModal';
import { AppLayout } from '../src/components/Layout/AppLayout';
import { PageParams } from '../src/types/pageParams';
import './globals.css';

const inter = Inter({ subsets: ['latin', 'cyrillic'] });

export const metadata: Metadata = {
  title: 'YetMusic - Видео платформа',
  description: 'Платформа для поиска и просмотра видео',
};

type RootLayoutProps = PropsWithChildren<{
  params: PageParams<{}>;
}>;

export default async function RootLayout(props: RootLayoutProps) {
  await props.params;
  const children = await props.children;
  return (
    <html lang="ru">
      <body className={inter.className}>
        <ApolloProviderWrapper>
          <ModalProvider>
            <VideoPlaybackProvider>
              <AppLayout>
                {children}
              </AppLayout>
              <VideoModal />
              <Modal />
            </VideoPlaybackProvider>
          </ModalProvider>
        </ApolloProviderWrapper>
      </body>
    </html>
  );
}

