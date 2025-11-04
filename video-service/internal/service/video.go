package service

import (
    "context"
    "crypto/md5"
    "database/sql"
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

    "github.com/google/uuid"
)

type VideoService struct {
    repo    *repository.VideoRepository
    storage *storage.MinIOClient
}

func NewVideoService(repo *repository.VideoRepository, storage *storage.MinIOClient) *VideoService {
    return &VideoService{repo: repo, storage: storage}
}

func (s *VideoService) CreateVideoFile(userID uuid.UUID, fileHeader *model.FileHeader) (*model.Video, error) {
    tempDir := filepath.Join("temp", userID.String())
    if err := os.MkdirAll(tempDir, 0755); err != nil {
        return nil, err
    }

    hash := md5.Sum([]byte(fmt.Sprintf("%s_%s_%d", userID.String(), fileHeader.Filename, time.Now().UnixNano())))
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
    objectName := fmt.Sprintf("user-%s/%s", userID.String(), fileName)
    if err := s.storage.UploadFile(ctx, objectName, tempFilePath, fileHeader.Size); err != nil {
        os.Remove(tempFilePath)
        return nil, err
    }

    video := &model.Video{
        ID:           uuid.New(),
        Title:        "",
        Description:  "",
        FilePath:     objectName,
        FileSize:     fileHeader.Size,
        ThumbnailPath: sql.NullString{},
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

func (s *VideoService) GetUserVideosPaginated(userID uuid.UUID, page, pageSize int) ([]model.VideoResponse, error) {
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
        if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
            thumbnailURL = fmt.Sprintf("/api/videos/%s/thumbnail", video.ID.String())
        }

        var duration float64
        if video.Duration.Valid {
            duration = video.Duration.Float64
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
            Duration:     duration,
            CreatedAt:    video.CreatedAt,
        })
    }

    return response, nil
}

func (s *VideoService) GetAllVideosPaginated(query string, userID *uuid.UUID, page, pageSize int) ([]model.VideoResponse, error) {
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
        if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
            thumbnailURL = fmt.Sprintf("/api/videos/%s/thumbnail", video.ID.String())
        }

        var duration float64
        if video.Duration.Valid {
            duration = video.Duration.Float64
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
            Duration:     duration,
            CreatedAt:    video.CreatedAt,
        })
    }

    return response, nil
}

func (s *VideoService) GetVideo(userID, videoID uuid.UUID) (*model.Video, error) {
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return nil, err
    }
    if video.UserID != userID {
        return nil, errors.New("video not found")
    }
    return video, nil
}

func (s *VideoService) GetVideoPublic(videoID uuid.UUID) (*model.Video, error) {
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return nil, err
    }
    return video, nil
}

func (s *VideoService) GetVideoStreamURL(ctx context.Context, objectName string) (string, error) {
    return s.storage.GeneratePresignedURL(ctx, objectName)
}

func (s *VideoService) StatObject(ctx context.Context, objectName string) (int64, string, error) {
    info, err := s.storage.Stat(ctx, objectName)
    if err != nil {
        return 0, "", err
    }
    return info.Size, info.ContentType, nil
}

func (s *VideoService) GetObjectRange(ctx context.Context, objectName string, start, end int64) (io.ReadCloser, error) {
    obj, err := s.storage.GetObjectRange(ctx, objectName, start, end)
    if err != nil {
        return nil, err
    }
    return obj, nil
}

func (s *VideoService) DeleteVideo(userID, videoID uuid.UUID) error {
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return err
    }
    if video.UserID != userID {
        return errors.New("video not found")
    }
    ctx := context.Background()
    _ = s.storage.DeleteFile(ctx, video.FilePath)
    if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
        _ = s.storage.DeleteFile(ctx, video.ThumbnailPath.String)
    }
    return s.repo.DeleteByID(videoID)
}

func (s *VideoService) CreateVideoStream(userID uuid.UUID, reader io.Reader, filename string, size int64, contentType string) (*model.Video, error) {
    ext := filepath.Ext(filename)
    if ext == "" {
        if contentType == "video/mp4" {
            ext = ".mp4"
        } else {
            ext = ".bin"
        }
    }

    hash := md5.Sum([]byte(fmt.Sprintf("%s_%s_%d", userID.String(), filename, time.Now().UnixNano())))
    fileName := hex.EncodeToString(hash[:]) + ext

    ctx := context.Background()
    objectName := fmt.Sprintf("user-%s/%s", userID.String(), fileName)

    uploadedSize, err := s.storage.UploadReader(ctx, objectName, reader, size, contentType)
    if err != nil {
        return nil, err
    }

    finalSize := uploadedSize
    if size > 0 {
        finalSize = size
    }

    video := &model.Video{
        ID:           uuid.New(),
        Title:        "",
        Description:  "",
        FilePath:     objectName,
        FileSize:     finalSize,
        ThumbnailPath: sql.NullString{},
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

func (s *VideoService) UpdateVideoMetadata(userID, videoID uuid.UUID, req *model.UpdateVideoMetadataRequest) error {
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return err
    }
    if video.UserID != userID {
        return errors.New("video not found or access denied")
    }
    return s.repo.UpdateMetadata(videoID, req.Title, req.Description)
}

func (s *VideoService) UpdateVideoThumbnail(userID, videoID uuid.UUID, fileHeader *model.FileHeader) error {
    video, err := s.repo.FindByID(videoID)
    if err != nil {
        return err
    }
    if video.UserID != userID {
        return errors.New("video not found or access denied")
    }

    tempDir := filepath.Join("temp", userID.String())
    if err := os.MkdirAll(tempDir, 0755); err != nil {
        return err
    }

    hash := md5.Sum([]byte(fmt.Sprintf("thumb_%s_%s_%d", userID.String(), fileHeader.Filename, time.Now().UnixNano())))
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

    ctx := context.Background()
    objectName := fmt.Sprintf("user-%s/thumbnails/%s", userID.String(), fileName)

    if err := s.storage.UploadFile(ctx, objectName, tempFilePath, fileHeader.Size); err != nil {
        os.Remove(tempFilePath)
        return err
    }

    if video.ThumbnailPath.Valid && video.ThumbnailPath.String != "" {
        s.storage.DeleteFile(ctx, video.ThumbnailPath.String)
    }

    if err := s.repo.UpdateThumbnail(videoID, objectName); err != nil {
        s.storage.DeleteFile(ctx, objectName)
        return err
    }

    os.Remove(tempFilePath)
    return nil
}
