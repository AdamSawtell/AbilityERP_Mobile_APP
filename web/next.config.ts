import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Ensure Amplify build injects server env for API routes
  env: {
    API_BASE_URL: process.env.API_BASE_URL,
  },
};

export default nextConfig;
