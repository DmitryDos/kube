-- Миграция: удаление старых фото из таблицы images
-- Все фото теперь хранятся в таблице videos с content_type = 'image'

DELETE FROM images;

-- Опционально: можно удалить саму таблицу, если она больше не нужна
-- DROP TABLE IF EXISTS images CASCADE;

