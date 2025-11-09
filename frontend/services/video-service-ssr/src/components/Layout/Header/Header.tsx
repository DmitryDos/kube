'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useAuth } from '../../../hooks/useAuth';
import { useRouter } from 'next/navigation';
import { useModal } from '../../../contexts/ModalContext';
import { AuthModalContent } from '../../AuthModal/AuthModal';
import styles from './Header.module.css';

export function Header() {
  const { isAuthenticated, currentUser, logout, isLoading } = useAuth();
  const router = useRouter();
  const { openModal } = useModal();
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const handleLogout = async () => {
    await logout();
    router.push('/main');
  };

  const handleAuthClick = (e: React.MouseEvent) => {
    e.preventDefault();
    openModal({
      id: 'auth',
      title: 'Авторизация',
      content: <AuthModalContent />,
    });
    setIsMenuOpen(false);
  };

  return (
    <header className={styles['header']}>
      <div className={styles['container']}>
        <Link href="/main" className={styles['logo']}>
          YetMusic
        </Link>

        <nav className={`${styles['nav']} ${isMenuOpen ? styles['navOpen'] : ''}`}>
          {!isLoading && (
            <>
              {isAuthenticated && currentUser ? (
                <>
                  <div className={styles['userAvatar']}>
                    <div className={styles['avatar']} title={currentUser.name}>
                      {currentUser.name.charAt(0).toUpperCase()}
                    </div>
                  </div>
                  <button onClick={handleLogout} className={styles['navButton']}>
                    Выйти
                  </button>
                </>
              ) : (
                <button onClick={handleAuthClick} className={styles['navLink']}>
                  Войти
                </button>
              )}
            </>
          )}
        </nav>

        <button
          className={styles['menuButton']}
          onClick={() => setIsMenuOpen(!isMenuOpen)}
          aria-label="Меню"
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
            {isMenuOpen ? (
              <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" />
            ) : (
              <path d="M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z" />
            )}
          </svg>
        </button>
      </div>
    </header>
  );
}

