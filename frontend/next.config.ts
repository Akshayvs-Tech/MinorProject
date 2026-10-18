import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    // In Docker, BACKEND_URL is set to http://backend:8000 via environment variable.
    // Locally (without Docker), it falls back to http://localhost:8000.
    const backendUrl = process.env.BACKEND_URL || "http://localhost:8000";
    return [
      {
        source: "/api/:path*",
        destination: `${backendUrl}/:path*`,
      },
    ];
  },
};

export default nextConfig;
