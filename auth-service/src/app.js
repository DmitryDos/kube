import express from 'express';
import authRoutes from './routes/auth.js';
import pool from './utils/database.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

app.use('/api/auth', authRoutes);

app.get('/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ status: 'OK', service: 'auth-service', database: 'connected' });
    } catch (error) {
        res.status(500).json({ status: 'ERROR', service: 'auth-service', database: 'disconnected' });
    }
});

app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

const server = app.listen(PORT, () => {
    console.log(`Auth service running on port ${PORT}`);
});

const gracefulShutdown = async (signal) => {
    console.log(`Received ${signal}, shutting down gracefully...`);
    
    server.close(async () => {
        console.log('HTTP server closed');
        
        if (pool) {
            await pool.end();
            console.log('Database connection pool closed');
        }
        
        process.exit(0);
    });
    
    setTimeout(() => {
        console.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
    }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));