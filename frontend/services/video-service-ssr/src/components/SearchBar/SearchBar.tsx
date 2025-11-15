// src/components/SearchBar/SearchBar.tsx
'use client';

import { useState, useRef, useEffect } from 'react';
import styles from './SearchBar.module.css';

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  onSubmit?: () => void;
  onClear?: () => void;
  placeholder?: string;
}

export function SearchBar({ 
  value, 
  onChange, 
  onSubmit, 
  onClear,
  placeholder = 'Поиск видео и авторов'
}: SearchBarProps) {
  const [isExpanded, setIsExpanded] = useState(!!value);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (value) {
      setIsExpanded(true);
    }
  }, [value]);

  const handleExpand = () => {
    setIsExpanded(true);
    setTimeout(() => {
      inputRef.current?.focus();
    }, 100);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.value);
  };

  const handleClear = () => {
    onChange('');
    onClear?.();
    inputRef.current?.focus();
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit?.();
    inputRef.current?.blur();
  };

  return (
    <div className={styles['search-container']}>
      {isExpanded ? (
        <form onSubmit={handleSubmit} className={styles['search-form']}>
          <div className={styles['search-input-wrapper']}>
            <svg 
              className={styles['search-icon']} 
              width="20" 
              height="20" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="currentColor" 
              strokeWidth="2"
            >
              <circle cx="11" cy="11" r="8" />
              <path d="m21 21-4.35-4.35" />
            </svg>
            <input
              ref={inputRef}
              type="text"
              value={value}
              onChange={handleInputChange}
              placeholder={placeholder}
              className={styles['search-input']}
            />
            {value && (
              <button
                type="button"
                onClick={handleClear}
                className={styles['clear-button']}
                aria-label="Очистить"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="12" r="10" />
                  <path d="m15 9-6 6M9 9l6 6" />
                </svg>
              </button>
            )}
          </div>
        </form>
      ) : (
        <button
          type="button"
          onClick={handleExpand}
          className={styles['search-button']}
          aria-label="Поиск"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8" />
            <path d="m21 21-4.35-4.35" />
          </svg>
        </button>
      )}
    </div>
  );
}

