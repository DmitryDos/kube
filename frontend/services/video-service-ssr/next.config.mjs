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
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin',
          },
        ],
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

