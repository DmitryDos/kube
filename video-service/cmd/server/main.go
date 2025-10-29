package main

import (
    "context"
    "database/sql"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "time"
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

    for i := 0; i < 10; i++ {
        if err := db.Ping(); err == nil {
            break
        }
        log.Printf("Waiting for database... (attempt %d/10)", i+1)
        time.Sleep(2 * time.Second)
        if i == 9 {
            log.Fatal("Database ping failed:", err)
        }
    }

    log.Println("Database connected")

    minioClient, err := storage.NewMinIOClient()
    if err != nil {
        log.Fatal("Failed to connect to MinIO:", err)
    }

    log.Println("MinIO connected")

    videoRepo := repository.NewVideoRepository(db)
    videoService := service.NewVideoService(videoRepo, minioClient)
    videoHandler := handler.NewVideoHandler(videoService)
    healthHandler := handler.NewHealthHandler()

    r := gin.Default()
    
    r.GET("/health", healthHandler.HealthCheck)
    
    protected := r.Group("/api/videos")
    protected.Use(handler.AuthenticateJWT())
    {
        protected.POST("/upload", videoHandler.UploadVideo)
        protected.POST("/upload/raw", videoHandler.UploadVideoRaw)
        protected.GET("/", videoHandler.GetVideos)
        protected.GET("/:id/stream", videoHandler.StreamVideo)
        protected.GET("/:id/stream/url", videoHandler.GetStreamURL)
    }

    port := ":3001"
    
    srv := &http.Server{
        Addr:    port,
        Handler: r,
    }

    go func() {
        log.Printf("Video service running on port %s", port)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatal("Failed to start server:", err)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, os.Interrupt, os.Kill)
    <-quit

    log.Println("Shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }

    if err := db.Close(); err != nil {
        log.Printf("Error closing database: %v", err)
    }

    log.Println("Server exited")
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}