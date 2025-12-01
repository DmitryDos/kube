-- Миграция: перенос thumbnail_path в file_path для всех фото
-- Фото (content_type = 'image') сейчас хранятся в thumbnail_path, а file_path пустой
-- Нужно перенести thumbnail_path в file_path для всех фото

UPDATE videos
SET file_path = thumbnail_path
WHERE content_type = 'image' 
  AND (file_path IS NULL OR file_path = '')
  AND thumbnail_path IS NOT NULL
  AND thumbnail_path != '';

-- После миграции thumbnail_path для фото можно оставить пустым или удалить
-- Но оставляем для обратной совместимости на время

