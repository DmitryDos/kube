/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  
  // Turbopack configuration (empty to silence warning)
  turbopack: {},
  
  // Environment variables
  env: {
    VERSION: process.env.VERSION,
    CDN_PATH: process.env.CDN_PATH,
  },

  // Generate build ID from version if provided
  generateBuildId: process.env.VERSION
    ? async () => process.env.VERSION
    : undefined,

  // Rewrites removed - using API routes for video streaming instead
  // Video streaming goes directly to cloud API Gateway via API routes

  // Headers
  async headers() {
    const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
    
    // Базовые security заголовки для всех путей
    const securityHeaders = [
      {
        key: 'X-DNS-Prefetch-Control',
        value: 'on',
      },
      {
        key: 'Referrer-Policy',
        value: 'strict-origin-when-cross-origin',
      },
      {
        key: 'X-Content-Type-Options',
        value: 'nosniff',
      },
      {
        key: 'X-Frame-Options',
        value: 'DENY',
      },
      {
        key: 'X-XSS-Protection',
        value: '1; mode=block',
      },
      {
        key: 'Permissions-Policy',
        value: 'camera=(), microphone=(), geolocation=()',
      },
    ];
    
    return [
      {
        // Базовые security заголовки для всех путей
        // CSP временно отключен для диагностики SSL проблем
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },

  typescript: {
    ignoreBuildErrors: true,
  },

  images: {
    remotePatterns: [
      {
        protocol: 'http',
        hostname: '**',
      },
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
  },
};

export default nextConfig;

