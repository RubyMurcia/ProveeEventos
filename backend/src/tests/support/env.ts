// Entornos sintéticos para pruebas: valores ficticios, nunca secretos.
const KEY = `1:${Buffer.alloc(32, 7).toString('base64')}`;
const FAKE = 'x'.repeat(40);

const shared = {
  APP_ENV: 'test',
  NODE_ENV: 'test',
  TZ: 'UTC',
  REDIS_URL: `redis://:${FAKE}@redis:6379/0`,
  APP_BASE_URL: 'http://localhost:3000',
  TOKEN_DERIVATION_KEYS: KEY,
  TOKEN_DERIVATION_ACTIVE_VERSION: '1',
  DOCUMENT_STORAGE_DRIVER: 'local',
  DOCUMENT_STORAGE_PATH: '/var/lib/pe/documents',
};

export const apiSource = (): Record<string, string> => ({
  ...shared,
  DATABASE_URL: `postgresql://pe_api:${FAKE}@pgbouncer:5432/proveeeventos`,
  AUTH0_ISSUER_BASE_URL: 'http://localhost:4010',
  AUTH0_AUDIENCE: 'https://api.proveeeventos.test',
  TRUSTED_PROXY_CIDRS: '172.16.0.0/12',
  SENDGRID_WEBHOOK_PUBLIC_KEY: 'clave-publica-ficticia',
  CLOUDINARY_CLOUD_NAME: 'pe-local',
  CLOUDINARY_API_KEY: 'pe-local-key',
  CLOUDINARY_API_SECRET: FAKE,
  CLOUDINARY_UPLOAD_BASE_URL: 'http://localhost:4010/cloudinary',
  CLOUDINARY_API_BASE_URL: 'http://dev-stubs:4010/cloudinary',
  MEDIA_MAX_IMAGE_BYTES: '10485760',
  MEDIA_MAX_VIDEO_BYTES: '104857600',
  MEDIA_MAX_VIDEO_SECONDS: '60',
  DOCUMENT_URL_SIGNING_KEY: FAKE,
});

export const workerSource = (): Record<string, string> => ({
  ...shared,
  DATABASE_URL: `postgresql://pe_worker:${FAKE}@pgbouncer:5432/proveeeventos`,
  RETENTION_DATABASE_URL: `postgresql://pe_retention:${FAKE}@pgbouncer:5432/proveeeventos`,
  EMAIL_PROVIDER: 'smtp',
  EMAIL_FROM_ADDRESS: 'no-reply@proveeeventos.test',
  SMTP_HOST: 'mailpit',
  SMTP_PORT: '1025',
});

export const seedSource = (): Record<string, string> => ({
  APP_ENV: 'test',
  TZ: 'UTC',
  DIRECT_URL: `postgresql://pe_migrator:${FAKE}@postgres:5432/proveeeventos`,
});
