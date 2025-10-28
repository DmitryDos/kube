package service

import (
    "context"
    "crypto/md5"
    "encoding/hex"
    "errors"
    "fmt"
    "io"
    "os"
    "path/filepath"
    "time"
    "video-service/internal/model"
    "video-service/internal/repository"
    "video-service/internal/storage"
)

type VideoService struct {
    repo    *repository.VideoRepository
    storage *storage.MinIOClient
}

func NewVideoService(repo *repository.VideoRepository, storage *storage.MinIOClient) *VideoService {
    return &VideoService{repo: repo, storage: storage}
}

func (s *VideoService) CreateVideo(userID int, req *model.CreateVideoRequest, fileHeader *model.FileHeader) (*model.Video, error) {
    // Создаем временный файл
    tempDir := filepath.Join("temp", fmt.Sprintf("%d", userID))
    if err := os.MkdirAll(tempDir, 0755); err != nil {
        return nil, err
    }

    // Генерируем уникальное имя файла
    hash := md5.Sum([]byte(fmt.Sprintf("%d_%s_%d", userID, fileHeader.Filename, time.Now().UnixNano())))
    fileName := hex.EncodeToString(hash[:]) + filepath.Ext(fileHeader.Filename)
    tempFilePath := filepath.Join(tempDir, fileName)

    // Сохраняем во временный файл
    tempFile, err := os.Create(tempFilePath)
    if err != nil {
        return nil, err
    }
    defer tempFile.Close()

    if _, err := io.Copy(tempFile, fileHeader.File); err != nil {
        return nil, err
    }

    // Загружаем в MinIO
    ctx := context.Background()
    objectName := fmt.Sprintf("user-%d/%s", userID, fileName)
    if err := s.storage.UploadFile(ctx, objectName, tempFilePath, fileHeader.Size); err != nil {
        os.Remove(tempFilePath)
        return nil, err
    }

    // Создаем запись в БД
    video := &model.Video{
        Title:       req.Title,
        Description: req.Description,
        FilePath:    objectName, // Теперь это путь в MinIO
        FileName:    fileName,
        FileSize:    fileHeader.Size,
        UserID:      userID,
        Status:      "ready",
    }

    if err := s.repo.Create(video); err != nil {
        // TODO: Удалить файл из MinIO при ошибке
        os.Remove(tempFilePath)
        return nil, err
    }

    // Удаляем временный файл
    os.Remove(tempFilePath)

    return video, nil
}

func (s *VideoService) GetUserVideos(userID int) ([]model.VideoResponse, error) {
    videos, err := s.repo.FindByUserID(userID)
    if err != nil {
        return nil, err
    }

    var response []model.VideoResponse
    ctx := context.Background()

    for _, video := range videos {
        // Генерируем presigned URL для каждого видео
        fileURL, err := s.storage.GeneratePresignedURL(ctx, video.FilePath)
        if err != nil {
            fileURL = "" // или логируем ошибку
        }

        response = append(response, model.VideoResponse{
            ID:          video.ID,
            Title:       video.Title,
            Description: video.Description,
            FileName:    video.FileName,
            FileSize:    video.FileSize,
            FileURL:     fileURL,
            Status:      video.Status,
            CreatedAt:   video.CreatedAt,
        })
    }

    return response, nil
}

func (s *VideoService) GetVideo(userID, videoID int) (*model.Video, error) {
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return nil, err
    }

    if video.UserID != userID {
        return nil, errors.New("video not found")
    }

    return video, nil
}