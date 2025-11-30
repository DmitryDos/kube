package service

import (
	"context"
	"crypto/md5"
	"database/sql"
	"encoding/hex"
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"io"
	"os"
	"path/filepath"
	"time"
	"video-service/internal/model"
	"video-service/internal/repository"
	"video-service/internal/storage"

	"github.com/google/uuid"
)

type ImageService struct {
	repo    *repository.ImageRepository
	storage *storage.MinIOClient
}

func NewImageService(repo *repository.ImageRepository, storage *storage.MinIOClient) *ImageService {
	return &ImageService{repo: repo, storage: storage}
}

func (s *ImageService) CreateImageFile(userID uuid.UUID, fileHeader *model.FileHeader) (*model.Image, error) {
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

	// Получаем размеры изображения
	file, err := os.Open(tempFilePath)
	if err != nil {
		os.Remove(tempFilePath)
		return nil, err
	}
	defer file.Close()

	img, _, err := image.DecodeConfig(file)
	if err != nil {
		os.Remove(tempFilePath)
		return nil, fmt.Errorf("failed to decode image: %w", err)
	}

	ctx := context.Background()
	objectName := fmt.Sprintf("user-%s/images/%s", userID.String(), fileName)
	if err := s.storage.UploadFile(ctx, objectName, tempFilePath, fileHeader.Size); err != nil {
		os.Remove(tempFilePath)
		return nil, err
	}

	imageModel := &model.Image{
		ID:            uuid.New(),
		Title:         sql.NullString{},
		ImagePath:     objectName,
		Width:         img.Width,
		Height:        img.Height,
		FileSize:      fileHeader.Size,
		Author:        sql.NullString{},
		Description:   sql.NullString{},
		Tags:          []string{},
		UserID:        userID,
		Status:        "ready",
		IsPrivate:     false,
		PublishedDate: sql.NullTime{},
	}

	if err := s.repo.Create(imageModel); err != nil {
		ctx := context.Background()
		s.storage.DeleteFile(ctx, objectName)
		os.Remove(tempFilePath)
		return nil, err
	}

	os.Remove(tempFilePath)
	return imageModel, nil
}

func (s *ImageService) GetImageStreamURL(ctx context.Context, imagePath string) (string, error) {
	return s.storage.GetPresignedURL(ctx, imagePath, 24*time.Hour)
}

func (s *ImageService) UpdateMetadata(imageID uuid.UUID, req *model.UpdateImageMetadataRequest) error {
	return s.repo.UpdateMetadata(imageID, req)
}

func (s *ImageService) GetImageByID(imageID uuid.UUID) (*model.Image, error) {
	return s.repo.FindByID(imageID)
}

