-- Миграция: добавление поля content_type для различения видео и музыки
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'videos' 
        AND column_name = 'content_type'
    ) THEN
        ALTER TABLE videos ADD COLUMN content_type VARCHAR(50) DEFAULT 'video' NOT NULL;
        
        -- Создаем индекс для content_type
        CREATE INDEX IF NOT EXISTS idx_videos_content_type ON videos(content_type);
    END IF;
END $$;

