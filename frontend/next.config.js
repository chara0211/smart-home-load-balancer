/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'standalone',
    async rewrites() {
        // Utiliser le nom de service Docker en production, localhost en développement
        const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://usage-collector-service:8083';
        return [
            {
                source: '/api/:path*',
                destination: `${backendUrl}/:path*`,
            },
        ];
    },
};

module.exports = nextConfig;