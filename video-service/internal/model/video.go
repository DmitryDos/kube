package model

import "time"

type Video struct {
    ID          int       `json:"id" db:"id"`
    Title       string    `json:"title" db:"title"`
    Description string    `json:"description" db:"description"`
    FilePath    string    `json:"file_path" db:"file_path"`
    FileName    string    `json:"file_name" db:"file_name"` // Новое поле
    FileSize    int64     `json:"file_size" db:"file_size"`
    UserID      int       `json:"user_id" db:"user_id"`
    Status      string    `json:"status" db:"status"`
    CreatedAt   time.Time `json:"created_at" db:"created_at"`
    UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type CreateVideoRequest struct {
    Title       string `json:"title" binding:"required"`
    Description string `json:"description"`
}

type VideoResponse struct {
    ID          int       `json:"id"`
    Title       string    `json:"title"`
    Description string    `json:"description"`
    FileName    string    `json:"file_name"`
    FileSize    int64     `json:"file_size"`
    FileURL     string    `json:"file_url"` // URL для скачивания
    Status      string    `json:"status"`
    CreatedAt   time.Time `json:"created_at"`
}