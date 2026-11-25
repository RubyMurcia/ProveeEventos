import { type DestinationStream, type Logger, pino } from 'pino';

/** Lista de redacción centralizada (ADR-OBS-002 R1, R2). Ampliarla exige aprobación humana. */
export const REDACTED_FIELDS: readonly string[] = [
  'password',
  'token',
  'accessToken',
  'refreshToken',
  'idToken',
  'secret',
  'clientSecret',
  'apiKey',
  'authorization',
  'cookie',
  'set-cookie',
  'magicLink',
  'signature',
  'email',
  'phone',
  'DATABASE_URL',
  'DIRECT_URL',
  'RETENTION_DATABASE_URL',
  'REDIS_URL',
];

const REDACTION_PATHS = REDACTED_FIELDS.flatMap((field) => {
  const key = field.includes('-') ? `["${field}"]` : field;
  const join = (prefix: string): string =>
    key.startsWith('[') ? `${prefix}${key}` : `${prefix}.${key}`;
  return [key, join('*'), join('*.*')];
});

export interface LoggerOptions {
  readonly level?: string;
  readonly service: string;
  readonly destination?: DestinationStream;
}

/** Logger JSON de la aplicación (ADR-OBS-001 R1). */
export function createLogger({ level = 'info', service, destination }: LoggerOptions): Logger {
  const options = {
    level,
    base: { service },
    redact: { paths: REDACTION_PATHS, censor: '[REDACTADO]' },
  };
  return destination === undefined ? pino(options) : pino(options, destination);
}

export type { Logger };
