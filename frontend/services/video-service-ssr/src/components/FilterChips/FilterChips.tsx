// src/components/FilterChips/FilterChips.tsx
'use client';

import { SearchFilter } from '../../types';
import styles from './FilterChips.module.css';

interface FilterChipsProps {
  selectedFilter: SearchFilter;
  onFilterChange: (filter: SearchFilter) => void;
}

const filters: { value: SearchFilter; label: string }[] = [
  { value: 'all', label: 'Все' },
  { value: 'videos', label: 'Видео' },
  { value: 'authors', label: 'Авторы' },
];

export function FilterChips({ selectedFilter, onFilterChange }: FilterChipsProps) {
  return (
    <div className={styles['filter-chips']}>
      {filters.map((filter) => (
        <button
          key={filter.value}
          type="button"
          className={`${styles['chip']} ${selectedFilter === filter.value ? styles['chip-selected'] : ''}`}
          onClick={() => onFilterChange(filter.value)}
        >
          {filter.label}
        </button>
      ))}
    </div>
  );
}

