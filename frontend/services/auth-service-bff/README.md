# Auth Service BFF

Backend for Frontend сервис для авторизации.

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

- `PORT` - Порт сервиса (по умолчанию 3003)
- `API_BASE_URL` - URL API Gateway (по умолчанию http://localhost:8080)
- `FRONTEND_URL` - URL фронтенда для CORS (по умолчанию http://localhost:3000)
- `NODE_ENV` - Окружение (production/development)

## API Endpoints

- `POST /api/auth/login` - Вход
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/logout` - Выход
- `GET /api/auth/me` - Получение текущего пользователя

