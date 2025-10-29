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
        Title:       req.Title,
        Description: req.Description,
        FilePath:    objectName,
        FileSize:    fileHeader.Size,
        UserID:      userID,
        Status:      "ready",
    }

    if err := s.repo.Create(video); err != nil {
        ctx := context.Background()
        if delErr := s.storage.DeleteFile(ctx, objectName); delErr != nil {
            fmt.Printf("Warning: failed to delete object %s from MinIO: %v\n", objectName, delErr)
        }
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

        response = append(response, model.VideoResponse{
            ID:          video.ID,
            Title:       video.Title,
            Description: video.Description,
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

func (s *VideoService) GetVideoStreamURL(ctx context.Context, objectName string) (string, error) {
    return s.storage.GeneratePresignedURL(ctx, objectName)
}

// Proxy helpers for streaming
func (s *VideoService) StatObject(ctx context.Context, objectName string) (interface{ Size int64; ContentType string }, error) {
    info, err := s.storage.Stat(ctx, objectName)
    if err != nil { return nil, err }
    // return anonymous struct with needed fields
    return struct{ Size int64; ContentType string }{ Size: info.Size, ContentType: info.ContentType }, nil
}

func (s *VideoService) GetObjectRange(ctx context.Context, objectName string, start, end int64) (io.ReadCloser, error) {
    obj, err := s.storage.GetObjectRange(ctx, objectName, start, end)
    if err != nil { return nil, err }
    return obj, nil
}

// CreateVideoStream uploads the provided reader directly to storage and creates a DB record.
// If size is unknown, pass size = -1 and a suitable contentType (e.g., "video/mp4").
func (s *VideoService) CreateVideoStream(userID int, req *model.CreateVideoRequest, reader io.Reader, filename string, size int64, contentType string) (*model.Video, error) {
    if req == nil || req.Title == "" {
        return nil, errors.New("title is required")
    }

    ext := filepath.Ext(filename)
    if ext == "" {
        // Fallback based on content type
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
        Title:       req.Title,
        Description: req.Description,
        FilePath:    objectName,
        FileSize:    finalSize,
        UserID:      userID,
        Status:      "ready",
    }

    if err := s.repo.Create(video); err != nil {
        ctx := context.Background()
        _ = s.storage.DeleteFile(ctx, objectName)
        return nil, err
    }

    return video, nil
}