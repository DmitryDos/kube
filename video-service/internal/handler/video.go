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

func (h *VideoHandler) StreamVideo(c *gin.Context) {
	videoID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
		return
	}

	video, err := h.service.GetVideoPublic(videoID)
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

func (h *VideoHandler) GetStreamURL(c *gin.Context) {
	videoID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
		return
	}

	video, err := h.service.GetVideoPublic(videoID)
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

	c.JSON(http.StatusOK, gin.H{"url": presignedURL})
}

func (h *VideoHandler) StreamVideoProxy(c *gin.Context) {
	idParam := c.Param("id")
	log.Printf("[StreamVideoProxy] Received ID param: %s", idParam)
	videoID, err := uuid.Parse(idParam)
	if err != nil {
		log.Printf("[StreamVideoProxy] Failed to parse UUID: %v, param: %s", err, idParam)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
		return
	}

	log.Printf("[StreamVideoProxy] Parsed UUID: %s", videoID.String())
	video, err := h.service.GetVideoPublic(videoID)
	if err != nil {
		log.Printf("[StreamVideoProxy] Video not found: %v, UUID: %s", err, videoID.String())
		c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
		return
	}
	log.Printf("[StreamVideoProxy] Found video: %s, file_path: %s", video.ID.String(), video.FilePath)

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
		log.Printf("[StreamVideoProxy] Failed to stat object: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get video info"})
		return
	}

	// Убеждаемся, что Content-Type правильный для видео
	if contentType == "" || contentType == "application/octet-stream" {
		// Определяем Content-Type по расширению файла
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
				contentType = "video/mp4" // По умолчанию mp4
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
		log.Printf("[StreamVideoProxy] Failed to get object range: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to stream video"})
		return
	}
	defer obj.Close()

	// Всегда устанавливаем Accept-Ranges, чтобы AVPlayer знал, что сервер поддерживает Range requests
	c.Header("Accept-Ranges", "bytes")
	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "no-cache")

	if hasRange {
		// Range request - возвращаем 206 Partial Content
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
		log.Printf("[StreamVideoProxy] Sending partial content: bytes %d-%d/%d (Content-Length: %d)", start, end, totalSize, contentLen)
	} else {
		// Первый запрос без Range - возвращаем весь файл, но с правильными заголовками
		c.Header("Content-Length", strconv.FormatInt(totalSize, 10))
		c.Status(http.StatusOK)
		log.Printf("[StreamVideoProxy] Sending full content: size %d, Content-Type: %s", totalSize, contentType)
	}

	if _, err := io.Copy(c.Writer, obj); err != nil {
		log.Printf("[StreamVideoProxy] Error copying data: %v", err)
		return
	}
}

func (h *VideoHandler) GetThumbnail(c *gin.Context) {
	idParam := c.Param("id")
	log.Printf("[GetThumbnail] Received ID param: %s", idParam)
	videoID, err := uuid.Parse(idParam)
	if err != nil {
		log.Printf("[GetThumbnail] Failed to parse UUID: %v, param: %s", err, idParam)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
		return
	}

	log.Printf("[GetThumbnail] Parsed UUID: %s", videoID.String())
	video, err := h.service.GetVideoPublic(videoID)
	if err != nil {
		log.Printf("[GetThumbnail] Video not found: %v, UUID: %s", err, videoID.String())
		c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
		return
	}
	log.Printf("[GetThumbnail] Found video: %s, thumbnail_path: %v", video.ID.String(), video.ThumbnailPath)

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

	log.Printf("[GetThumbnail] Video ID: %s, Path: %s, Size: %d, ContentType: %s", videoID, video.ThumbnailPath.String, totalSize, contentType)

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
	
	bytesWritten, err := io.Copy(c.Writer, obj)
	if err != nil {
		log.Printf("[GetThumbnail] Error copying data: %v, bytes written: %d", err, bytesWritten)
		return
	}
	log.Printf("[GetThumbnail] Successfully sent %d bytes", bytesWritten)
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