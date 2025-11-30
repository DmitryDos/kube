package handler

import (
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"
	"video-service/internal/model"
	"video-service/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MediaHandler struct {
	videoService *service.VideoService
}

func NewMediaHandler(videoService *service.VideoService, imageService *service.ImageService) *MediaHandler {
	return &MediaHandler{
		videoService: videoService,
	}
}

func (h *MediaHandler) UploadAudio(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
		return
	}
	userIDUUID, ok := userID.(uuid.UUID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID type"})
		return
	}

	if err := c.Request.ParseMultipartForm(500 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
		return
	}

	file, header, err := c.Request.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Audio file is required"})
		return
	}
	defer file.Close()

	if header.Size > 500<<20 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File too large"})
		return
	}

	fileHeader := &model.FileHeader{
		File:     file,
		Filename: header.Filename,
		Size:     header.Size,
	}

	video, err := h.videoService.CreateAudioFile(userIDUUID, fileHeader)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload audio"})
		return
	}

	var fileURL string
	if video.FilePath != "" {
		fileURL = fmt.Sprintf("/api/videos/%s/stream", video.ID.String())
	}

	var thumbnailURL string
	if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
		thumbnailURL = fmt.Sprintf("/api/videos/%s/thumbnail", video.ID.String())
	}

	var duration float64
	if video.Duration.Valid {
		duration = video.Duration.Float64
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Audio uploaded successfully",
		"music": model.VideoResponse{
			ID:           video.ID,
			Title:        video.Title,
			Description:  video.Description,
			UserID:       video.UserID,
			FileSize:     video.FileSize,
			FileURL:      fileURL,
			ThumbnailURL: thumbnailURL,
			Status:       video.Status,
			Duration:     duration,
			IsPrivate:    video.IsPrivate,
			CreatedAt:    video.CreatedAt,
		},
	})
}

func (h *MediaHandler) UploadPhoto(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
		return
	}
	userIDUUID, ok := userID.(uuid.UUID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID type"})
		return
	}

	if err := c.Request.ParseMultipartForm(100 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
		return
	}

	file, header, err := c.Request.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Image file is required"})
		return
	}
	defer file.Close()

	if header.Size > 100<<20 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File too large"})
		return
	}

	fileHeader := &model.FileHeader{
		File:     file,
		Filename: header.Filename,
		Size:     header.Size,
	}

	video, err := h.videoService.CreateImageFile(userIDUUID, fileHeader)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to upload photo: %v", err)})
		return
	}

	var thumbnailURL string
	if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
		thumbnailURL = fmt.Sprintf("/api/videos/%s/thumbnail", video.ID.String())
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Photo uploaded successfully",
		"photo": model.VideoResponse{
			ID:           video.ID,
			Title:        video.Title,
			Description:  video.Description,
			UserID:       video.UserID,
			FileSize:     video.FileSize,
			FileURL:      "", // Фото не имеют file_url
			ThumbnailURL: thumbnailURL,
			Status:       video.Status,
			Duration:     0, // Фото не имеют duration
			ContentType:  "image",
			IsPrivate:    video.IsPrivate,
			CreatedAt:    video.CreatedAt,
		},
	})
}

func (h *MediaHandler) UpdatePhotoMetadata(c *gin.Context) {
	photoIDStr := c.Param("id")
	photoID, err := uuid.Parse(photoIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid photo ID"})
		return
	}

	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}
	userIDUUID := userID.(uuid.UUID)

	video, err := h.videoService.GetVideoPublic(photoID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Photo not found"})
		return
	}

	if video.ContentType != "image" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Not a photo"})
		return
	}

	if video.UserID != userIDUUID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	var req model.UpdateVideoMetadataRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.videoService.UpdateVideoMetadata(userIDUUID, photoID, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update metadata"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Metadata updated successfully"})
}

