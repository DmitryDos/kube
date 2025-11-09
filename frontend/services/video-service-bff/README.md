# Video Service BFF

Backend for Frontend сервис для работы с видео.

## Установка

```bash
npm install
```

## Запуск

```bash
# Development
npm run start:dev

# Production
npm run build
npm run start:prod
```

## Переменные окружения

- `PORT` - Порт сервиса (по умолчанию 3002)
- `API_BASE_URL` - URL API Gateway (по умолчанию http://localhost:8080)
  - Для локальной разработки: `http://localhost:8080`
  - Для Docker: `http://api-gateway:80` (используется переменная `API_GATEWAY_SERVICE`)
- `API_GATEWAY_SERVICE` - Имя сервиса API Gateway в Docker (если задано, используется вместо `API_BASE_URL`)
- `FRONTEND_URL` - URL фронтенда для CORS (по умолчанию http://localhost:3000)

**Важно:** Убедитесь, что API Gateway запущен и доступен по указанному адресу перед запуском сервиса.

## API Endpoints

- `GET /api/search` - Поиск видео и авторов
- `GET /api/videos/:id/stream/proxy` - Потоковое воспроизведение видео
- `GET /api/videos/:id/thumbnail` - Получение миниатюры видео

