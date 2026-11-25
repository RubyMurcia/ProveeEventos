import path from 'node:path';

import type { NextConfig } from 'next';

const NO_STORE_HEADERS = [
  { key: 'Cache-Control', value: 'no-store' },
  { key: 'Referrer-Policy', value: 'no-referrer' },
];

const SECURITY_HEADERS = [
  {
    key: 'Content-Security-Policy',
    value: "frame-ancestors 'none'; object-src 'none'; base-uri 'self'",
  },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
];

const nextConfig: NextConfig = {
  output: 'standalone',
  outputFileTracingRoot: path.join(import.meta.dirname, '..'),
  poweredByHeader: false,
  // El lint corre con la configuración raíz en `npm run verify:lint`, no dentro de `next build`.
  eslint: { ignoreDuringBuilds: true },
  headers() {
    // ADR-SEC-004 R5 y UXUI §11.2. La directiva script-src con nonce llega con el middleware.
    return Promise.resolve([
      { source: '/:path*', headers: SECURITY_HEADERS },
      { source: '/r', headers: NO_STORE_HEADERS },
      { source: '/invitacion', headers: NO_STORE_HEADERS },
    ]);
  },
};

export default nextConfig;
