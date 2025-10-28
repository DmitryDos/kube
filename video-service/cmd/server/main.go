package main

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    "video-service/internal/handler"
    "video-service/internal/repository"
    "video-service/internal/service"
    "video-service/internal/storage"

    "github.com/gin-gonic/gin"
    _ "github.com/lib/pq"
)

func main() {
    connStr := fmt.Sprintf(
        "host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        getEnv("DB_HOST", "localhost"),
        getEnv("DB_PORT", "5432"),
        getEnv("DB_USER", "admin"),
        getEnv("DB_PASSWORD", "password123"),
        getEnv("DB_NAME", "video_platform"),
    )

    db, err := sql.Open("postgres", connStr)
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    defer db.Close()

    // Проверка подключения
    if err := db.Ping(); err != nil {
        log.Fatal("Database ping failed:", err)
    }

    minioClient, err := storage.NewMinIOClient()
    if err != nil {
        log.Fatal("Failed to connect to MinIO:", err)
    }

    // Остальной код без изменений...
    videoRepo := repository.NewVideoRepository(db)
    videoService := service.NewVideoService(videoRepo, minioClient)
    videoHandler := handler.NewVideoHandler(videoService)
    healthHandler := handler.NewHealthHandler()

    r := gin.Default()
    r.GET("/health", healthHandler.HealthCheck)
    r.POST("/api/videos/upload", videoHandler.UploadVideo)
    r.GET("/api/videos", videoHandler.GetVideos)
    r.GET("/api/videos/:id/stream", videoHandler.StreamVideo)

    port := ":3001"
    log.Printf("Video service running on port %s", port)
    if err := r.Run(port); err != nil {
        log.Fatal("Failed to start server:", err)
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}