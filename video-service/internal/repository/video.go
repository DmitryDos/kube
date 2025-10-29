package repository

import (
    "database/sql"
    "video-service/internal/model"
)

type VideoRepository struct {
    db *sql.DB
}

func NewVideoRepository(db *sql.DB) *VideoRepository {
    return &VideoRepository{db: db}
}

func (r *VideoRepository) Create(video *model.Video) error {
    query := `
        INSERT INTO videos (title, description, file_path, file_size, user_id, status)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, created_at, updated_at
    `

    return r.db.QueryRow(
        query,
        video.Title,
        video.Description,
        video.FilePath,
        video.FileSize,
        video.UserID,
        video.Status,
    ).Scan(&video.ID, &video.CreatedAt, &video.UpdatedAt)
}

func (r *VideoRepository) FindByUserID(userID int) ([]model.Video, error) {
    return r.FindByUserIDPaginated(userID, 0, 0)
}

func (r *VideoRepository) FindByUserIDPaginated(userID, page, pageSize int) ([]model.Video, error) {
    query := `
        SELECT id, title, description, file_path, file_size, user_id, status, created_at, updated_at
        FROM videos
        WHERE user_id = $1
        ORDER BY created_at DESC
    `
    
    args := []interface{}{userID}
    
    if pageSize > 0 {
        offset := page * pageSize
        query += " LIMIT $2 OFFSET $3"
        args = append(args, pageSize, offset)
    }

    rows, err := r.db.Query(query, args...)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var videos []model.Video
    for rows.Next() {
        var video model.Video
        err := rows.Scan(
            &video.ID,
            &video.Title,
            &video.Description,
            &video.FilePath,
            &video.FileSize,
            &video.UserID,
            &video.Status,
            &video.CreatedAt,
            &video.UpdatedAt,
        )
        if err != nil {
            return nil, err
        }
        videos = append(videos, video)
    }

    return videos, nil
}

func (r *VideoRepository) FindByID(id int) (*model.Video, error) {
    query := `
        SELECT id, title, description, file_path, file_size, user_id, status, created_at, updated_at
        FROM videos
        WHERE id = $1
    `

    var video model.Video
    err := r.db.QueryRow(query, id).Scan(
        &video.ID,
        &video.Title,
        &video.Description,
        &video.FilePath,
        &video.FileSize,
        &video.UserID,
        &video.Status,
        &video.CreatedAt,
        &video.UpdatedAt,
    )

    if err != nil {
        return nil, err
    }

    return &video, nil
}

func (r *VideoRepository) DeleteByID(id int) error {
    _, err := r.db.Exec("DELETE FROM videos WHERE id = $1", id)
    return err
}