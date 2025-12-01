package repository

import (
	"database/sql"
	"fmt"
	"strings"
	"video-service/internal/model"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

type ImageRepository struct {
	db *sql.DB
}

func NewImageRepository(db *sql.DB) *ImageRepository {
	return &ImageRepository{db: db}
}

func (r *ImageRepository) Create(image *model.Image) error {
	query := `
		INSERT INTO images (id, title, image_path, width, height, file_size, author, description, tags, user_id, status, is_private, published_date)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		RETURNING created_at, updated_at
	`

	var title interface{}
	if image.Title.Valid {
		title = image.Title.String
	} else {
		title = nil
	}

	var author interface{}
	if image.Author.Valid {
		author = image.Author.String
	} else {
		author = nil
	}

	var description interface{}
	if image.Description.Valid {
		description = image.Description.String
	} else {
		description = nil
	}

	var tags interface{}
	if len(image.Tags) > 0 {
		tags = pq.Array(image.Tags)
	} else {
		tags = nil
	}

	var publishedDate interface{}
	if image.PublishedDate.Valid {
		publishedDate = image.PublishedDate.Time
	} else {
		publishedDate = nil
	}

	return r.db.QueryRow(
		query,
		image.ID,
		title,
		image.ImagePath,
		image.Width,
		image.Height,
		image.FileSize,
		author,
		description,
		tags,
		image.UserID,
		image.Status,
		image.IsPrivate,
		publishedDate,
	).Scan(&image.CreatedAt, &image.UpdatedAt)
}

func (r *ImageRepository) FindByID(id uuid.UUID) (*model.Image, error) {
	query := `
		SELECT id, title, image_path, width, height, file_size, author, description, tags, user_id, status, is_private, published_date, created_at, updated_at
		FROM images
		WHERE id = $1
	`

	image := &model.Image{}
	var tags pq.StringArray
	err := r.db.QueryRow(query, id).Scan(
		&image.ID,
		&image.Title,
		&image.ImagePath,
		&image.Width,
		&image.Height,
		&image.FileSize,
		&image.Author,
		&image.Description,
		&tags,
		&image.UserID,
		&image.Status,
		&image.IsPrivate,
		&image.PublishedDate,
		&image.CreatedAt,
		&image.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	image.Tags = []string(tags)
	return image, nil
}

func (r *ImageRepository) UpdateMetadata(id uuid.UUID, req *model.UpdateImageMetadataRequest) error {
	updates := []string{}
	args := []interface{}{}
	argIndex := 1

	if req.Title != nil {
		updates = append(updates, fmt.Sprintf("title = $%d", argIndex))
		args = append(args, *req.Title)
		argIndex++
	}
	if req.Description != nil {
		updates = append(updates, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}
	if req.Author != nil {
		updates = append(updates, fmt.Sprintf("author = $%d", argIndex))
		args = append(args, *req.Author)
		argIndex++
	}
	if req.Tags != nil {
		updates = append(updates, fmt.Sprintf("tags = $%d", argIndex))
		args = append(args, pq.Array(*req.Tags))
		argIndex++
	}
	if req.IsPrivate != nil {
		updates = append(updates, fmt.Sprintf("is_private = $%d", argIndex))
		args = append(args, *req.IsPrivate)
		argIndex++
	}
	if req.PublishedDate != nil {
		updates = append(updates, fmt.Sprintf("published_date = $%d", argIndex))
		args = append(args, *req.PublishedDate)
		argIndex++
	}

	if len(updates) == 0 {
		return nil
	}

	updates = append(updates, fmt.Sprintf("updated_at = CURRENT_TIMESTAMP"))
	args = append(args, id)

	query := fmt.Sprintf("UPDATE images SET %s WHERE id = $%d", strings.Join(updates, ", "), argIndex)
	_, err := r.db.Exec(query, args...)
	return err
}

func (r *ImageRepository) FindAllPaginatedWithSearch(query string, userID *uuid.UUID, currentUserID *uuid.UUID, page, pageSize int) ([]model.Image, error) {
	base := `
		SELECT id, title, image_path, width, height, file_size, author, description, tags, user_id, status, is_private, published_date, created_at, updated_at
		FROM images
	`
	where := ""
	args := []interface{}{}
	argIndex := 1

	// Фильтр по приватности: показываем публичные или свои
	if currentUserID != nil {
		where = "WHERE (is_private = FALSE OR user_id = $" + fmt.Sprintf("%d", argIndex) + ")"
		args = append(args, *currentUserID)
		argIndex++
	} else {
		where = "WHERE is_private = FALSE"
	}

	// Фильтр по пользователю (если указан)
	if userID != nil {
		if where != "" {
			where += " AND user_id = $" + fmt.Sprintf("%d", argIndex)
		} else {
			where = "WHERE user_id = $" + fmt.Sprintf("%d", argIndex)
		}
		args = append(args, *userID)
		argIndex++
	}

	// Поиск по запросу
	if query != "" {
		searchCondition := `
			(LOWER(title::text) LIKE LOWER($` + fmt.Sprintf("%d", argIndex) + `) OR
			LOWER(description::text) LIKE LOWER($` + fmt.Sprintf("%d", argIndex) + `) OR
			LOWER(author::text) LIKE LOWER($` + fmt.Sprintf("%d", argIndex) + `))
		`
		if where != "" {
			where += " AND " + searchCondition
		} else {
			where = "WHERE " + searchCondition
		}
		args = append(args, "%"+query+"%")
		argIndex++
	}

	// Фильтр по статусу
	if where != "" {
		where += " AND status = 'ready'"
	} else {
		where = "WHERE status = 'ready'"
	}

	queryStr := base + where + " ORDER BY created_at DESC LIMIT $" + fmt.Sprintf("%d", argIndex) + " OFFSET $" + fmt.Sprintf("%d", argIndex+1)
	args = append(args, pageSize, page*pageSize)

	rows, err := r.db.Query(queryStr, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var images []model.Image
	for rows.Next() {
		var image model.Image
		var tags pq.StringArray
		if err := rows.Scan(
			&image.ID,
			&image.Title,
			&image.ImagePath,
			&image.Width,
			&image.Height,
			&image.FileSize,
			&image.Author,
			&image.Description,
			&tags,
			&image.UserID,
			&image.Status,
			&image.IsPrivate,
			&image.PublishedDate,
			&image.CreatedAt,
			&image.UpdatedAt,
		); err != nil {
			return nil, err
		}
		image.Tags = []string(tags)
		images = append(images, image)
	}

	return images, nil
}

