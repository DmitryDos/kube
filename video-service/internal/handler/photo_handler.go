package handler

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"video-service/internal/service"

	"github.com/gin-gonic/gin"
)

type PhotoHandler struct {
	service *service.VideoService
}

func NewPhotoHandler(service *service.VideoService) *PhotoHandler {
	return &PhotoHandler{service: service}
}

// GetPhoto - получение фото
func (h *PhotoHandler) GetPhoto(c *gin.Context) {
	video, err := getVideoByID(h.service, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid photo ID"})
		return
	}

	if video == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Photo not found"})
		return
	}

	// Проверяем, что это действительно фото
	if video.ContentType != "image" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Not a photo file"})
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
		log.Printf("[GetPhoto] Failed to stat object: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get photo info"})
		return
	}

	// Определяем Content-Type для изображений
	if contentType == "" || contentType == "application/octet-stream" {
		if len(video.FilePath) > 4 {
			ext := video.FilePath[len(video.FilePath)-4:]
			switch ext {
			case ".jpg", "jpeg":
				contentType = "image/jpeg"
			case ".png":
				contentType = "image/png"
			case ".gif":
				contentType = "image/gif"
			case ".webp":
				contentType = "image/webp"
			case ".tiff", ".tif":
				contentType = "image/tiff"
			default:
				contentType = "image/jpeg"
			}
		} else {
			contentType = "image/jpeg"
		}
	}

	if end < 0 || end >= totalSize {
		end = totalSize - 1
	}

	obj, err := h.service.GetObjectRange(ctx, video.FilePath, start, end)
	if err != nil {
		log.Printf("[GetPhoto] Failed to get object range: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get photo"})
		return
	}
	defer obj.Close()

	c.Header("Accept-Ranges", "bytes")
	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "public, max-age=3600")

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
		log.Printf("[GetPhoto] Error copying data: %v", err)
		return
	}
}

