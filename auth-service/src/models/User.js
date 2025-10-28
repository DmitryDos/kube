import pool from '../utils/database.js';

export class User {
    static async create(userData) {
        const { email, passwordHash, name } = userData;
        const result = await pool.query(
            'INSERT INTO users (email, password_hash, name) VALUES ($1, $2, $3) RETURNING id, email, name, created_at',
            [email, passwordHash, name]
        );
        return result.rows[0];
    }

    static async findByEmail(email) {
        const result = await pool.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );
        return result.rows[0];
    }

    static async findById(id) {
        const result = await pool.query(
            'SELECT id, email, name, created_at FROM users WHERE id = $1',
            [id]
        );
        return result.rows[0];
    }
}