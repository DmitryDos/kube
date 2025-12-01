// src/components/Search/Search.tsx
'use client';

import { SearchBar } from '../SearchBar/SearchBar';
import { FilterChips } from '../FilterChips/FilterChips';
import { SearchFilter } from '../../types';
import styles from './Search.module.css';

interface SearchProps {
  searchQuery: string;
  selectedFilter: SearchFilter;
  onSearchChange: (value: string) => void;
  onFilterChange: (filter: SearchFilter) => void;
  onSubmit?: () => void;
  placeholder?: string;
}

export function Search({ 
  searchQuery,
  selectedFilter,
  onSearchChange,
  onFilterChange,
  onSubmit,
  placeholder = 'Поиск видео и авторов'
}: SearchProps) {

  return (
    <div className={styles['search']}>
      <div className={styles['search-bar-wrapper']}>
        <SearchBar
          value={searchQuery}
          onChange={onSearchChange}
          onSubmit={onSubmit}
          placeholder={placeholder}
        />
      </div>
      <div className={styles['filter-chips-wrapper']}>
        <FilterChips
          selectedFilter={selectedFilter}
          onFilterChange={onFilterChange}
        />
      </div>
    </div>
  );
}

