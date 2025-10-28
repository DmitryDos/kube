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
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt, ok := userID.(int)
    if !ok {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID type"})
        return
    }

    if err := c.Request.ParseMultipartForm(100 << 20); err != nil {
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

    if header.Size > 500<<20 {
        c.JSON(http.StatusBadRequest, gin.H{"error": "File too large"})
        return
    }

    title := c.PostForm("title")
    description := c.PostForm("description")
    
    if title == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
        return
    }

    req := model.CreateVideoRequest{
        Title:       title,
        Description: description,
    }

    fileHeader := &model.FileHeader{
        File:     file,
        Filename: header.Filename,
        Size:     header.Size,
    }

    video, err := h.service.CreateVideo(userIDInt, &req, fileHeader)
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
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt := userID.(int)

    // Получаем параметры пагинации
    pageStr := c.DefaultQuery("page", "0")
    limitStr := c.DefaultQuery("limit", "0")
    
    page, _ := strconv.Atoi(pageStr)
    limit, _ := strconv.Atoi(limitStr)
    
    // Если limit не указан, возвращаем все видео
    videos, err := h.service.GetUserVideosPaginated(userIDInt, page, limit)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get videos"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"videos": videos})
}

func (h *VideoHandler) StreamVideo(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt := userID.(int)

    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    video, err := h.service.GetVideo(userIDInt, videoID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
        return
    }

    ctx := c.Request.Context()
    presignedURL, err := h.service.GetVideoStreamURL(ctx, video.FilePath)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate stream URL"})
        return
    }

    c.Redirect(http.StatusTemporaryRedirect, presignedURL)
}