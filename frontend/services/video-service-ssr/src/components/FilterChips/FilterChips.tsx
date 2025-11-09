'use client';

import { SearchFilter } from '../../types';
import styles from './FilterChips.module.css';

interface FilterChipsProps {
  selected: SearchFilter;
  onChange: (filter: SearchFilter) => void;
}

const filters: { value: SearchFilter; label: string }[] = [
  { value: 'all', label: 'Все' },
  { value: 'videos', label: 'Видео' },
  { value: 'authors', label: 'Авторы' },
];

export default function FilterChips({ selected, onChange }: FilterChipsProps) {
  return (
    <div className={styles['filterChips']}>
      {filters.map((filter) => (
        <button
          key={filter.value}
          onClick={() => onChange(filter.value)}
          className={`${styles['chip']} ${selected === filter.value ? styles['active'] : ''}`}
        >
          {filter.label}
        </button>
      ))}
    </div>
  );
}

