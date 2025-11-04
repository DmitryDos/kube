-- Миграция: конвертация integer ID пользователей в UUID
-- Проверяем, есть ли колонка id с типом integer
DO $$
DECLARE
    column_type TEXT;
BEGIN
    -- Получаем тип колонки id
    SELECT data_type INTO column_type
    FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'id';
    
    -- Если колонка integer, конвертируем в UUID
    IF column_type = 'integer' OR column_type = 'bigint' THEN
        -- Создаем временную колонку с UUID
        ALTER TABLE users ADD COLUMN IF NOT EXISTS id_new UUID;
        
        -- Генерируем UUID для существующих пользователей
        UPDATE users SET id_new = uuid_generate_v4() WHERE id_new IS NULL;
        
        -- Обновляем внешние ключи в других таблицах
        -- Сначала обновляем sessions
        ALTER TABLE sessions ADD COLUMN IF NOT EXISTS user_id_new UUID;
        UPDATE sessions s 
        SET user_id_new = u.id_new 
        FROM users u 
        WHERE CAST(s.user_id AS TEXT) = CAST(u.id AS TEXT);
        
        -- Обновляем videos
        ALTER TABLE videos ADD COLUMN IF NOT EXISTS user_id_new UUID;
        UPDATE videos v 
        SET user_id_new = u.id_new 
        FROM users u 
        WHERE CAST(v.user_id AS TEXT) = CAST(u.id AS TEXT);
        
        -- Удаляем старые колонки и переименовываем новые
        ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey;
        ALTER TABLE videos DROP CONSTRAINT IF EXISTS videos_user_id_fkey;
        
        ALTER TABLE users DROP COLUMN id;
        ALTER TABLE users RENAME COLUMN id_new TO id;
        ALTER TABLE users ALTER COLUMN id SET NOT NULL;
        ALTER TABLE users ADD PRIMARY KEY (id);
        
        ALTER TABLE sessions DROP COLUMN user_id;
        ALTER TABLE sessions RENAME COLUMN user_id_new TO user_id;
        ALTER TABLE sessions ALTER COLUMN user_id SET NOT NULL;
        ALTER TABLE sessions ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        ALTER TABLE videos DROP COLUMN user_id;
        ALTER TABLE videos RENAME COLUMN user_id_new TO user_id;
        ALTER TABLE videos ALTER COLUMN user_id SET NOT NULL;
        ALTER TABLE videos ADD CONSTRAINT videos_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Migrated user IDs from integer to UUID';
    ELSE
        RAISE NOTICE 'User ID column is already UUID type, skipping migration';
    END IF;
END $$;

