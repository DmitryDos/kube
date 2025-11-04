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

    // Optional backfill: set owner for all videos
    if err := backfillOwner(db); err != nil {
        log.Printf("Backfill owner skipped/failed: %v", err)
    }

    minioClient, err := storage.NewMinIOClient()
    if err != nil {
        log.Fatal("Failed to connect to MinIO:", err)
    }

    log.Println("MinIO connected")

    videoRepo := repository.NewVideoRepository(db)
    videoService := service.NewVideoService(videoRepo, minioClient)
    videoHandler := handler.NewVideoHandler(videoService)
    searchHandler := handler.NewSearchHandler(videoService)
    healthHandler := handler.NewHealthHandler()

    r := gin.Default()
    
    r.GET("/health", healthHandler.HealthCheck)

    api := r.Group("/api")
    {
        protected := api.Group("")
        protected.Use(handler.AuthenticateJWT())
        {
            videosGroup := protected.Group("/videos")
            {
                videosGroup.POST("/upload", videoHandler.UploadVideo)
                videosGroup.POST("/upload/raw", videoHandler.UploadVideoRaw)
                videosGroup.GET("/all", videoHandler.SearchAllVideos)
                videosGroup.PUT("/:id", videoHandler.UpdateVideoMetadata)
                videosGroup.PATCH("/:id", videoHandler.UpdateVideoMetadata)
                videosGroup.DELETE("/:id", videoHandler.DeleteVideo)
            }
        }

        api.GET("/search", searchHandler.SearchVideosAndAuthors)
        api.GET("/videos/:id/stream", videoHandler.StreamVideo)
        api.GET("/videos/:id/stream/url", videoHandler.GetStreamURL)
        api.GET("/videos/:id/stream/proxy", videoHandler.StreamVideoProxy)
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

// backfillOwner updates all records in videos to have a specific owner id, if configured.
func backfillOwner(videoDB *sql.DB) error {
    ownerIDEnv := os.Getenv("BACKFILL_OWNER_ID")
    ownerEmail := os.Getenv("BACKFILL_OWNER_EMAIL")
    if ownerIDEnv == "" && ownerEmail == "" {
        return nil
    }

    var ownerID int
    if ownerIDEnv != "" {
        // parse int
        if _, err := fmt.Sscanf(ownerIDEnv, "%d", &ownerID); err != nil {
            return fmt.Errorf("invalid BACKFILL_OWNER_ID: %w", err)
        }
    } else {
        // lookup in auth DB by email
        authConn := fmt.Sprintf(
            "host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
            getEnv("AUTH_DB_HOST", getEnv("DB_HOST", "localhost")),
            getEnv("AUTH_DB_PORT", getEnv("DB_PORT", "5432")),
            getEnv("AUTH_DB_USER", getEnv("DB_USER", "admin")),
            getEnv("AUTH_DB_PASSWORD", getEnv("DB_PASSWORD", "password123")),
            getEnv("AUTH_DB_NAME", "auth_service"),
        )
        adb, err := sql.Open("postgres", authConn)
        if err != nil { return fmt.Errorf("auth db connect: %w", err) }
        defer adb.Close()
        if err := adb.Ping(); err != nil { return fmt.Errorf("auth db ping: %w", err) }
        row := adb.QueryRow("SELECT id FROM users WHERE email = $1 LIMIT 1", ownerEmail)
        if err := row.Scan(&ownerID); err != nil {
            return fmt.Errorf("owner email not found: %w", err)
        }
    }

    // Apply owner id to all videos
    if _, err := videoDB.Exec("UPDATE videos SET user_id = $1", ownerID); err != nil {
        return fmt.Errorf("update videos owner: %w", err)
    }
    log.Printf("Backfilled owner for all videos to user_id=%d", ownerID)
    return nil
}