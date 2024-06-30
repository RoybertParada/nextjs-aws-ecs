/** @type {import('next').NextConfig} */
const nextConfig = {
    env: {
      ENVIRONMENT_NAME: process.env.ENVIRONMENT_NAME
    }
};

export default nextConfig;