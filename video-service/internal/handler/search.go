// handler/search_handler.go
package handler

import (
	"log"
	"net/http"
	"strconv"
	"video-service/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SearchHandler struct {
	videoService *service.VideoService
}

func NewSearchHandler(videoService *service.VideoService) *SearchHandler {
	return &SearchHandler{videoService: videoService}
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
		// Только видео
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

		videoResults := make([]gin.H, len(videos))
		for i, video := range videos {
			videoResults[i] = gin.H{
				"type":  "video",
				"data":  video,
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

	default:
		// Все результаты (и видео, и авторы)
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

		authorLimit := limit / 2
		if authorLimit < 1 {
			authorLimit = 1
		}
		authorOffset := offset / 2
		authors, err := h.searchAuthors(q, authorLimit, authorOffset) // Делим лимит между типами
		if err != nil {
			log.Printf("[SearchHandler] Error searching authors: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search authors"})
			return
		}

		// Собираем все результаты в один массив
		allResults := make([]gin.H, 0, len(videos)+len(authors))

		// Добавляем видео
		for _, video := range videos {
			allResults = append(allResults, gin.H{
				"type": "video",
				"data": video,
			})
		}

		// Добавляем авторов
		for _, author := range authors {
			allResults = append(allResults, gin.H{
				"type": "author",
				"data": author,
			})
		}

		response = gin.H{
			"results": allResults,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": len(allResults),
			},
		}
	}

	c.JSON(http.StatusOK, response)
}

// searchAuthors - заглушка для поиска авторов (нужно реализовать)
func (h *SearchHandler) searchAuthors(query string, limit, offset int) ([]gin.H, error) {
	// TODO: Реализовать поиск авторов из базы данных
	// Пока возвращаем заглушку

	authors := []gin.H{
		{
			"id":           "1",
			"title":        "Иван Иванов",
			"subtitle":     "Создатель образовательного контента",
			"imageURL":     "https://example.com/avatar1.jpg",
			"videoCount":   42,
			"followerCount": 1500,
		},
		{
			"id":           "2",
			"title":        "Мария Петрова",
			"subtitle":     "Эксперт в дизайне интерфейсов",
			"imageURL":     "https://example.com/avatar2.jpg",
			"videoCount":   28,
			"followerCount": 890,
		},
	}

	// Фильтрация по query если есть
	if query != "" {
		filtered := make([]gin.H, 0)
		for _, author := range authors {
			if name, ok := author["title"].(string); ok {
				if containsIgnoreCase(name, query) {
					filtered = append(filtered, author)
				}
			}
		}
		return filtered, nil
	}

	return authors, nil
}

// Вспомогательная функция для поиска без учета регистра
func containsIgnoreCase(s, substr string) bool {
	// Простая реализация - в продакшене используйте strings.Contains с strings.ToLower
	return len(s) >= len(substr)
}