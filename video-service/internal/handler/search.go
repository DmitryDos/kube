// handler/search_handler.go
package handler

import (
	"log"
	"net/http"
	"strconv"
	"video-service/internal/model"
	"video-service/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SearchHandler struct {
	videoService *service.VideoService
	imageService *service.ImageService
}

func NewSearchHandler(videoService *service.VideoService, imageService *service.ImageService) *SearchHandler {
	return &SearchHandler{
		videoService: videoService,
		imageService: imageService,
	}
}

// SearchVideosAndAuthors возвращает объединенные результаты поиска
func (h *SearchHandler) SearchVideosAndAuthors(c *gin.Context) {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[SearchHandler] Panic recovered: %v", r)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		}
	}()

	q := c.DefaultQuery("q", "")
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "20")
	filter := c.DefaultQuery("filter", "all")

	log.Printf("[SearchHandler] Search request: q=%s, page=%s, limit=%s, filter=%s", q, pageStr, limitStr, filter)

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}

	// Вычисляем offset для пагинации
	offset := (page - 1) * limit

	// В зависимости от фильтра выполняем поиск
	var response gin.H

	switch filter {
	case "authors":
		// Только авторы
		authors, err := h.searchAuthors(q, limit, offset)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search authors"})
			return
		}
		response = gin.H{
			"results": authors,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": len(authors),
			},
		}

	case "videos":
		// Только видео (content_type = 'video' или пустой)
		var currentUserID *uuid.UUID
		if uid, ok := c.Get("userID"); ok {
			if v, ok2 := uid.(uuid.UUID); ok2 {
				currentUserID = &v
			}
		}
		allVideos, err := h.videoService.GetAllVideosPaginated(q, nil, currentUserID, page-1, limit*2)
		if err != nil {
			log.Printf("[SearchHandler] Error searching videos: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search videos"})
			return
		}

		// Фильтруем только видео
		var videos []model.VideoResponse
		for _, v := range allVideos {
			contentType := v.ContentType
			if contentType == "" || contentType == "video" {
				videos = append(videos, v)
			}
		}

		// Применяем пагинацию
		start := (page - 1) * limit
		end := start + limit
		if end > len(videos) {
			end = len(videos)
		}
		if start < len(videos) {
			videos = videos[start:end]
		} else {
			videos = []model.VideoResponse{}
		}

		videoResults := make([]gin.H, len(videos))
		for i, video := range videos {
			videoResults[i] = gin.H{
				"type": "video",
				"data": video,
			}
		}

		response = gin.H{
			"results": videoResults,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": len(videos),
			},
		}

	case "music":
		// Только музыка (content_type = 'audio')
		var currentUserID *uuid.UUID
		if uid, ok := c.Get("userID"); ok {
			if v, ok2 := uid.(uuid.UUID); ok2 {
				currentUserID = &v
			}
		}
		allVideos, err := h.videoService.GetAllVideosPaginated(q, nil, currentUserID, page-1, limit*2)
		if err != nil {
			log.Printf("[SearchHandler] Error searching music: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search music"})
			return
		}

		// Фильтруем только музыку
		var music []model.VideoResponse
		for _, v := range allVideos {
			if v.ContentType == "audio" {
				music = append(music, v)
			}
		}

		// Применяем пагинацию
		start := (page - 1) * limit
		end := start + limit
		if end > len(music) {
			end = len(music)
		}
		if start < len(music) {
			music = music[start:end]
		} else {
			music = []model.VideoResponse{}
		}

		musicResults := make([]gin.H, len(music))
		for i, track := range music {
			musicResults[i] = gin.H{
				"type": "music",
				"data": track,
			}
		}

		response = gin.H{
			"results": musicResults,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": len(music),
			},
		}

	case "photos":
		// Только фото - возвращаем как VideoResponse с thumbnail_url
		var currentUserID *uuid.UUID
		if uid, ok := c.Get("userID"); ok {
			if v, ok2 := uid.(uuid.UUID); ok2 {
				currentUserID = &v
			}
		}
		images, err := h.imageService.GetAllImagesPaginated(q, nil, currentUserID, page-1, limit)
		if err != nil {
			log.Printf("[SearchHandler] Error searching photos: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search photos"})
			return
		}

		// Конвертируем ImageResponse в VideoResponse
		photoResults := make([]gin.H, len(images))
		for i, img := range images {
			videoResponse := model.VideoResponse{
				ID:           img.ID,
				Title:        img.Title,
				Description:  img.Description,
				UserID:       img.UserID,
				FileSize:     img.FileSize,
				FileURL:      "", // Фото не имеют file_url
				ThumbnailURL: img.ImageURL, // Используем image_url как thumbnail_url
				Status:       img.Status,
				Duration:     0, // Фото не имеют duration
				ContentType:  "image",
				IsPrivate:    img.IsPrivate,
				CreatedAt:    img.CreatedAt,
			}
			photoResults[i] = gin.H{
				"type": "photo",
				"data": videoResponse,
			}
		}

		response = gin.H{
			"results": photoResults,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": len(images),
			},
		}

	default:
		// По умолчанию возвращаем только видео (для обратной совместимости)
		var currentUserID *uuid.UUID
		if uid, ok := c.Get("userID"); ok {
			if v, ok2 := uid.(uuid.UUID); ok2 {
				currentUserID = &v
			}
		}
		videos, err := h.videoService.GetAllVideosPaginated(q, nil, currentUserID, page-1, limit)
		if err != nil {
			log.Printf("[SearchHandler] Error searching videos: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search videos"})
			return
		}

		// Фильтруем только видео (не музыку)
		var videoResults []model.VideoResponse
		for _, v := range videos {
			contentType := v.ContentType
			if contentType == "" || contentType == "video" {
				videoResults = append(videoResults, v)
			}
		}

		results := make([]gin.H, len(videoResults))
		for i, video := range videoResults {
			results[i] = gin.H{
				"type": "video",
				"data": video,
			}
		}

		response = gin.H{
			"results": results,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": len(videoResults),
			},
		}
	}

	c.JSON(http.StatusOK, response)
}

// searchAuthors - поиск авторов (нужно реализовать)
func (h *SearchHandler) searchAuthors(query string, limit, offset int) ([]gin.H, error) {
	// TODO: Реализовать поиск авторов из базы данных
	// Пока возвращаем пустой массив
	return []gin.H{}, nil
}