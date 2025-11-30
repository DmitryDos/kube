package model

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

type Image struct {
	ID           uuid.UUID      `json:"id" db:"id"`
	Title        sql.NullString `json:"title" db:"title"`
	ImagePath    string         `json:"image_path" db:"image_path"`
	Width        int            `json:"width" db:"width"`
	Height       int            `json:"height" db:"height"`
	FileSize     int64          `json:"file_size" db:"file_size"`
	Author       sql.NullString `json:"author" db:"author"`
	Description  sql.NullString `json:"description" db:"description"`
	Tags         pq.StringArray `json:"tags" db:"tags"`
	UserID       uuid.UUID      `json:"user_id" db:"user_id"`
	Status       string         `json:"status" db:"status"`
	IsPrivate    bool           `json:"is_private" db:"is_private"`
	PublishedDate sql.NullTime  `json:"published_date" db:"published_date"`
	CreatedAt    time.Time      `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at" db:"updated_at"`
}

type UpdateImageMetadataRequest struct {
	Title        *string   `json:"title"`
	Description  *string   `json:"description"`
	Author       *string   `json:"author"`
	Tags         *[]string `json:"tags"`
	IsPrivate    *bool     `json:"is_private"`
	PublishedDate *time.Time `json:"published_date"`
}

type ImageResponse struct {
	ID            uuid.UUID  `json:"id"`
	Title         string     `json:"title,omitempty"`
	ImageURL      string     `json:"image_url"`
	Width         int        `json:"width"`
	Height        int        `json:"height"`
	UserID        uuid.UUID  `json:"user_id"`
	FileSize      int64      `json:"file_size"`
	Author        string     `json:"author,omitempty"`
	Description   string     `json:"description,omitempty"`
	Tags          []string   `json:"tags,omitempty"`
	Status        string     `json:"status"`
	IsPrivate     bool       `json:"is_private"`
	PublishedDate *time.Time `json:"published_date,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

