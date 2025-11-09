import { Suspense } from 'react';
import { MainPageClient } from '../../src/views/MainPage/MainPageClient';
import { SearchParams } from '../../src/types/pageParams';

export const dynamic = 'force-dynamic';

type MainPageProps = {
  searchParams: SearchParams<{ q?: string; filter?: string }>;
};

export default async function MainPage(props: MainPageProps) {
  const searchParams = await props.searchParams;
  const query = searchParams.q || '';
  const filter = (searchParams.filter as 'all' | 'videos' | 'authors') || 'all';

  return (
    <Suspense fallback={<div>Загрузка...</div>}>
      <MainPageClient initialQuery={query} initialFilter={filter} />
    </Suspense>
  );
}
