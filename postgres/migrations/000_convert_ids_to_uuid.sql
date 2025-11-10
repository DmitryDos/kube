-- Миграция: конвертация id колонок с VARCHAR/TEXT на UUID
-- Безопасна для повторного запуска - проверяет текущий тип

-- Убеждаемся, что расширение uuid-ossp доступно
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ 
BEGIN
    -- Конвертация users.id
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'id'
        AND data_type IN ('character varying', 'varchar', 'text', 'integer', 'bigint')
    ) THEN
        -- Сначала удаляем внешние ключи, которые зависят от users.id
        ALTER TABLE IF EXISTS sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey;
        ALTER TABLE IF EXISTS videos DROP CONSTRAINT IF EXISTS videos_user_id_fkey;
        
        -- Удаляем DEFAULT и sequence для users.id
        ALTER TABLE users ALTER COLUMN id DROP DEFAULT;
        DROP SEQUENCE IF EXISTS users_id_seq CASCADE;
        
        -- Конвертируем users.id
        ALTER TABLE users 
        ALTER COLUMN id TYPE UUID USING uuid_generate_v4();
        
        -- Устанавливаем новый DEFAULT
        ALTER TABLE users ALTER COLUMN id SET DEFAULT uuid_generate_v4();
    END IF;
    
    -- Конвертация sessions.id
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'sessions' 
        AND column_name = 'id'
        AND data_type IN ('character varying', 'varchar', 'text', 'integer', 'bigint')
    ) THEN
        -- Удаляем DEFAULT и sequence для sessions.id
        ALTER TABLE sessions ALTER COLUMN id DROP DEFAULT;
        DROP SEQUENCE IF EXISTS sessions_id_seq CASCADE;
        
        ALTER TABLE sessions 
        ALTER COLUMN id TYPE UUID USING uuid_generate_v4();
        
        -- Устанавливаем новый DEFAULT
        ALTER TABLE sessions ALTER COLUMN id SET DEFAULT uuid_generate_v4();
    END IF;
    
    -- Конвертация videos.id
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'videos' 
        AND column_name = 'id'
        AND data_type IN ('character varying', 'varchar', 'text', 'integer', 'bigint')
    ) THEN
        -- Удаляем DEFAULT и sequence для videos.id
        ALTER TABLE videos ALTER COLUMN id DROP DEFAULT;
        DROP SEQUENCE IF EXISTS videos_id_seq CASCADE;
        
        ALTER TABLE videos 
        ALTER COLUMN id TYPE UUID USING uuid_generate_v4();
        
        -- Устанавливаем новый DEFAULT
        ALTER TABLE videos ALTER COLUMN id SET DEFAULT uuid_generate_v4();
    END IF;
    
    -- Конвертация sessions.user_id
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'sessions' 
        AND column_name = 'user_id'
        AND data_type IN ('character varying', 'varchar', 'text', 'integer', 'bigint')
    ) THEN
        ALTER TABLE sessions 
        ALTER COLUMN user_id TYPE UUID USING 
            CASE 
                WHEN pg_typeof(user_id)::text IN ('character varying', 'varchar', 'text') 
                     AND user_id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
                THEN user_id::text::UUID
                ELSE NULL
            END;
    END IF;
    
    -- Конвертация videos.user_id
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'videos' 
        AND column_name = 'user_id'
        AND data_type IN ('character varying', 'varchar', 'text', 'integer', 'bigint')
    ) THEN
        ALTER TABLE videos 
        ALTER COLUMN user_id TYPE UUID USING NULL;
    END IF;
    
    -- Восстанавливаем внешние ключи после конвертации всех колонок
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'sessions_user_id_fkey'
    ) THEN
        ALTER TABLE sessions 
        ADD CONSTRAINT sessions_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'videos_user_id_fkey'
    ) THEN
        ALTER TABLE videos 
        ADD CONSTRAINT videos_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
END $$;

