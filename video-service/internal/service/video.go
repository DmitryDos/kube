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

func (s *VideoService) CreateVideoFile(userID int, fileHeader *model.FileHeader) (*model.Video, error) {
    tempDir := filepath.Join("temp", fmt.Sprintf("%d", userID))
    if err := os.MkdirAll(tempDir, 0755); err != nil {
        return nil, err
    }

    hash := md5.Sum([]byte(fmt.Sprintf("%d_%s_%d", userID, fileHeader.Filename, time.Now().UnixNano())))
    fileName := hex.EncodeToString(hash[:]) + filepath.Ext(fileHeader.Filename)
    tempFilePath := filepath.Join(tempDir, fileName)

    tempFile, err := os.Create(tempFilePath)
    if err != nil {
        return nil, err
    }
    defer tempFile.Close()

    if _, err := io.Copy(tempFile, fileHeader.File); err != nil {
        return nil, err
    }

    ctx := context.Background()
    objectName := fmt.Sprintf("user-%d/%s", userID, fileName)
    if err := s.storage.UploadFile(ctx, objectName, tempFilePath, fileHeader.Size); err != nil {
        os.Remove(tempFilePath)
        return nil, err
    }

    video := &model.Video{
        Title:        "",
        Description:  "",
        FilePath:     objectName,
        FileSize:     fileHeader.Size,
        ThumbnailPath: "",
        UserID:       userID,
        Status:       "ready",
    }

    if err := s.repo.Create(video); err != nil {
        ctx := context.Background()
        s.storage.DeleteFile(ctx, objectName)
        os.Remove(tempFilePath)
        return nil, err
    }

    os.Remove(tempFilePath)

    return video, nil
}

func (s *VideoService) GetUserVideos(userID int) ([]model.VideoResponse, error) {
    return s.GetUserVideosPaginated(userID, 0, 0)
}

func (s *VideoService) GetUserVideosPaginated(userID, page, pageSize int) ([]model.VideoResponse, error) {
    videos, err := s.repo.FindByUserIDPaginated(userID, page, pageSize)
    if err != nil {
        return nil, err
    }

    var response []model.VideoResponse
    ctx := context.Background()

    for _, video := range videos {
        fileURL, err := s.storage.GeneratePresignedURL(ctx, video.FilePath)
        if err != nil {
            fileURL = ""
        }

        var thumbnailURL string
        if video.ThumbnailPath != "" {
            thumbnailURL, _ = s.storage.GeneratePresignedURL(ctx, video.ThumbnailPath)
        }

        response = append(response, model.VideoResponse{
            ID:           video.ID,
            Title:        video.Title,
            Description:  video.Description,
            UserID:       video.UserID,
            FileSize:     video.FileSize,
            FileURL:      fileURL,
            ThumbnailURL: thumbnailURL,
            Status:       video.Status,
            CreatedAt:    video.CreatedAt,
        })
    }

    return response, nil
}

// GetAllVideosPaginated returns all videos (across users) with optional search query, optional user filter, and pagination
func (s *VideoService) GetAllVideosPaginated(query string, userID *int, page, pageSize int) ([]model.VideoResponse, error) {
    videos, err := s.repo.FindAllPaginatedWithSearch(query, userID, page, pageSize)
    if err != nil {
        return nil, err
    }

    var response []model.VideoResponse
    ctx := context.Background()

    for _, video := range videos {
        fileURL, err := s.storage.GeneratePresignedURL(ctx, video.FilePath)
        if err != nil {
            fileURL = ""
        }

        var thumbnailURL string
        if video.ThumbnailPath != "" {
            thumbnailURL, _ = s.storage.GeneratePresignedURL(ctx, video.ThumbnailPath)
        }

        response = append(response, model.VideoResponse{
            ID:           video.ID,
            Title:        video.Title,
            Description:  video.Description,
            UserID:       video.UserID,
            FileSize:     video.FileSize,
            FileURL:      fileURL,
            ThumbnailURL: thumbnailURL,
            Status:       video.Status,
            CreatedAt:    video.CreatedAt,
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

// GetVideoPublic returns video by id without ownership check (for streaming)
func (s *VideoService) GetVideoPublic(videoID int) (*model.Video, error) {
    video, err := s.repo.FindByID(videoID)
    if err != nil { return nil, err }
    return video, nil
}

func (s *VideoService) GetVideoStreamURL(ctx context.Context, objectName string) (string, error) {
    return s.storage.GeneratePresignedURL(ctx, objectName)
}

// Proxy helpers for streaming
func (s *VideoService) StatObject(ctx context.Context, objectName string) (int64, string, error) {
    info, err := s.storage.Stat(ctx, objectName)
    if err != nil {
        return 0, "", err
    }
    return info.Size, info.ContentType, nil
}

func (s *VideoService) GetObjectRange(ctx context.Context, objectName string, start, end int64) (io.ReadCloser, error) {
    obj, err := s.storage.GetObjectRange(ctx, objectName, start, end)
    if err != nil { return nil, err }
    return obj, nil
}

func (s *VideoService) DeleteVideo(userID, videoID int) error {
    video, err := s.repo.FindByID(videoID)
    if err != nil { return err }
    if video.UserID != userID { return errors.New("video not found") }
    ctx := context.Background()
    _ = s.storage.DeleteFile(ctx, video.FilePath)
    if video.ThumbnailPath != "" {
        _ = s.storage.DeleteFile(ctx, video.ThumbnailPath)
    }
    return s.repo.DeleteByID(videoID)
}

// CreateVideoStream uploads the provided reader directly to storage and creates a DB record.
// If size is unknown, pass size = -1 and a suitable contentType (e.g., "video/mp4").
func (s *VideoService) CreateVideoStream(userID int, reader io.Reader, filename string, size int64, contentType string) (*model.Video, error) {
    ext := filepath.Ext(filename)
    if ext == "" {
        if contentType == "video/mp4" {
            ext = ".mp4"
        } else {
            ext = ".bin"
        }
    }

    hash := md5.Sum([]byte(fmt.Sprintf("%d_%s_%d", userID, filename, time.Now().UnixNano())))
    fileName := hex.EncodeToString(hash[:]) + ext

    ctx := context.Background()
    objectName := fmt.Sprintf("user-%d/%s", userID, fileName)

    uploadedSize, err := s.storage.UploadReader(ctx, objectName, reader, size, contentType)
    if err != nil {
        return nil, err
    }

    finalSize := uploadedSize
    if size > 0 {
        finalSize = size
    }

    video := &model.Video{
        Title:        "",
        Description:  "",
        FilePath:     objectName,
        FileSize:     finalSize,
        ThumbnailPath: "",
        UserID:       userID,
        Status:       "ready",
    }

    if err := s.repo.Create(video); err != nil {
        ctx := context.Background()
        s.storage.DeleteFile(ctx, objectName)
        return nil, err
    }

    return video, nil
}
// UpdateVideoMetadata updates video title and description
func (s *VideoService) UpdateVideoMetadata(userID, videoID int, req *model.UpdateVideoMetadataRequest) error {
    // Проверяем ownership
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return err
    }
    
    if video.UserID != userID {
        return errors.New("video not found or access denied")
    }

    // Обновляем метаданные
    return s.repo.UpdateMetadata(videoID, req.Title, req.Description)
}

// UpdateVideoThumbnail updates video thumbnail
func (s *VideoService) UpdateVideoThumbnail(userID, videoID int, fileHeader *model.FileHeader) error {
    // Проверяем ownership
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return err
    }
    
    if video.UserID != userID {
        return errors.New("video not found or access denied")
    }

    // Создаем временный файл для thumbnail
    tempDir := filepath.Join("temp", fmt.Sprintf("%d", userID))
    if err := os.MkdirAll(tempDir, 0755); err != nil {
        return err
    }

    hash := md5.Sum([]byte(fmt.Sprintf("thumb_%d_%s_%d", userID, fileHeader.Filename, time.Now().UnixNano())))
    fileName := hex.EncodeToString(hash[:]) + filepath.Ext(fileHeader.Filename)
    tempFilePath := filepath.Join(tempDir, fileName)

    tempFile, err := os.Create(tempFilePath)
    if err != nil {
        return err
    }
    defer tempFile.Close()

    if _, err := io.Copy(tempFile, fileHeader.File); err != nil {
        return err
    }

    // Загружаем в MinIO
    ctx := context.Background()
    objectName := fmt.Sprintf("user-%d/thumbnails/%s", userID, fileName)
    
    if err := s.storage.UploadFile(ctx, objectName, tempFilePath, fileHeader.Size); err != nil {
        os.Remove(tempFilePath)
        return err
    }

    // Удаляем старый thumbnail если есть
    if video.ThumbnailPath != "" {
        s.storage.DeleteFile(ctx, video.ThumbnailPath)
    }

    // Обновляем путь в БД
    if err := s.repo.UpdateThumbnail(videoID, objectName); err != nil {
        // Откатываем загрузку если обновление БД не удалось
        s.storage.DeleteFile(ctx, objectName)
        return err
    }

    os.Remove(tempFilePath)
    return nil
}
