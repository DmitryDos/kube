package handler

import (
    "net/http"
    "strconv"
    "video-service/internal/model"
    "video-service/internal/service"

    "github.com/gin-gonic/gin"
)

type VideoHandler struct {
    service *service.VideoService
}

func NewVideoHandler(service *service.VideoService) *VideoHandler {
    return &VideoHandler{service: service}
}

func (h *VideoHandler) UploadVideo(c *gin.Context) {
    // Получаем userID из middleware (позже добавим)
    userID := 1 // временно

    // Парсим форму
    if err := c.Request.ParseMultipartForm(100 << 20); err != nil { // 100MB
        c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
        return
    }

    // Получаем файл
    file, header, err := c.Request.FormFile("video")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Video file is required"})
        return
    }
    defer file.Close()

    // Валидация размера
    if header.Size > 500<<20 { // 500MB
        c.JSON(http.StatusBadRequest, gin.H{"error": "File too large"})
        return
    }

    // Получаем метаданные
    var req model.CreateVideoRequest
    if err := c.Bind(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
        return
    }

    // Создаем видео
    fileHeader := &model.FileHeader{
        File:     file,
        Filename: header.Filename,
        Size:     header.Size,
    }

    video, err := h.service.CreateVideo(userID, &req, fileHeader)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create video"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{
        "message": "Video uploaded successfully",
        "video": model.VideoResponse{
            ID:          video.ID,
            Title:       video.Title,
            Description: video.Description,
            FileSize:    video.FileSize,
            Status:      video.Status,
            CreatedAt:   video.CreatedAt,
        },
    })
}

func (h *VideoHandler) GetVideos(c *gin.Context) {
    userID := 1 // временно

    videos, err := h.service.GetUserVideos(userID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get videos"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"videos": videos})
}

func (h *VideoHandler) StreamVideo(c *gin.Context) {
    userID := 1 // временно

    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    video, err := h.service.GetVideo(userID, videoID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
        return
    }

    // Отдаем файл
    c.File(video.FilePath)
}