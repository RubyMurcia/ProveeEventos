// Validación fail-fast de entorno (CICD §3.4). Único lugar del backend que lee process.env (DC-07).
import { z } from 'zod';

import { createLogger } from '../observability/logger.js';

export const CONFIG_EXIT_CODE = 78;

type Source = Readonly<Record<string, string | undefined>>;

const flag = z.enum(['true', 'false']).transform((v) => v === 'true');
const int = (min: number, max: number) => z.coerce.number().int().min(min).max(max);
const positive = int(1, Number.MAX_SAFE_INTEGER);
const text = z.string().min(1);
const secret = z.string().min(32);
const keyList = z
  .string()
  .regex(
    /^\d+:[A-Za-z0-9+/]{43}=(,\d+:[A-Za-z0-9+/]{43}=)?$/,
    'formato version:base64 de 32 bytes',
  );
const pgUrl = (user: string) =>
  z.string().refine((v) => {
    const url = URL.parse(v);
    return url?.protocol === 'postgresql:' && url.username === user;
  }, `URL postgresql con usuario ${user}`);
const redisUrl = z
  .string()
  .refine(
    (v) => URL.parse(v)?.protocol === 'redis:' && Boolean(URL.parse(v)?.password),
    'URL redis con contraseña',
  );

const base = z.object({
  APP_ENV: z.enum(['development', 'test', 'staging', 'production']),
  TZ: z.literal('UTC'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
});

const runtime = base.extend({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  FEATURE_E2_ENABLED: flag.default(false),
  DB_POOL_MAX: int(1, 50).default(10),
  REDIS_URL: redisUrl,
  APP_BASE_URL: z.url(),
  TOKEN_DERIVATION_KEYS: keyList,
  TOKEN_DERIVATION_ACTIVE_VERSION: int(1, 999),
  DOCUMENT_STORAGE_DRIVER: z.enum(['local']),
  DOCUMENT_STORAGE_PATH: z.string().startsWith('/'),
  CANCELLATION_RESPONSE_HOURS: positive.default(72),
  COMPLETION_WINDOW_DAYS: positive.default(5),
});

const apiShape = runtime.extend({
  API_PORT: int(1024, 65535).default(4000),
  DATABASE_URL: pgUrl('pe_api'),
  AUTH0_ISSUER_BASE_URL: z.url(),
  AUTH0_BACKCHANNEL_BASE_URL: z.url().optional(),
  AUTH0_AUDIENCE: text,
  TRUSTED_PROXY_CIDRS: z
    .string()
    .regex(/^[0-9a-fA-F:.]+\/\d{1,3}(,[0-9a-fA-F:.]+\/\d{1,3})*$/, 'lista de CIDR'),
  SENDGRID_WEBHOOK_PUBLIC_KEY: text,
  CLOUDINARY_CLOUD_NAME: text,
  CLOUDINARY_API_KEY: text,
  CLOUDINARY_API_SECRET: secret,
  CLOUDINARY_UPLOAD_BASE_URL: z.url(),
  CLOUDINARY_API_BASE_URL: z.url(),
  MEDIA_ALLOWED_IMAGE_TYPES: text.default('image/jpeg,image/png,image/webp'),
  MEDIA_ALLOWED_VIDEO_TYPES: text.default('video/mp4'),
  MEDIA_MAX_IMAGE_BYTES: positive,
  MEDIA_MAX_VIDEO_BYTES: positive,
  MEDIA_MAX_VIDEO_SECONDS: positive,
  DOCUMENT_URL_SIGNING_KEY: secret,
  DOCUMENT_URL_TTL_SECONDS: int(30, 900).default(300),
  MAPS_PROVIDER: z.enum(['disabled', 'google']).default('disabled'),
  GOOGLE_MAPS_SERVER_KEY: text.optional(),
  RATE_LIMIT_CATALOG_PER_MINUTE: positive.default(120),
  RATE_LIMIT_MAGIC_FAILURES_PER_10_MINUTES: positive.default(10),
  RATE_LIMIT_MAGIC_TOKEN_PER_HOUR: positive.default(20),
  RATE_LIMIT_ASSISTED_IMPORT_PER_HOUR: positive.default(30),
  RATE_LIMIT_REGISTRATION_PER_HOUR: positive.default(5),
  RATE_LIMIT_WRITES_PER_MINUTE: positive.default(300),
});

const workerShape = runtime.extend({
  WORKER_HEALTH_PORT: int(1024, 65535).default(4001),
  DATABASE_URL: pgUrl('pe_worker'),
  RETENTION_DATABASE_URL: pgUrl('pe_retention'),
  EMAIL_PROVIDER: z.enum(['sendgrid', 'smtp']),
  EMAIL_FROM_ADDRESS: z.email(),
  EMAIL_FROM_NAME: text.default('ProveeEventos'),
  SMTP_HOST: text.optional(),
  SMTP_PORT: int(1, 65535).optional(),
  SENDGRID_API_KEY: text.optional(),
  SENDGRID_API_BASE_URL: z.url().optional(),
  WORKER_CONCURRENCY: int(1, 1000).default(10),
  OUTBOX_POLL_INTERVAL_MS: int(1000, 60000).default(5000),
});

const seedShape = base.extend({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  SEED_SYNTHETIC: flag.default(false),
  DIRECT_URL: pgUrl('pe_migrator'),
});

const REMOTE = new Set(['staging', 'production']);
const PUBLIC_URLS = ['APP_BASE_URL', 'AUTH0_ISSUER_BASE_URL', 'CLOUDINARY_UPLOAD_BASE_URL'];
const LOCAL_ONLY = ['AUTH0_BACKCHANNEL_BASE_URL', 'SENDGRID_API_BASE_URL'];

/** Reglas que dependen del valor crudo: ENV-01 y ENV-02. */
function sourceProblems(source: Source): string[] {
  const problems: string[] = [];
  for (const [name, value] of Object.entries(source)) {
    if (value?.includes('__GENERATE') === true) problems.push(`${name}: marcador sin generar`);
  }
  if (!REMOTE.has(source['APP_ENV'] ?? '')) return problems;
  const fail = (name: string): number => problems.push(`${name}: opción solo local`);
  if (source['NODE_ENV'] !== undefined && source['NODE_ENV'] !== 'production') fail('NODE_ENV');
  if (source['EMAIL_PROVIDER'] === 'smtp') fail('EMAIL_PROVIDER');
  if (source['SEED_SYNTHETIC'] === 'true') fail('SEED_SYNTHETIC');
  for (const name of PUBLIC_URLS) {
    const value = source[name];
    if (value !== undefined && !value.startsWith('https://')) fail(name);
  }
  for (const name of Object.keys(source)) {
    if (LOCAL_ONLY.includes(name) || name.startsWith('DEV_')) fail(name);
  }
  return problems;
}

interface CrossFields {
  APP_ENV?: string;
  EMAIL_PROVIDER?: string | undefined;
  SMTP_HOST?: string | undefined;
  SMTP_PORT?: number | undefined;
  SENDGRID_API_KEY?: string | undefined;
  MAPS_PROVIDER?: string | undefined;
  GOOGLE_MAPS_SERVER_KEY?: string | undefined;
  TOKEN_DERIVATION_KEYS?: string | undefined;
  TOKEN_DERIVATION_ACTIVE_VERSION?: number | undefined;
  WORKER_CONCURRENCY?: number | undefined;
  DB_POOL_MAX?: number | undefined;
  DOCUMENT_STORAGE_DRIVER?: string | undefined;
}

/** ENV-03, ENV-04, ENV-06, ENV-07 y ENV-08. ENV-05 la aplican los tipos de URL. */
function applyCrossRules(env: CrossFields, ctx: z.RefinementCtx): void {
  const fail = (path: string, message: string): void => {
    ctx.addIssue({ code: 'custom', path: [path], message });
  };
  if (env.EMAIL_PROVIDER === 'smtp') {
    if (env.SMTP_HOST === undefined) fail('SMTP_HOST', 'variable condicional ausente');
    if (env.SMTP_PORT === undefined) fail('SMTP_PORT', 'variable condicional ausente');
  }
  if (env.EMAIL_PROVIDER === 'sendgrid' && env.SENDGRID_API_KEY === undefined) {
    fail('SENDGRID_API_KEY', 'variable condicional ausente');
  }
  if (env.MAPS_PROVIDER === 'google' && env.GOOGLE_MAPS_SERVER_KEY === undefined) {
    fail('GOOGLE_MAPS_SERVER_KEY', 'variable condicional ausente');
  }
  if (env.TOKEN_DERIVATION_KEYS !== undefined) {
    const versions = env.TOKEN_DERIVATION_KEYS.split(',').map((item) => item.split(':')[0]);
    if (!versions.includes(String(env.TOKEN_DERIVATION_ACTIVE_VERSION))) {
      fail('TOKEN_DERIVATION_ACTIVE_VERSION', 'versión de clave inexistente');
    }
  }
  if ((env.WORKER_CONCURRENCY ?? 0) > (env.DB_POOL_MAX ?? Number.MAX_SAFE_INTEGER)) {
    fail('WORKER_CONCURRENCY', 'pool insuficiente');
  }
  if (env.DOCUMENT_STORAGE_DRIVER === 'local' && REMOTE.has(env.APP_ENV ?? '')) {
    fail('DOCUMENT_STORAGE_DRIVER', 'almacenamiento no definido para el ambiente');
  }
}

export const apiEnvSchema = apiShape.superRefine(applyCrossRules);
export const workerEnvSchema = workerShape.superRefine(applyCrossRules);
export const seedEnvSchema = seedShape.superRefine(applyCrossRules);

/** Claves declaradas por proceso, para compararlas con .env.example (DC-08). */
export const ENV_KEYS = {
  api: Object.keys(apiShape.shape),
  worker: Object.keys(workerShape.shape),
  seed: Object.keys(seedShape.shape),
} as const;

export type ApiEnv = z.infer<typeof apiEnvSchema>;
export type WorkerEnv = z.infer<typeof workerEnvSchema>;
export type SeedEnv = z.infer<typeof seedEnvSchema>;

/** Los mensajes llevan nombres y motivos, nunca valores. */
export function loadEnv<T>(
  schema: z.ZodType<T>,
  source: Source,
  fail: (problems: readonly string[]) => never,
): Readonly<T> {
  const cleaned = Object.fromEntries(Object.entries(source).filter(([, v]) => v !== ''));
  const early = sourceProblems(cleaned);
  const result = schema.safeParse(cleaned);
  if (!result.success) {
    return fail([...early, ...result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`)]);
  }
  if (early.length > 0) return fail(early);
  return Object.freeze(result.data);
}

function abort(problems: readonly string[]): never {
  createLogger({ service: 'config' }).fatal({ problems }, 'Configuración de entorno no válida');
  process.exit(CONFIG_EXIT_CODE);
}

export const loadApiEnv = (): Readonly<ApiEnv> => loadEnv(apiEnvSchema, process.env, abort);
export const loadWorkerEnv = (): Readonly<WorkerEnv> =>
  loadEnv(workerEnvSchema, process.env, abort);
export const loadSeedEnv = (): Readonly<SeedEnv> => loadEnv(seedEnvSchema, process.env, abort);
