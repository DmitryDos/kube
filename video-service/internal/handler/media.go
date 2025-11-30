package handler

import (
	"fmt"
	"net/http"
	"time"
	"video-service/internal/model"
	"video-service/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MediaHandler struct {
	videoService *service.VideoService
	imageService *service.ImageService
}

func NewMediaHandler(videoService *service.VideoService, imageService *service.ImageService) *MediaHandler {
	return &MediaHandler{
		videoService: videoService,
		imageService: imageService,
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

	ctx := c.Request.Context()
	presignedURL, err := h.videoService.GetVideoStreamURL(ctx, video.FilePath)
	if err != nil {
		h.videoService.DeleteVideo(userIDUUID, video.ID)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate stream URL"})
		return
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
			FileURL:      presignedURL,
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

	image, err := h.imageService.CreateImageFile(userIDUUID, fileHeader)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to upload photo: %v", err)})
		return
	}

	ctx := c.Request.Context()
	presignedURL, err := h.imageService.GetImageStreamURL(ctx, image.ImagePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate stream URL"})
		return
	}

	var title string
	if image.Title.Valid {
		title = image.Title.String
	}

	var author string
	if image.Author.Valid {
		author = image.Author.String
	}

	var description string
	if image.Description.Valid {
		description = image.Description.String
	}

	var publishedDate *time.Time
	if image.PublishedDate.Valid {
		publishedDate = &image.PublishedDate.Time
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Photo uploaded successfully",
		"photo": model.ImageResponse{
			ID:            image.ID,
			Title:         title,
			ImageURL:      presignedURL,
			Width:         image.Width,
			Height:        image.Height,
			UserID:        image.UserID,
			FileSize:      image.FileSize,
			Author:        author,
			Description:   description,
			Tags:          []string(image.Tags),
			Status:        image.Status,
			IsPrivate:     image.IsPrivate,
			PublishedDate: publishedDate,
			CreatedAt:     image.CreatedAt,
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

	image, err := h.imageService.GetImageByID(photoID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Photo not found"})
		return
	}

	if image.UserID != userIDUUID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	var req model.UpdateImageMetadataRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.imageService.UpdateMetadata(photoID, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update metadata"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Metadata updated successfully"})
}

