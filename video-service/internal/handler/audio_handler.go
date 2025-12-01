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

type AudioHandler struct {
	service *service.VideoService
}

func NewAudioHandler(service *service.VideoService) *AudioHandler {
	return &AudioHandler{service: service}
}

// StreamAudio - стриминг только для аудио
func (h *AudioHandler) StreamAudio(c *gin.Context) {
	video, err := getVideoByID(h.service, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid audio ID"})
		return
	}

	if video == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Audio not found"})
		return
	}

	// Проверяем, что это действительно аудио
	if video.ContentType != "audio" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Not an audio file"})
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
		log.Printf("[StreamAudio] Failed to stat object: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get audio info"})
		return
	}

	// Определяем Content-Type для аудио
	if contentType == "" || contentType == "application/octet-stream" {
		if len(video.FilePath) > 4 {
			ext := video.FilePath[len(video.FilePath)-4:]
			switch ext {
			case ".mp3":
				contentType = "audio/mpeg"
			case ".m4a":
				contentType = "audio/mp4"
			case ".aac":
				contentType = "audio/aac"
			case ".flac":
				contentType = "audio/flac"
			case ".wav":
				contentType = "audio/wav"
			case ".ogg":
				contentType = "audio/ogg"
			default:
				contentType = "audio/mpeg"
			}
		} else {
			contentType = "audio/mpeg"
		}
	}

	if end < 0 || end >= totalSize {
		end = totalSize - 1
	}

	obj, err := h.service.GetObjectRange(ctx, video.FilePath, start, end)
	if err != nil {
		log.Printf("[StreamAudio] Failed to get object range: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to stream audio"})
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
		log.Printf("[StreamAudio] Error copying data: %v", err)
		return
	}
}

