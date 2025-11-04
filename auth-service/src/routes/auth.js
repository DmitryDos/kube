import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import { User } from '../models/User.js';
import { AuthUtils } from '../utils/auth.js';
import { authenticateToken } from '../middleware/auth.js';
import pool from '../utils/database.js';

const router = express.Router();

router.post('/register', async (req, res) => {
    try {
        const { email, password, name } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ error: 'Invalid email format' });
        }

        if (password.length < 8) {
            return res.status(400).json({ error: 'Password must be at least 8 characters long' });
        }

        const existingUser = await User.findByEmail(email);
        if (existingUser) {
            return res.status(409).json({ error: 'User already exists' });
        }

        const passwordHash = await AuthUtils.hashPassword(password);

        const user = await User.create({
            email,
            passwordHash,
            name: name || email.split('@')[0]
        });

        // Проверяем формат ID (новый пользователь должен иметь UUID из схемы)
        let userId;
        if (typeof user.id === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user.id)) {
            userId = user.id;
        } else {
            // Если по какой-то причине не UUID, конвертируем
            userId = String(user.id);
        }

        const token = AuthUtils.generateToken(userId);

        res.status(201).json({
            message: 'User created successfully',
            user: {
                id: userId,
                email: user.email,
                name: user.name
            },
            token
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ error: 'Invalid email format' });
        }

        // Поиск пользователя
        const user = await User.findByEmail(email);
        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Проверка пароля
        const isValidPassword = await AuthUtils.verifyPassword(password, user.password_hash);
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        console.log('[Login] User from DB:', { id: user.id, idType: typeof user.id, idValue: user.id });

        // Проверяем формат ID и конвертируем в UUID если нужно
        let userId;
        if (typeof user.id === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user.id)) {
            // Уже валидный UUID
            userId = user.id;
        } else if ((typeof user.id === 'string' && /^\d+$/.test(user.id)) || typeof user.id === 'number') {
            // Это число или строка с числом (старый формат)
            // ВАЖНО: Нужно выполнить миграцию 002_migrate_user_id_to_uuid.sql вручную!
            console.error('[Login] ERROR: User ID is integer format. Please run migration 002_migrate_user_id_to_uuid.sql');
            console.error('[Login] User ID:', user.id, 'Type:', typeof user.id);
            // Временно генерируем UUID для ответа, но база останется со старым форматом
            // Это нужно исправить миграцией!
            userId = uuidv4();
            console.warn('[Login] WARNING: Returning temporary UUID, but database still has integer ID. Migration required!');
        } else {
            // PostgreSQL UUID объект - конвертируем в строку
            userId = String(user.id);
        }

        const token = AuthUtils.generateToken(userId);

        res.json({
            message: 'Login successful',
            user: {
                id: userId,
                email: user.email,
                name: user.name
            },
            token
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.get('/profile', authenticateToken, async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Проверяем формат ID
        let userId;
        if (typeof user.id === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user.id)) {
            userId = user.id;
        } else {
            userId = String(user.id);
        }

        res.json({ 
            user: {
                id: userId,
                email: user.email,
                name: user.name,
                created_at: user.created_at
            }
        });
    } catch (error) {
        console.error('Profile error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.post('/logout', authenticateToken, async (req, res) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (token) {
            await AuthUtils.addToBlacklist(token);
        }

        res.json({ message: 'Logout successful' });
    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.get('/validate', authenticateToken, (req, res) => {
    res.json({ valid: true, userId: req.userId });
});

export default router;