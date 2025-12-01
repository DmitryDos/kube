'use client';

import { ReactNode, useRef, useEffect, useState, useCallback } from 'react';
import styles from './Carousel.module.css';

interface CarouselProps {
  pages: ReactNode[];
  initialPage?: number;
  onPageChange?: (pageIndex: number) => void;
}

export function Carousel({ pages, initialPage = 0, onPageChange }: CarouselProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [currentPage, setCurrentPage] = useState(initialPage);
  const isDraggingRef = useRef(false);
  const startXRef = useRef(0);
  const startScrollLeftRef = useRef(0);
  const lastXRef = useRef(0);
  const lastTimeRef = useRef(0);
  const animIdRef = useRef<number | null>(null);
  const isWheelingRef = useRef(false);
  const startPageRef = useRef(0);
  const currentPageRef = useRef(initialPage);
  const wheelActiveRef = useRef(false);
  const wheelTriggeredRef = useRef(false);
  const wheelEndTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const getPageWidth = () => {
    return containerRef.current?.clientWidth || 0;
  };

  // Плавная анимация до целевого scrollLeft
  const animateTo = useCallback((targetLeft: number, duration = 320, onComplete?: () => void) => {
    const container = containerRef.current;
    if (!container) return;
    if (animIdRef.current) {
      cancelAnimationFrame(animIdRef.current);
      animIdRef.current = null;
    }
    const startLeft = container.scrollLeft;
    const delta = targetLeft - startLeft;
    if (Math.abs(delta) < 1) {
      container.scrollLeft = targetLeft;
      return;
    }
    const startTs = performance.now();
    const easeOutCubic = (t: number) => 1 - Math.pow(1 - t, 3);
    const step = (ts: number) => {
      const elapsed = ts - startTs;
      const t = Math.min(1, elapsed / duration);
      const eased = easeOutCubic(t);
      container.scrollLeft = startLeft + delta * eased;
      if (t < 1) {
        animIdRef.current = requestAnimationFrame(step);
      } else {
        animIdRef.current = null;
        if (onComplete) onComplete();
      }
    };
    animIdRef.current = requestAnimationFrame(step);
  }, []);

  // Инициализация
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    
    const pageWidth = getPageWidth();
    if (pageWidth > 0) {
      container.scrollLeft = initialPage * pageWidth;
      setCurrentPage(initialPage);
    }
  }, [initialPage]);

  // Обработка изменения размера
  useEffect(() => {
    const handleResize = () => {
      const container = containerRef.current;
      if (!container || isDraggingRef.current) return;
      
      const pageWidth = getPageWidth();
      if (pageWidth > 0) {
        container.scrollLeft = currentPage * pageWidth;
      }
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [currentPage]);

  // Синхронизация актуальной страницы в ref (для wheel-логики)
  useEffect(() => {
    currentPageRef.current = currentPage;
  }, [currentPage]);

  // Определение ближайшей страницы
  const getNearestPage = useCallback(() => {
    const container = containerRef.current;
    if (!container) return 0;
    
    const pageWidth = getPageWidth();
    if (pageWidth === 0) return 0;
    
    const scrollLeft = container.scrollLeft;
    // Округление к ближайшей странице
    const pageIndex = Math.round(scrollLeft / pageWidth);
    return Math.max(0, Math.min(pageIndex, pages.length - 1));
  }, [pages.length]);

  // Фиксация на ближайшей странице
  const snapToPage = useCallback(() => {
    const container = containerRef.current;
    if (!container) return;

    const pageWidth = getPageWidth();
    if (pageWidth === 0) return;

    const targetPage = getNearestPage();
    const targetScroll = targetPage * pageWidth;
    animateTo(targetScroll);

    if (targetPage !== currentPage) {
      setCurrentPage(targetPage);
      onPageChange?.(targetPage);
    }
  }, [currentPage, getNearestPage, onPageChange, animateTo]);

  // Начало drag
  const handlePointerDown = useCallback((e: React.PointerEvent) => {
    const container = containerRef.current;
    if (!container) return;
    
    e.preventDefault();
    container.setPointerCapture(e.pointerId);
    
    if (animIdRef.current) {
      cancelAnimationFrame(animIdRef.current);
      animIdRef.current = null;
    }
    isDraggingRef.current = true;
    startXRef.current = e.clientX;
    startScrollLeftRef.current = container.scrollLeft;
    lastXRef.current = e.clientX;
    lastTimeRef.current = performance.now();
    startPageRef.current = Math.round(startScrollLeftRef.current / getPageWidth());
    
    // Отключаем любые нативные плавности
    container.style.scrollBehavior = 'auto';
  }, []);

  // Движение
  const handlePointerMove = useCallback((e: React.PointerEvent) => {
    if (!isDraggingRef.current) return;
    
    const container = containerRef.current;
    if (!container) return;
    
    e.preventDefault();
    
    // Простое следование за курсором
    const deltaX = startXRef.current - e.clientX;
    container.scrollLeft = startScrollLeftRef.current + deltaX;
    lastXRef.current = e.clientX;
    lastTimeRef.current = performance.now();
  }, []);

  // Окончание drag
  const handlePointerUp = useCallback((e: React.PointerEvent) => {
    const container = containerRef.current;
    if (!container) return;
    
    container.releasePointerCapture(e.pointerId);
    
    if (!isDraggingRef.current) return;
    isDraggingRef.current = false;
    
    // Определяем таргет-страницу
    const pageWidth = getPageWidth();
    if (pageWidth === 0) return;
    const scrollLeft = container.scrollLeft;
    const basePage = Math.floor(scrollLeft / pageWidth);
    const offset = scrollLeft - basePage * pageWidth;
    const progress = offset / pageWidth; // 0..1

    // Скорость последнего сегмента (px/ms)
    const now = performance.now();
    const dt = Math.max(1, now - lastTimeRef.current);
    // Вектор направления берём из общего смещения, а не последнего кадра — стабильнее
    const totalDx = startXRef.current - e.clientX; // >0 если движение влево (к следующей)
    const vx = totalDx / dt; // px/ms
    const flick = Math.abs(vx) > 0.6; // чуть мягче порог флика

    let targetPage = basePage;
    if (flick) {
      // На флик перелистываем ровно на одну страницу по направлению
      const dir = vx > 0 ? 1 : -1;
      targetPage = startPageRef.current + dir;
    } else {
      // Без флика: правило 50%
      targetPage = basePage + (progress >= 0.5 ? 1 : 0);
    }
    targetPage = Math.max(0, Math.min(targetPage, pages.length - 1));

    const targetLeft = targetPage * pageWidth;
    // Быстрее анимация на флик, мягче — на обычный драг
    animateTo(targetLeft, flick ? 240 : 360);

    if (targetPage !== currentPage) {
      setCurrentPage(targetPage);
      onPageChange?.(targetPage);
    }
  }, [snapToPage]);

  const handlePointerCancel = useCallback((e: React.PointerEvent) => {
    const container = containerRef.current;
    if (!container) return;
    
    container.releasePointerCapture(e.pointerId);
    isDraggingRef.current = false;
    const pageWidth = getPageWidth();
    const targetLeft = Math.round((container.scrollLeft / pageWidth)) * pageWidth;
    animateTo(targetLeft, 360);
  }, [snapToPage]);

  // Отслеживание изменения страницы (только когда не drag)
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    let timeoutId: NodeJS.Timeout;
    
    const handleScroll = () => {
      // Игнорируем во время drag
      if (isDraggingRef.current || isWheelingRef.current) return;
      
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => {
        const newPage = getNearestPage();
        if (newPage !== currentPage) {
          setCurrentPage(newPage);
          onPageChange?.(newPage);
        }
      }, 50);
    };

    container.addEventListener('scroll', handleScroll, { passive: true });
    return () => {
      container.removeEventListener('scroll', handleScroll);
      clearTimeout(timeoutId);
    };
  }, [currentPage, getNearestPage, onPageChange]);

  // Поддержка тачпада/колесика мыши (wheel): мгновенный переход при начале свайпа
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const handleWheel = (e: WheelEvent) => {
      const dx = e.deltaX;
      if (dx === 0) return;
      if (isDraggingRef.current) return;

      e.preventDefault();

      if (animIdRef.current) return;

      const pageWidth = getPageWidth();
      const startThreshold = 8;
      // Начало жеста
      if (!wheelActiveRef.current) {
        wheelActiveRef.current = true;
        wheelTriggeredRef.current = false;
      }

      if (!wheelTriggeredRef.current && Math.abs(dx) >= startThreshold) {
        const dir = dx > 0 ? 1 : -1;
        const base = currentPageRef.current;
        const targetPage = Math.max(0, Math.min(base + dir, pages.length - 1));
        if (targetPage !== base) {
          wheelTriggeredRef.current = true;
          isWheelingRef.current = true;
          const targetLeft = targetPage * pageWidth;
          animateTo(targetLeft, 220, () => {
            isWheelingRef.current = false;
            wheelActiveRef.current = false;
            wheelTriggeredRef.current = false;
            if (wheelEndTimeoutRef.current) {
              clearTimeout(wheelEndTimeoutRef.current);
              wheelEndTimeoutRef.current = null;
            }
          });
          setCurrentPage(targetPage);
          onPageChange?.(targetPage);
        }
      }

      // Завершение жеста по «тишине»
      if (wheelEndTimeoutRef.current) {
        clearTimeout(wheelEndTimeoutRef.current);
      }
      wheelEndTimeoutRef.current = setTimeout(() => {
        wheelActiveRef.current = false;
        wheelTriggeredRef.current = false;
        wheelEndTimeoutRef.current = null;
      }, 120);
    };

    container.addEventListener('wheel', handleWheel as EventListener, { passive: false } as AddEventListenerOptions);
    return () => {
      container.removeEventListener('wheel', handleWheel as EventListener);
      if (wheelEndTimeoutRef.current) {
        clearTimeout(wheelEndTimeoutRef.current);
        wheelEndTimeoutRef.current = null;
      }
    };
  }, [animateTo, currentPage, onPageChange, pages.length]);

  return (
    <div
      ref={containerRef}
      className={styles['carousel']}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerCancel}
    >
      <div
        className={styles['pagesContainer']}
        style={{ width: `${pages.length * 100}%` }}
      >
        {pages.map((page, index) => (
          <div
            key={index}
            className={styles['page']}
            style={{ width: `${100 / pages.length}%` }}
          >
            {page}
          </div>
        ))}
      </div>
    </div>
  );
}

