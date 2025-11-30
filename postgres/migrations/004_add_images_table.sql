-- Миграция: создание таблицы images для всех изображений (обложки и фото)
CREATE TABLE IF NOT EXISTS images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255),
    image_path VARCHAR(500) NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    file_size BIGINT NOT NULL,
    author VARCHAR(255),
    description TEXT,
    tags TEXT[], -- Массив строк для тегов
    user_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'ready' NOT NULL,
    is_private BOOLEAN DEFAULT FALSE NOT NULL,
    published_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_images_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Индексы для images
CREATE INDEX IF NOT EXISTS idx_images_user_id ON images(user_id);
CREATE INDEX IF NOT EXISTS idx_images_status ON images(status);
CREATE INDEX IF NOT EXISTS idx_images_is_private ON images(is_private) WHERE is_private = FALSE;
CREATE INDEX IF NOT EXISTS idx_images_created_at ON images(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_images_published_date ON images(published_date DESC);

-- Добавляем image_id в videos для связи с обложками
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'videos' 
        AND column_name = 'image_id'
    ) THEN
        ALTER TABLE videos ADD COLUMN image_id UUID REFERENCES images(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_videos_image_id ON videos(image_id);
    END IF;
END $$;

