import type { NextConfig } from "next";

// Where this server finds the backend. The browser never needs this address:
// it calls /api/bro/* on the web app, which forwards here, so phones on the
// Wi-Fi only need port 3000 and nothing breaks when the PC's IP changes.
const backend = (process.env.BRO_BACKEND_INTERNAL_URL || "http://localhost:8080").replace(/\/+$/, "");

const nextConfig: NextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [{ source: "/api/bro/:path*", destination: `${backend}/:path*` }];
  },
};

export default nextConfig;
