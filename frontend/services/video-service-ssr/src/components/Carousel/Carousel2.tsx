'use client';

import { ReactNode, useRef, useEffect, useState, useCallback } from 'react';
import styles from './Carousel2.module.css';

interface Carousel2Props {
  pages: ReactNode[];
  initialPage?: number;
  onPageChange?: (pageIndex: number) => void;
}

export function Carousel2({ 
  pages, 
  initialPage = 0, 
  onPageChange
}: Carousel2Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [currentPageIndex, setCurrentPageIndex] = useState(initialPage);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [transitionDirection, setTransitionDirection] = useState(0);
  const [scrollOffset, setScrollOffset] = useState(0);
  
  const isDraggingRef = useRef(false);
  const startXRef = useRef(0);
  const startScrollOffsetRef = useRef(0);
  const lastXRef = useRef(0);
  const lastTimeRef = useRef(0);
  const velocityRef = useRef(0);
  const animIdRef = useRef<number | null>(null);
  const centerTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isTransitioningRef = useRef(false);
  const currentPageIndexRef = useRef(initialPage);
  const scrollOffsetRef = useRef(0);
  const transitionStartOffsetRef = useRef(0);
  const scrollVelocityHistoryRef = useRef<number[]>([]);
  const maxScrollVelocityRef = useRef(0);
  const isScrollBlockedRef = useRef(false);

  const normalizePageIndex = useCallback((index: number) => {
    return ((index % pages.length) + pages.length) % pages.length;
  }, [pages.length]);

  const getContainerWidth = useCallback(() => {
    return containerRef.current?.clientWidth || 0;
  }, []);

  const getPageWidth = useCallback(() => {
    const containerWidth = getContainerWidth();
    return containerWidth * 1.06;
  }, [getContainerWidth]);

  const getMaxOffset = useCallback(() => {
    const pageWidth = getPageWidth();
    const containerWidth = getContainerWidth();
    return pageWidth - containerWidth;
  }, [getPageWidth, getContainerWidth]);

  const animateOffset = useCallback((targetOffset: number, duration = 300, onComplete?: () => void) => {
    if (animIdRef.current) {
      cancelAnimationFrame(animIdRef.current);
      animIdRef.current = null;
    }
    
    const startOffset = scrollOffsetRef.current;
    const delta = targetOffset - startOffset;
    
    if (Math.abs(delta) < 1) {
      setScrollOffset(targetOffset);
      scrollOffsetRef.current = targetOffset;
      if (onComplete) onComplete();
      return;
    }
    
    const startTs = performance.now();
    const easeOutCubic = (t: number) => 1 - Math.pow(1 - t, 3);
    
    const step = (ts: number) => {
      const elapsed = ts - startTs;
      const t = Math.min(1, elapsed / duration);
      const eased = easeOutCubic(t);
      const currentOffset = startOffset + delta * eased;
      setScrollOffset(currentOffset);
      scrollOffsetRef.current = currentOffset;
      
      if (t < 1) {
        animIdRef.current = requestAnimationFrame(step);
      } else {
        animIdRef.current = null;
        setScrollOffset(targetOffset);
        scrollOffsetRef.current = targetOffset;
        if (onComplete) onComplete();
      }
    };
    
    animIdRef.current = requestAnimationFrame(step);
  }, []);

  const centerPage = useCallback(() => {
    animateOffset(0, 200);
  }, [animateOffset]);

  const transitionToPage = useCallback((direction: number) => {
    if (isTransitioningRef.current) return;
    
    const newIndex = normalizePageIndex(currentPageIndexRef.current + direction);
    setIsTransitioning(true);
    isTransitioningRef.current = true;
    setTransitionDirection(direction);
    
    if (centerTimeoutRef.current) {
      clearTimeout(centerTimeoutRef.current);
      centerTimeoutRef.current = null;
    }
    
    const pageWidth = getPageWidth();
    const currentOffset = scrollOffsetRef.current;
    transitionStartOffsetRef.current = currentOffset;
    
    if (direction < 0) {
      animateOffset(-pageWidth, 320, () => {
        setCurrentPageIndex(newIndex);
        currentPageIndexRef.current = newIndex;
        setScrollOffset(0);
        scrollOffsetRef.current = 0;
        setIsTransitioning(false);
        isTransitioningRef.current = false;
        setTransitionDirection(0);
        onPageChange?.(newIndex);
      });
    } else {
      animateOffset(pageWidth, 320, () => {
        setCurrentPageIndex(newIndex);
        currentPageIndexRef.current = newIndex;
        setScrollOffset(0);
        scrollOffsetRef.current = 0;
        setIsTransitioning(false);
        isTransitioningRef.current = false;
        setTransitionDirection(0);
        onPageChange?.(newIndex);
      });
    }
  }, [normalizePageIndex, getPageWidth, animateOffset, onPageChange]);

  useEffect(() => {
    currentPageIndexRef.current = initialPage;
    setCurrentPageIndex(initialPage);
  }, [initialPage]);

  useEffect(() => {
    currentPageIndexRef.current = currentPageIndex;
  }, [currentPageIndex]);

  useEffect(() => {
    scrollOffsetRef.current = scrollOffset;
  }, [scrollOffset]);

  const handlePointerDown = useCallback((e: React.PointerEvent) => {
    const container = containerRef.current;
    if (!container || isTransitioningRef.current) return;
    
    e.preventDefault();
    container.setPointerCapture(e.pointerId);
    
    if (animIdRef.current) {
      cancelAnimationFrame(animIdRef.current);
      animIdRef.current = null;
    }
    
    if (centerTimeoutRef.current) {
      clearTimeout(centerTimeoutRef.current);
      centerTimeoutRef.current = null;
    }
    
    isDraggingRef.current = true;
    startXRef.current = e.clientX;
    startScrollOffsetRef.current = scrollOffset;
    lastXRef.current = e.clientX;
    lastTimeRef.current = performance.now();
    velocityRef.current = 0;
  }, [scrollOffset]);

  const handlePointerMove = useCallback((e: React.PointerEvent) => {
    if (!isDraggingRef.current || isTransitioningRef.current) return;
    
    e.preventDefault();
    
    const containerWidth = getContainerWidth();
    const maxOffset = getMaxOffset();
    
    const deltaX = e.clientX - startXRef.current;
    let newOffset = startScrollOffsetRef.current + deltaX;
    
    newOffset = Math.max(-maxOffset, Math.min(newOffset, maxOffset));
    setScrollOffset(newOffset);
    
    const now = performance.now();
    const dt = Math.max(1, now - lastTimeRef.current);
    const dx = newOffset - startScrollOffsetRef.current;
    velocityRef.current = dx / dt;
    
    lastXRef.current = e.clientX;
    lastTimeRef.current = now;
    
    const threshold = containerWidth * 0.02;
    
    if (newOffset >= maxOffset - threshold && !isTransitioningRef.current && deltaX > 0) {
      transitionToPage(1);
      isDraggingRef.current = false;
      containerRef.current?.releasePointerCapture(e.pointerId);
    }
    else if (newOffset <= -maxOffset + threshold && !isTransitioningRef.current && deltaX < 0 && startScrollOffsetRef.current === 0) {
      transitionToPage(-1);
      isDraggingRef.current = false;
      containerRef.current?.releasePointerCapture(e.pointerId);
    }
  }, [getContainerWidth, getMaxOffset, transitionToPage]);

  const handlePointerUp = useCallback((e: React.PointerEvent) => {
    const container = containerRef.current;
    if (!container) return;
    
    container.releasePointerCapture(e.pointerId);
    
    if (!isDraggingRef.current) return;
    isDraggingRef.current = false;
    
    if (isTransitioningRef.current) return;
    
    if (centerTimeoutRef.current) {
      clearTimeout(centerTimeoutRef.current);
    }
    centerTimeoutRef.current = setTimeout(() => {
      centerPage();
    }, 100);
  }, [centerPage]);

  const handlePointerCancel = useCallback((e: React.PointerEvent) => {
    const container = containerRef.current;
    if (!container) return;
    
    container.releasePointerCapture(e.pointerId);
    isDraggingRef.current = false;
    
    if (isTransitioningRef.current) return;
    
    centerPage();
  }, [centerPage]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const handleWheel = (e: WheelEvent) => {
      const dx = e.deltaX;
      if (dx === 0) return;
      if (isDraggingRef.current || isTransitioningRef.current) return;

      e.preventDefault();

      const absDx = Math.abs(dx);
      const scrollVelocityHistory = scrollVelocityHistoryRef.current;
      scrollVelocityHistory.push(absDx);
      
      if (scrollVelocityHistory.length > 5) {
        scrollVelocityHistory.shift();
      }

      if (absDx > maxScrollVelocityRef.current) {
        isScrollBlockedRef.current = false;
      } else {
        isScrollBlockedRef.current = true;
      }

      maxScrollVelocityRef.current = absDx;

      if (isScrollBlockedRef.current) {
        return;
      }

      const containerWidth = getContainerWidth();
      const maxOffset = getMaxOffset();
      const threshold = containerWidth * 0;

      const currentOffset = scrollOffsetRef.current;
      const scrollSensitivity = 0.1;
      const newOffset = currentOffset - dx * scrollSensitivity;

      const wouldHitRightEdge = newOffset >= maxOffset - threshold && dx < 0;
      const wouldHitLeftEdge = newOffset <= -maxOffset + threshold && dx > 0;

      if (wouldHitRightEdge && !isTransitioningRef.current) {
        if (centerTimeoutRef.current) {
          clearTimeout(centerTimeoutRef.current);
          centerTimeoutRef.current = null;
        }
        maxScrollVelocityRef.current = 0;
        scrollVelocityHistoryRef.current = [];
        transitionToPage(1);
        return;
      } else if (wouldHitLeftEdge && !isTransitioningRef.current) {
        if (centerTimeoutRef.current) {
          clearTimeout(centerTimeoutRef.current);
          centerTimeoutRef.current = null;
        }
        maxScrollVelocityRef.current = 0;
        scrollVelocityHistoryRef.current = [];
        transitionToPage(-1);
        return;
      }

      let currentScrollOffset = Math.max(-maxOffset, Math.min(newOffset, maxOffset));
      setScrollOffset(currentScrollOffset);

      if (centerTimeoutRef.current) {
        clearTimeout(centerTimeoutRef.current);
      }
      centerTimeoutRef.current = setTimeout(() => {
        if (!isTransitioningRef.current) {
          maxScrollVelocityRef.current = 0;
          scrollVelocityHistoryRef.current = [];
          centerPage();
        }
      }, 100);
    };

    container.addEventListener('wheel', handleWheel as EventListener, { passive: false } as AddEventListenerOptions);
    return () => {
      container.removeEventListener('wheel', handleWheel as EventListener);
      if (centerTimeoutRef.current) {
        clearTimeout(centerTimeoutRef.current);
      }
    };
  }, [getContainerWidth, getMaxOffset, transitionToPage, centerPage]);

  useEffect(() => {
    return () => {
      if (centerTimeoutRef.current) {
        clearTimeout(centerTimeoutRef.current);
      }
      if (animIdRef.current) {
        cancelAnimationFrame(animIdRef.current);
      }
    };
  }, []);

  const renderPages = () => {
    const currentPage = pages[normalizePageIndex(currentPageIndex)];
    
    if (isTransitioning && transitionDirection !== 0) {
      const nextIndex = normalizePageIndex(currentPageIndex + transitionDirection);
      const nextPage = pages[nextIndex];
      
      const containerWidth = getContainerWidth();
      const pageWidth = getPageWidth();
      const centerOffset = (pageWidth - containerWidth) / 2;
      
      if (transitionDirection < 0) {
        return (
          <>
            <div
              className={styles['page']}
              style={{
                transform: `translateX(${scrollOffset - centerOffset}px)`
              }}
            >
              {currentPage}
            </div>
            <div
              className={styles['page']}
              style={{
                transform: `translateX(${scrollOffset + pageWidth - centerOffset}px)`
              }}
            >
              {nextPage}
            </div>
          </>
        );
      } else {
        return (
          <>
            <div
              className={styles['page']}
              style={{
                transform: `translateX(${scrollOffset - pageWidth - centerOffset}px)`
              }}
            >
              {nextPage}
            </div>
            <div
              className={styles['page']}
              style={{
                transform: `translateX(${scrollOffset - centerOffset}px)`
              }}
            >
              {currentPage}
            </div>
          </>
        );
      }
    }
    
    const containerWidth = getContainerWidth();
    const pageWidth = getPageWidth();
    const centerOffset = (pageWidth - containerWidth) / 2;
    
    return (
      <div
        className={styles['page']}
        style={{
          transform: `translateX(${scrollOffset - centerOffset}px)`
        }}
      >
        {currentPage}
      </div>
    );
  };

  return (
    <div
      ref={containerRef}
      className={styles['carousel']}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerCancel}
    >
      {renderPages()}
    </div>
  );
}
