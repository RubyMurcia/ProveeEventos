// Validación de entorno del proceso web (CICD §3.4). Único lugar del frontend que lee process.env (DC-07).
import 'server-only';

import { z } from 'zod';

import { logger } from '../observability/logger';

const CONFIG_EXIT_CODE = 78;
const REMOTE = new Set(['staging', 'production']);
const PUBLIC_URLS = ['APP_BASE_URL', 'AUTH0_ISSUER_BASE_URL', 'CLOUDINARY_UPLOAD_BASE_URL'];
const LOCAL_ONLY = ['AUTH0_BACKCHANNEL_BASE_URL', 'SENDGRID_API_BASE_URL'];

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

/** Reglas que dependen del valor crudo: ENV-01 y ENV-02 (CICD §3.4). */
function sourceProblems(source: Readonly<Record<string, string | undefined>>): string[] {
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

const webEnvSchema = webShape.superRefine((env, ctx) => {
  if (env.MAPS_PROVIDER === 'google' && env.MAPS_BROWSER_KEY === undefined) {
    ctx.addIssue({
      code: 'custom',
      path: ['MAPS_BROWSER_KEY'],
      message: 'variable condicional ausente',
    });
  }
});

export type WebEnv = z.infer<typeof webEnvSchema>;

let cached: Readonly<WebEnv> | undefined;

/** Termina el proceso con código 78 y registra solo nombres y motivos, nunca valores. */
export function getEnv(): Readonly<WebEnv> {
  if (cached !== undefined) return cached;
  const source = Object.fromEntries(Object.entries(process.env).filter(([, v]) => v !== ''));
  const problems = sourceProblems(source);
  const result = webEnvSchema.safeParse(source);
  if (!result.success) {
    const issues = result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`);
    logger.fatal({ problems: [...problems, ...issues] }, 'Configuración de entorno no válida');
    process.exit(CONFIG_EXIT_CODE);
  }
  if (problems.length > 0) {
    logger.fatal({ problems }, 'Configuración de entorno no válida');
    process.exit(CONFIG_EXIT_CODE);
  }
  cached = Object.freeze(result.data);
  return cached;
}
