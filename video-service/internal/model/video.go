package model

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type Video struct {
	ID           uuid.UUID      `json:"id" db:"id"`
	Title        string         `json:"title" db:"title"`
	Description  string         `json:"description" db:"description"`
	FilePath     string         `json:"file_path" db:"file_path"`
	FileSize     int64          `json:"file_size" db:"file_size"`
	Duration     sql.NullFloat64 `json:"duration" db:"duration"`
	ThumbnailPath sql.NullString `json:"thumbnail_path" db:"thumbnail_path"`
	UserID       uuid.UUID      `json:"user_id" db:"user_id"`
	Status       string         `json:"status" db:"status"`
	CreatedAt    time.Time      `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at" db:"updated_at"`
}

type CreateVideoRequest struct {
	Title       string `json:"title" binding:"required"`
	Description string `json:"description"`
}

type UpdateVideoMetadataRequest struct {
	Title       *string `json:"title"`
	Description *string `json:"description"`
}

type VideoResponse struct {
	ID           uuid.UUID `json:"id"`
	Title        string    `json:"title"`
	Description  string    `json:"description"`
	UserID       uuid.UUID `json:"user_id"`
	FileSize     int64     `json:"file_size"`
	FileURL      string    `json:"file_url"`
	ThumbnailURL string    `json:"thumbnail_url,omitempty"`
	Status       string    `json:"status"`
	Duration     float64   `json:"duration"`
	CreatedAt    time.Time `json:"created_at"`
}
