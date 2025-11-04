package handler

import (
    "fmt"
    "net/http"
    "strconv"
    "video-service/internal/model"

    "github.com/gin-gonic/gin"
)

// UpdateVideoMetadata updates video metadata (title, description, thumbnail)
// Supports both JSON (for title/description) and multipart/form-data (for thumbnail)
func (h *VideoHandler) UpdateVideoMetadata(c *gin.Context) {
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

    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    contentType := c.GetHeader("Content-Type")
    if contentType == "" {
        contentType = "application/json"
    }

    var req model.UpdateVideoMetadataRequest

    if len(contentType) >= 19 && contentType[:19] == "multipart/form-data" {
        if err := c.Request.ParseMultipartForm(10 << 20); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
            return
        }

        if title := c.PostForm("title"); title != "" {
            req.Title = &title
        }
        if description := c.PostForm("description"); description != "" {
            req.Description = &description
        }

        if thumbnailFile, thumbnailFileHeader, err := c.Request.FormFile("thumbnail"); err == nil {
            defer thumbnailFile.Close()
            if thumbnailFileHeader.Size > 10<<20 {
                c.JSON(http.StatusBadRequest, gin.H{"error": "Thumbnail file too large (max 10MB)"})
                return
            }

            fileHeader := &model.FileHeader{
                File:     thumbnailFile,  // thumbnailFile уже имеет тип multipart.File
                Filename: thumbnailFileHeader.Filename,
                Size:     thumbnailFileHeader.Size,
            }

                if err := h.service.UpdateVideoThumbnail(userIDInt, videoID, fileHeader); err != nil {
                    c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update thumbnail"})
                    return
                }
        }

        if req.Title != nil || req.Description != nil {
            if err := h.service.UpdateVideoMetadata(userIDInt, videoID, &req); err != nil {
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update metadata"})
                return
            }
        }

        // Получаем обновленное видео для ответа
        video, err := h.service.GetVideo(userIDInt, videoID)
        if err != nil {
            c.JSON(http.StatusOK, gin.H{"message": "Video metadata updated successfully"})
            return
        }

        ctx := c.Request.Context()
        fileURL, _ := h.service.GetVideoStreamURL(ctx, video.FilePath)
        var thumbnailURL string
        if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
            thumbnailURL = fmt.Sprintf("/api/videos/%d/thumbnail", videoID)
        }

        c.JSON(http.StatusOK, gin.H{
            "message": "Video metadata updated successfully",
            "video": model.VideoResponse{
                ID:           video.ID,
                Title:        video.Title,
                Description:  video.Description,
                UserID:       video.UserID,
                FileSize:     video.FileSize,
                FileURL:      fileURL,
                ThumbnailURL: thumbnailURL,
                Status:       video.Status,
                CreatedAt:    video.CreatedAt,
            },
        })
        return
    }

    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
        return
    }

    if err := h.service.UpdateVideoMetadata(userIDInt, videoID, &req); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update metadata"})
        return
    }

    // Получаем обновленное видео для ответа
    video, err := h.service.GetVideo(userIDInt, videoID)
    if err != nil {
        c.JSON(http.StatusOK, gin.H{"message": "Video metadata updated successfully"})
        return
    }

    ctx := c.Request.Context()
    fileURL, _ := h.service.GetVideoStreamURL(ctx, video.FilePath)
    var thumbnailURL string
    if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
        thumbnailURL, _ = h.service.GetVideoStreamURL(ctx, video.ThumbnailPath.String)
    }

    c.JSON(http.StatusOK, gin.H{
        "message": "Video metadata updated successfully",
        "video": model.VideoResponse{
            ID:           video.ID,
            Title:        video.Title,
            Description:  video.Description,
            UserID:       video.UserID,
            FileSize:     video.FileSize,
            FileURL:      fileURL,
            ThumbnailURL: thumbnailURL,
            Status:       video.Status,
            CreatedAt:    video.CreatedAt,
        },
    })
}
