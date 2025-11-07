import pg from 'pg';
const { Pool, types } = pg;

// Настройка типов PostgreSQL: UUID возвращается как строка
// Тип UUID в PostgreSQL имеет OID 2950
types.setTypeParser(2950, 'text', (val) => val);

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'auth_service',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password',
});

export default pool;