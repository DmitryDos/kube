// Утилиты для нормализации URL

// Нормализует URL миниатюры: всегда используем прокси-роут Next.js
export function normalizeThumbnailUrl(_url: string | undefined, videoId: string): string {
  // Всегда используем прокси-роут, который добавит токен из cookie
  return `/api/proxy/videos/${videoId}/thumbnail`;
}

