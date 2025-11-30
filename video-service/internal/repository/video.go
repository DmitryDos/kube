package repository

import (
	"database/sql"
	"log"
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
		INSERT INTO videos (id, title, description, file_path, file_size, thumbnail_path, image_id, content_type, user_id, status, is_private)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING created_at, updated_at
	`

	var thumbnailPath interface{}
	if video.ThumbnailPath.Valid {
		thumbnailPath = video.ThumbnailPath.String
	} else {
		thumbnailPath = nil
	}

	var imageID interface{}
	if video.ImageID.Valid {
		imageID = video.ImageID.String
	} else {
		imageID = nil
	}

	contentType := video.ContentType
	if contentType == "" {
		contentType = "video" // По умолчанию видео
	}

	log.Printf("[VideoRepository.Create] Video.ContentType from model: %q, using contentType: %q, ID: %s", video.ContentType, contentType, video.ID.String())

	return r.db.QueryRow(
		query,
		video.ID,
		video.Title,
		video.Description,
		video.FilePath,
		video.FileSize,
		thumbnailPath,
		imageID,
		contentType,
		video.UserID,
		video.Status,
		video.IsPrivate,
	).Scan(&video.CreatedAt, &video.UpdatedAt)
}

func (r *VideoRepository) FindByUserID(userID uuid.UUID) ([]model.Video, error) {
	return r.FindByUserIDPaginated(userID, 0, 0)
}

func (r *VideoRepository) FindByUserIDPaginated(userID uuid.UUID, page, pageSize int) ([]model.Video, error) {
	query := `
		SELECT id, title, description, file_path, file_size, duration, thumbnail_path, image_id, content_type, user_id, status, is_private, created_at, updated_at
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
			&video.Duration,
			&video.ThumbnailPath,
			&video.ImageID,
			&video.ContentType,
			&video.UserID,
			&video.Status,
			&video.IsPrivate,
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
		SELECT id, title, description, file_path, file_size, duration, thumbnail_path, image_id, content_type, user_id, status, is_private, created_at, updated_at
		FROM videos
		WHERE id = $1
	`

	log.Printf("[FindByID] Searching for video with UUID: %s (lowercase: %s)", id.String(), id.String())
	
	// Проверяем, есть ли видео с таким UUID (прямой запрос)
	var testID uuid.UUID
	testQuery := `SELECT id FROM videos WHERE id = $1 LIMIT 1`
	testErr := r.db.QueryRow(testQuery, id).Scan(&testID)
	if testErr == nil {
		log.Printf("[FindByID] Direct test query found UUID: %s", testID.String())
	} else {
		log.Printf("[FindByID] Direct test query failed: %v", testErr)
		
		// Пробуем найти по строковому сравнению (на случай проблем с типами)
		var foundIDStr string
		testQuery2 := `SELECT id::text FROM videos WHERE id::text = LOWER($1) LIMIT 1`
		if err := r.db.QueryRow(testQuery2, id.String()).Scan(&foundIDStr); err == nil {
			log.Printf("[FindByID] Found by string comparison: %s", foundIDStr)
		} else {
			log.Printf("[FindByID] String comparison also failed: %v", err)
		}
	}
	
	var video model.Video
	err := r.db.QueryRow(query, id).Scan(
		&video.ID,
		&video.Title,
		&video.Description,
		&video.FilePath,
		&video.FileSize,
		&video.Duration,
		&video.ThumbnailPath,
		&video.ImageID,
		&video.ContentType,
		&video.UserID,
		&video.Status,
		&video.IsPrivate,
		&video.CreatedAt,
		&video.UpdatedAt,
	)

	if err != nil {
		log.Printf("[FindByID] Error scanning video: %v, UUID: %s", err, id.String())
		if err == sql.ErrNoRows {
			log.Printf("[FindByID] Video with UUID %s not found in database (sql.ErrNoRows)", id.String())
			
			// Показываем все доступные ID для отладки
			var allIDs []string
			allQuery := `SELECT id::text FROM videos ORDER BY created_at DESC LIMIT 10`
			if rows, err := r.db.Query(allQuery); err == nil {
				defer rows.Close()
				for rows.Next() {
					var idStr string
					if err := rows.Scan(&idStr); err == nil {
						allIDs = append(allIDs, idStr)
					}
				}
				log.Printf("[FindByID] All available video IDs: %v", allIDs)
			}
		}
		return nil, err
	}

	log.Printf("[FindByID] Found video: ID=%s, Title=%s, FilePath=%s", video.ID.String(), video.Title, video.FilePath)
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

func (r *VideoRepository) UpdateMetadata(videoID uuid.UUID, title *string, description *string, isPrivate *bool) error {
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

	if isPrivate != nil {
		updates = append(updates, "is_private = $"+strconv.Itoa(argPos))
		args = append(args, *isPrivate)
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

func (r *VideoRepository) FindAllPaginatedWithSearch(query string, userID *uuid.UUID, currentUserID *uuid.UUID, page, pageSize int) ([]model.Video, error) {
	base := `
		SELECT id, title, description, file_path, file_size, duration, thumbnail_path, image_id, content_type, user_id, status, is_private, created_at, updated_at
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

	// Добавляем фильтр приватности (если нужно)
	if userID == nil {
		// Если не фильтруем по конкретному пользователю, применяем фильтр приватности
		if currentUserID != nil {
			// Показываем публичные ИЛИ приватные видео текущего пользователя
			addCond("(is_private = FALSE OR (is_private = TRUE AND user_id = $"+strconv.Itoa(argPos)+"))", *currentUserID)
		} else {
			// Если пользователь не авторизован, показываем только публичные
			if where == "" {
				where = "WHERE is_private = FALSE"
			} else {
				where += " AND is_private = FALSE"
			}
		}
	}
	// Если userID != nil, показываем все видео этого пользователя (и приватные, и публичные)
	
	if query != "" {
		addCond("(title ILIKE $"+strconv.Itoa(argPos)+" OR description ILIKE $"+strconv.Itoa(argPos)+")", "%"+query+"%")
	}
	if userID != nil {
		// Если фильтруем по конкретному пользователю, показываем все его видео (и приватные, и публичные)
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
			&video.Duration,
			&video.ThumbnailPath,
			&video.ImageID,
			&video.ContentType,
			&video.UserID,
			&video.Status,
			&video.IsPrivate,
			&video.CreatedAt,
			&video.UpdatedAt,
		); err != nil {
			return nil, err
		}
		videos = append(videos, video)
	}
	return videos, nil
}
