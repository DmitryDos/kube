package handler

import (
	"video-service/internal/model"
	"video-service/internal/service"

	"github.com/google/uuid"
)

// getVideoByID - утилита для получения video по ID
func getVideoByID(service *service.VideoService, idParam string) (*model.Video, error) {
	videoID, err := uuid.Parse(idParam)
	if err != nil {
		return nil, err
	}
	return service.GetVideoPublic(videoID)
}

