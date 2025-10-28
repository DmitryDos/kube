import redis from 'redis';

const redisClient = redis.createClient({
    socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        reconnectStrategy: (retries) => {
            if (retries > 10) {
                console.error('Redis: Max reconnection attempts reached');
                return new Error('Redis connection failed after max retries');
            }
            const delay = Math.min(retries * 50, 1000);
            console.log(`Redis: Reconnecting in ${delay}ms (attempt ${retries})`);
            return delay;
        }
    },
    password: process.env.REDIS_PASSWORD || undefined
});

redisClient.on('error', (err) => {
    console.error('Redis error:', err);
});

redisClient.on('connect', () => {
    console.log('Redis: Connected');
});

redisClient.on('ready', () => {
    console.log('Redis: Ready');
});

redisClient.on('reconnecting', () => {
    console.log('Redis: Reconnecting...');
});

let isConnected = false;

async function connectRedis() {
    if (isConnected) {
        return redisClient;
    }

    try {
        await redisClient.connect();
        isConnected = true;
        console.log('Redis: Connection established');
        return redisClient;
    } catch (error) {
        console.error('Redis: Failed to connect', error);
        return redisClient;
    }
}

connectRedis();

process.on('SIGTERM', async () => {
    console.log('Redis: Closing connection on SIGTERM');
    await redisClient.quit();
});

process.on('SIGINT', async () => {
    console.log('Redis: Closing connection on SIGINT');
    await redisClient.quit();
});

export default redisClient;