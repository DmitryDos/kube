FROM golang:1.21-alpine

WORKDIR /app

# Копируем исходный код
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Собираем приложение
RUN go build -o main ./cmd/server

# Создаем пользователя
RUN adduser -D -u 1001 appuser

# Создаем директорию ДО смены пользователя
RUN mkdir -p /app/uploads /app/temp
RUN chown -R appuser:appuser /app/uploads /app/temp

USER appuser

EXPOSE 3001

CMD ["./main"]