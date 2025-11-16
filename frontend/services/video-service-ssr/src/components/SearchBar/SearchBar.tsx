// src/components/SearchBar/SearchBar.tsx
'use client';

import { useState, useRef, useEffect } from 'react';
import styles from './SearchBar.module.css';

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  onSubmit?: () => void;
  placeholder?: string;
}

export function SearchBar({ 
  value, 
  onChange, 
  onSubmit, 
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
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.value);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      onSubmit?.();
      inputRef.current?.blur();
    }
  };

  const handleSubmitClick = () => {
    onSubmit?.();
    inputRef.current?.blur();
  };

  return (
    <div className={styles['search-container']}>
      {isExpanded ? (
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
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            className={styles['search-input']}
            autoComplete="off"
            autoCorrect="off"
            autoCapitalize="off"
            spellCheck="false"
          />
          <button
            type="button"
            onClick={handleSubmitClick}
            className={styles['submit-button']}
            aria-label="Найти"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M5 12h14" />
              <path d="M12 5l7 7-7 7" />
            </svg>
          </button>
        </div>
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

