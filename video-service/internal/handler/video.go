package handler

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
    "strconv"
	"video-service/internal/model"
	"video-service/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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
	userIDUUID, ok := userID.(uuid.UUID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID type"})
		return
	}

	if err := c.Request.ParseMultipartForm(500 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
		return
	}

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

	fileHeader := &model.FileHeader{
		File:     file,
		Filename: header.Filename,
		Size:     header.Size,
	}

	video, err := h.service.CreateVideoFile(userIDUUID, fileHeader)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload video"})
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
		"message": "Video uploaded successfully",
		"video": model.VideoResponse{
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

func (h *VideoHandler) UploadVideoRaw(c *gin.Context) {
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

	contentType := c.GetHeader("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	video, err := h.service.CreateVideoStream(userIDUUID, c.Request.Body, "video", -1, contentType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create video"})
		return
	}

	c.Writer.Header().Add("X-Uploaded-Video-ID", video.ID.String())

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
		"message": "Video uploaded successfully",
		"video": model.VideoResponse{
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

func (h *VideoHandler) GetVideos(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
		return
	}
	userIDUUID := userID.(uuid.UUID)

	pageStr := c.DefaultQuery("page", "0")
	limitStr := c.DefaultQuery("limit", "0")
	
	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)
	
	videos, err := h.service.GetUserVideosPaginated(userIDUUID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get videos"})
		return
	}

	c.Writer.Header().Add("X-Videos-Count", strconv.Itoa(len(videos)))
	c.JSON(http.StatusOK, gin.H{"videos": videos})
}

func (h *VideoHandler) SearchAllVideos(c *gin.Context) {
	if _, exists := c.Get("userID"); !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
		return
	}

	pageStr := c.DefaultQuery("page", "0")
	limitStr := c.DefaultQuery("limit", "20")
	q := c.DefaultQuery("q", "")
	userIDStr := c.DefaultQuery("user_id", "")
	mine := c.DefaultQuery("mine", "false")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)
	var filterUserID *uuid.UUID
	var currentUserID *uuid.UUID
	
	if uid, ok := c.Get("userID"); ok {
		if v, ok2 := uid.(uuid.UUID); ok2 {
			currentUserID = &v
			if mine == "true" {
				filterUserID = &v
			}
		}
	}
	
	if mine != "true" && userIDStr != "" {
		if v, err := uuid.Parse(userIDStr); err == nil {
			filterUserID = &v
		}
	}

	videos, err := h.service.GetAllVideosPaginated(q, filterUserID, currentUserID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search videos"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"videos": videos})
}



// StreamVideo - стриминг только для видео
func (h *VideoHandler) StreamVideo(c *gin.Context) {
	video, err := getVideoByID(h.service, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
		return
	}

	if video == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
		return
	}

	// Проверяем, что это действительно видео
	if video.ContentType != "" && video.ContentType != "video" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Not a video file"})
		return
	}

	rangeHeader := c.GetHeader("Range")
	var start, end int64 = 0, -1
	hasRange := false

	if rangeHeader != "" {
		re := regexp.MustCompile(`bytes=(\d+)-(\d*)`)
		matches := re.FindStringSubmatch(rangeHeader)
		if len(matches) == 3 {
			start, _ = strconv.ParseInt(matches[1], 10, 64)
			if matches[2] != "" {
				end, _ = strconv.ParseInt(matches[2], 10, 64)
			}
			hasRange = true
		}
	}

	ctx := c.Request.Context()
	totalSize, contentType, err := h.service.StatObject(ctx, video.FilePath)
	if err != nil {
		log.Printf("[StreamVideo] Failed to stat object: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get video info"})
		return
	}

	// Определяем Content-Type для видео
	if contentType == "" || contentType == "application/octet-stream" {
		if len(video.FilePath) > 4 {
			ext := video.FilePath[len(video.FilePath)-4:]
			switch ext {
			case ".mp4":
				contentType = "video/mp4"
			case ".mov":
				contentType = "video/quicktime"
			case ".mkv":
				contentType = "video/x-matroska"
			case ".m4v":
				contentType = "video/x-m4v"
			default:
				contentType = "video/mp4"
			}
		} else {
			contentType = "video/mp4"
		}
	}

	if end < 0 || end >= totalSize {
		end = totalSize - 1
	}

	obj, err := h.service.GetObjectRange(ctx, video.FilePath, start, end)
	if err != nil {
		log.Printf("[StreamVideo] Failed to get object range: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to stream video"})
		return
	}
	defer obj.Close()

	c.Header("Accept-Ranges", "bytes")
	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "no-cache")

	if hasRange {
		var contentLen int64
		if end >= 0 {
			contentLen = end - start + 1
			c.Header("Content-Range", fmt.Sprintf("bytes %d-%d/%d", start, end, totalSize))
		} else {
			contentLen = totalSize - start
			c.Header("Content-Range", fmt.Sprintf("bytes %d-%d/%d", start, totalSize-1, totalSize))
		}
		c.Header("Content-Length", strconv.FormatInt(contentLen, 10))
		c.Status(http.StatusPartialContent)
	} else {
		c.Header("Content-Length", strconv.FormatInt(totalSize, 10))
		c.Status(http.StatusOK)
	}

	if _, err := io.Copy(c.Writer, obj); err != nil {
		log.Printf("[StreamVideo] Error copying data: %v", err)
		return
	}
}

// GetThumbnail - универсальная утилита для получения thumbnail
func (h *VideoHandler) GetThumbnail(c *gin.Context) {
	video, err := getVideoByID(h.service, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
		return
	}

	if video == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
		return
	}

	if !video.ThumbnailPath.Valid || video.ThumbnailPath.String == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Thumbnail not found"})
		return
	}

	ctx := c.Request.Context()
	totalSize, contentType, err := h.service.StatObject(ctx, video.ThumbnailPath.String)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get thumbnail info"})
		return
	}

	obj, err := h.service.GetObjectRange(ctx, video.ThumbnailPath.String, 0, -1)
	if err != nil {
		log.Printf("[GetThumbnail] Error getting object: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get thumbnail"})
		return
	}
	defer obj.Close()

	if contentType == "" {
		contentType = "image/jpeg"
	}
	
	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "public, max-age=3600")
	c.Header("Content-Length", strconv.FormatInt(totalSize, 10))
	
	if _, err := io.Copy(c.Writer, obj); err != nil {
		log.Printf("[GetThumbnail] Error copying data: %v", err)
		return
	}
}

func (h *VideoHandler) DeleteVideo(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists { 
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
		return 
	}
	userIDUUID := userID.(uuid.UUID)
	
	videoID, err := uuid.Parse(c.Param("id"))
	if err != nil { 
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
		return 
	}
	
	if err := h.service.DeleteVideo(userIDUUID, videoID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete video"})
		return
	}
	c.Status(http.StatusNoContent)
}