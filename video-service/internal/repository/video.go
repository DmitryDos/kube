package repository

import (
	"database/sql"
	"strconv"
	"strings"
	"video-service/internal/model"

	"github.com/google/uuid"
)

type VideoRepository struct {
	db *sql.DB
}

func NewVideoRepository(db *sql.DB) *VideoRepository {
	return &VideoRepository{db: db}
}

func (r *VideoRepository) Create(video *model.Video) error {
	query := `
		INSERT INTO videos (id, title, description, file_path, file_size, thumbnail_path, user_id, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING created_at, updated_at
	`

	var thumbnailPath interface{}
	if video.ThumbnailPath.Valid {
		thumbnailPath = video.ThumbnailPath.String
	} else {
		thumbnailPath = nil
	}

	return r.db.QueryRow(
		query,
		video.ID,
		video.Title,
		video.Description,
		video.FilePath,
		video.FileSize,
		thumbnailPath,
		video.UserID,
		video.Status,
	).Scan(&video.CreatedAt, &video.UpdatedAt)
}

func (r *VideoRepository) FindByUserID(userID uuid.UUID) ([]model.Video, error) {
	return r.FindByUserIDPaginated(userID, 0, 0)
}

func (r *VideoRepository) FindByUserIDPaginated(userID uuid.UUID, page, pageSize int) ([]model.Video, error) {
	query := `
		SELECT id, title, description, file_path, file_size, thumbnail_path, user_id, status, created_at, updated_at
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
			&video.ThumbnailPath,
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

func (r *VideoRepository) FindByID(id uuid.UUID) (*model.Video, error) {
	query := `
		SELECT id, title, description, file_path, file_size, thumbnail_path, user_id, status, created_at, updated_at
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
		&video.ThumbnailPath,
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

func (r *VideoRepository) DeleteByID(id uuid.UUID) error {
	_, err := r.db.Exec("DELETE FROM videos WHERE id = $1", id)
	return err
}

func (r *VideoRepository) UpdateThumbnail(videoID uuid.UUID, thumbnailPath string) error {
	_, err := r.db.Exec("UPDATE videos SET thumbnail_path = $1 WHERE id = $2", thumbnailPath, videoID)
	return err
}

func (r *VideoRepository) UpdateMetadata(videoID uuid.UUID, title *string, description *string) error {
	updates := []string{}
	args := []interface{}{}
	argPos := 1

	if title != nil {
		updates = append(updates, "title = $"+strconv.Itoa(argPos))
		args = append(args, *title)
		argPos++
	}

	if description != nil {
		updates = append(updates, "description = $"+strconv.Itoa(argPos))
		args = append(args, *description)
		argPos++
	}

	if len(updates) == 0 {
		return nil
	}

	args = append(args, videoID)
	query := "UPDATE videos SET " + strings.Join(updates, ", ") + ", updated_at = CURRENT_TIMESTAMP WHERE id = $" + strconv.Itoa(argPos)
	_, err := r.db.Exec(query, args...)
	return err
}

func (r *VideoRepository) FindAllPaginatedWithSearch(query string, userID *uuid.UUID, page, pageSize int) ([]model.Video, error) {
	base := `
		SELECT id, title, description, file_path, file_size, thumbnail_path, user_id, status, created_at, updated_at
		FROM videos
	`
	where := ""
	args := []interface{}{}
	argPos := 1

	addCond := func(cond string, val interface{}) {
		if where == "" {
			where = "WHERE " + cond
		} else {
			where += " AND " + cond
		}
		args = append(args, val)
		argPos++
	}

	if query != "" {
		addCond("(title ILIKE $"+strconv.Itoa(argPos)+" OR description ILIKE $"+strconv.Itoa(argPos)+")", "%"+query+"%")
	}
	if userID != nil {
		addCond("user_id = $"+strconv.Itoa(argPos), *userID)
	}

	order := " ORDER BY created_at DESC"

	var limitOffset string
	if pageSize > 0 {
		limitOffset = " LIMIT $" + strconv.Itoa(argPos) + " OFFSET $" + strconv.Itoa(argPos+1)
		args = append(args, pageSize, page*pageSize)
	}

	q := base + where + order + limitOffset

	rows, err := r.db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var videos []model.Video
	for rows.Next() {
		var video model.Video
		if err := rows.Scan(
			&video.ID,
			&video.Title,
			&video.Description,
			&video.FilePath,
			&video.FileSize,
			&video.ThumbnailPath,
			&video.UserID,
			&video.Status,
			&video.CreatedAt,
			&video.UpdatedAt,
		); err != nil {
			return nil, err
		}
		videos = append(videos, video)
	}
	return videos, nil
}
