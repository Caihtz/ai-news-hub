/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
    ],
  },
  // Production: proxy API requests to ECS backend
  async rewrites() {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL;
    // Only use rewrites in production (no direct API URL set)
    if (!apiUrl) {
      return [
        {
          source: '/api/:path*',
          destination: 'http://8.218.212.70:3001/api/:path*',
        },
      ];
    }
    return [];
  },
  webpack: (config) => {
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': require('path').resolve(__dirname, 'src'),
    };
    return config;
  },
};

module.exports = nextConfig;