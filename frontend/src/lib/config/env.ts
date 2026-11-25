// Validación de entorno del proceso web (CICD §3.4). Único lugar del frontend que lee process.env (DC-07).
import 'server-only';

import { z } from 'zod';

import { logger } from '../observability/logger';

const CONFIG_EXIT_CODE = 78;
const REMOTE = new Set(['staging', 'production']);

const text = z.string().min(1);
const keyList = z
  .string()
  .regex(
    /^\d+:[A-Za-z0-9+/]{43}=(,\d+:[A-Za-z0-9+/]{43}=)?$/,
    'formato version:base64 de 32 bytes',
  );

const webShape = z.object({
  APP_ENV: z.enum(['development', 'test', 'staging', 'production']),
  NODE_ENV: z.enum(['development', 'production', 'test']),
  TZ: z.literal('UTC'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  FEATURE_E2_ENABLED: z
    .enum(['true', 'false'])
    .default('false')
    .transform((v) => v === 'true'),
  AUTH0_ISSUER_BASE_URL: z.url(),
  AUTH0_BACKCHANNEL_BASE_URL: z.url().optional(),
  AUTH0_AUDIENCE: text,
  AUTH0_CLIENT_ID: text,
  AUTH0_CLIENT_SECRET: z.string().min(32),
  SESSION_COOKIE_KEYS: keyList,
  SESSION_IDLE_TIMEOUT_SECONDS: z.coerce.number().int().min(300).max(86400).default(86400),
  APP_BASE_URL: z.url(),
  API_BASE_URL: z.url(),
  CLOUDINARY_UPLOAD_BASE_URL: z.url(),
  MAPS_PROVIDER: z.enum(['disabled', 'google']).default('disabled'),
  MAPS_BROWSER_KEY: text.optional(),
});

const webEnvSchema = webShape.superRefine((env, ctx) => {
  const fail = (path: string, message: string): void => {
    ctx.addIssue({ code: 'custom', path: [path], message });
  };
  if (env.MAPS_PROVIDER === 'google' && env.MAPS_BROWSER_KEY === undefined) {
    fail('MAPS_BROWSER_KEY', 'variable condicional ausente');
  }
  if (!REMOTE.has(env.APP_ENV)) return;
  if (env.NODE_ENV !== 'production') fail('NODE_ENV', 'opción solo local');
  if (env.AUTH0_BACKCHANNEL_BASE_URL !== undefined) {
    fail('AUTH0_BACKCHANNEL_BASE_URL', 'opción solo local');
  }
  for (const name of [
    'APP_BASE_URL',
    'AUTH0_ISSUER_BASE_URL',
    'CLOUDINARY_UPLOAD_BASE_URL',
  ] as const) {
    if (!env[name].startsWith('https://')) fail(name, 'opción solo local');
  }
});

export type WebEnv = z.infer<typeof webEnvSchema>;

let cached: Readonly<WebEnv> | undefined;

/** Termina el proceso con código 78 y registra solo nombres y motivos, nunca valores. */
export function getEnv(): Readonly<WebEnv> {
  if (cached !== undefined) return cached;
  const source = Object.fromEntries(Object.entries(process.env).filter(([, v]) => v !== ''));
  const unresolved = Object.entries(source)
    .filter(([, value]) => value?.includes('__GENERATE') === true)
    .map(([name]) => `${name}: marcador sin generar`);
  const result = webEnvSchema.safeParse(source);
  if (!result.success || unresolved.length > 0) {
    const problems = result.success
      ? unresolved
      : [...unresolved, ...result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`)];
    logger.fatal({ problems }, 'Configuración de entorno no válida');
    process.exit(CONFIG_EXIT_CODE);
  }
  cached = Object.freeze(result.data);
  return cached;
}
