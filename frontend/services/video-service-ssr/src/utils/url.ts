// Утилиты для нормализации URL

// Нормализует URL миниатюры: идем напрямую через API Gateway (same origin)
export function normalizeThumbnailUrl(_url: string | undefined, videoId: string): string {
  // Идем напрямую через API Gateway - same origin, токен передается через cookie
  return `/api/videos/${videoId}/thumbnail`;
}

