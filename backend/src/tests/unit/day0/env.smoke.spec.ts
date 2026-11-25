import { describe, expect, it } from 'vitest';

import {
  apiEnvSchema,
  loadEnv,
  seedEnvSchema,
  workerEnvSchema,
} from '../../../shared/config/env.js';
import { apiSource, seedSource, workerSource } from '../../support/env.js';

class Rejected extends Error {
  constructor(readonly problems: readonly string[]) {
    super(problems.join('; '));
  }
}
const reject = (problems: readonly string[]): never => {
  throw new Rejected(problems);
};
const problemsOf = (run: () => unknown): string => {
  try {
    run();
  } catch (error) {
    if (error instanceof Rejected) return error.message;
    throw error;
  }
  return '';
};

describe('humo: validación de entorno', () => {
  it('acepta los tres procesos con valores sintéticos y los congela', () => {
    const api = loadEnv(apiEnvSchema, apiSource(), reject);
    expect(api.API_PORT).toBe(4000);
    expect(Object.isFrozen(api)).toBe(true);
    expect(loadEnv(workerEnvSchema, workerSource(), reject).WORKER_HEALTH_PORT).toBe(4001);
    expect(loadEnv(seedEnvSchema, seedSource(), reject).SEED_SYNTHETIC).toBe(false);
  });

  it.each([
    ['ENV-01', { APP_ENV: 'production' }, 'EMAIL_PROVIDER: opción solo local'],
    ['ENV-01', { APP_ENV: 'staging', DEV_X: '1' }, 'DEV_X: opción solo local'],
    [
      'ENV-01',
      { APP_ENV: 'staging', SEED_SYNTHETIC: 'true', SENDGRID_API_BASE_URL: 'https://x.test' },
      'SEED_SYNTHETIC',
    ],
    ['ENV-02', { EMAIL_FROM_NAME: '__GENERATE_HEX__' }, 'EMAIL_FROM_NAME: marcador sin generar'],
    ['ENV-03', { SMTP_HOST: '', SMTP_PORT: '' }, 'SMTP_HOST'],
    ['ENV-03', { EMAIL_PROVIDER: 'sendgrid' }, 'SENDGRID_API_KEY'],
    ['ENV-05', { DATABASE_URL: 'postgresql://pe_owner:x@db:5432/p' }, 'usuario pe_worker'],
    ['ENV-05', { DATABASE_URL: 'no-es-url' }, 'DATABASE_URL'],
    ['ENV-06', { TOKEN_DERIVATION_ACTIVE_VERSION: '2' }, 'versión de clave inexistente'],
    ['ENV-07', { WORKER_CONCURRENCY: '11' }, 'pool insuficiente'],
    ['ENV-08', { APP_ENV: 'production' }, 'almacenamiento no definido'],
  ])('%s rechaza la configuración', (_rule, overrides, expected) => {
    const source = { ...workerSource(), ...overrides };
    expect(problemsOf(() => loadEnv(workerEnvSchema, source, reject))).toContain(expected);
  });

  it('ENV-04 exige la clave de mapas', () => {
    const source = { ...apiSource(), MAPS_PROVIDER: 'google' };
    expect(problemsOf(() => loadEnv(apiEnvSchema, source, reject))).toContain(
      'GOOGLE_MAPS_SERVER_KEY',
    );
  });

  it('nunca incluye el valor recibido en el mensaje', () => {
    const source = {
      ...apiSource(),
      DOCUMENT_URL_SIGNING_KEY: 'valor-corto-secreto',
      REDIS_URL: 'redis://sin-clave',
    };
    const message = problemsOf(() => loadEnv(apiEnvSchema, source, reject));
    expect(message).toContain('DOCUMENT_URL_SIGNING_KEY');
    expect(message).not.toContain('valor-corto-secreto');
    expect(message).not.toContain('sin-clave');
  });
});
