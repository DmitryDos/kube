import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import redisClient from './redis.js';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const JWT_EXPIRES = process.env.JWT_EXPIRES || '7d';

export class AuthUtils {
    static async hashPassword(password) {
        return await bcrypt.hash(password, 12);
    }

    static async verifyPassword(password, hashedPassword) {
        return await bcrypt.compare(password, hashedPassword);
    }

    static generateToken(userId) {
        return jwt.sign({ userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES });
    }

    static async verifyToken(token) {
        try {
            // Проверяем в blacklist
            const isBlacklisted = await redisClient.get(`blacklist:${token}`);
            if (isBlacklisted) {
                return null;
            }

            return jwt.verify(token, JWT_SECRET);
        } catch (error) {
            return null;
        }
    }

    static async addToBlacklist(token) {
        // Добавляем токен в blacklist на время его экспирации
        const decoded = jwt.decode(token);
        if (decoded && decoded.exp) {
            const ttl = decoded.exp - Math.floor(Date.now() / 1000);
            if (ttl > 0) {
                await redisClient.setEx(`blacklist:${token}`, ttl, '1');
            }
        }
    }
}