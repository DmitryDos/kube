-- Миграция: добавление колонки is_private если её нет
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'videos' 
        AND column_name = 'is_private'
    ) THEN
        ALTER TABLE videos ADD COLUMN is_private BOOLEAN DEFAULT FALSE NOT NULL;
        
        -- Создаем индекс для is_private если его нет
        CREATE INDEX IF NOT EXISTS idx_videos_is_private ON videos(is_private) WHERE is_private = FALSE;
    END IF;
END $$;





