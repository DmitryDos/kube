-- Миграция: добавление колонки thumbnail_path если её нет
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'videos' 
        AND column_name = 'thumbnail_path'
    ) THEN
        ALTER TABLE videos ADD COLUMN thumbnail_path VARCHAR(500);
    END IF;
END $$;

