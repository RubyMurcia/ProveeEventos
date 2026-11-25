// DC-08 (CICD §3.4): los esquemas de entorno y .env.example no pueden divergir.
import { readFileSync } from 'node:fs';
import path from 'node:path';

import { describe, expect, it } from 'vitest';

import { ENV_KEYS } from '../../../shared/config/env.js';
import { REPO_ROOT } from '../../support/images.js';

const read = (file: string): string => readFileSync(path.join(REPO_ROOT, file), 'utf8');

const exampleKeys = [...read('.env.example').matchAll(/^([A-Z0-9_]+)=/gm)].map((m) => m[1] ?? '');

const webBlock = /const webShape = z\.object\(\{(.*?)\n\}\);/s.exec(
  read('frontend/src/lib/config/env.ts'),
);
const webKeys = [...(webBlock?.[1] ?? '').matchAll(/^ {2}([A-Z0-9_]+):/gm)].map((m) => m[1] ?? '');

// CICD §3.2, "En .env = no": las fija o deriva docker-compose.yml.
const DERIVED = [
  'NODE_ENV',
  'TZ',
  'WORKER_HEALTH_PORT',
  'DATABASE_URL',
  'RETENTION_DATABASE_URL',
  'DIRECT_URL',
  'REDIS_URL',
  'API_BASE_URL',
  'DOCUMENT_STORAGE_PATH',
];
// Solo las consumen Compose, la base de datos, Redis o los dobles locales.
const INFRA_ONLY = [
  'WEB_PORT',
  'MAILPIT_UI_PORT',
  'DEV_STUBS_PORT',
  'POSTGRES_DB',
  'POSTGRES_USER',
  'POSTGRES_PASSWORD',
  'PE_MIGRATOR_PASSWORD',
  'PE_API_PASSWORD',
  'PE_WORKER_PASSWORD',
  'PE_RETENTION_PASSWORD',
  'PE_READONLY_PASSWORD',
  'DB_APPLY_RLS',
  'REDIS_PASSWORD',
  'DEV_SENDGRID_WEBHOOK_PRIVATE_KEY',
];

const schemaKeys = new Set([...ENV_KEYS.api, ...ENV_KEYS.worker, ...ENV_KEYS.seed, ...webKeys]);

describe('DC-08 esquemas de entorno frente a .env.example', () => {
  it('analiza claves en ambos lados', () => {
    expect(exampleKeys.length).toBeGreaterThan(50);
    expect(webKeys.length).toBeGreaterThan(10);
  });

  it('toda clave de .env.example la consume un esquema o es solo de infraestructura', () => {
    expect(
      exampleKeys.filter((key) => !schemaKeys.has(key) && !INFRA_ONLY.includes(key)),
    ).toStrictEqual([]);
  });

  it('toda clave de los esquemas está en .env.example o la deriva Compose', () => {
    const declared = new Set([...exampleKeys, ...DERIVED]);
    expect([...schemaKeys].filter((key) => !declared.has(key))).toStrictEqual([]);
  });

  it('toda clave esperada por Compose existe en .env.example o en docker/images.env', () => {
    const images = [...read('docker/images.env').matchAll(/^([A-Z0-9_]+)=/gm)].map(
      (m) => m[1] ?? '',
    );
    const used = [...read('docker-compose.yml').matchAll(/(?<!\$)\$\{([A-Z0-9_]+)/g)].map(
      (m) => m[1] ?? '',
    );
    const known = new Set([...exampleKeys, ...images, 'HOST_UID', 'HOST_GID', 'SEED_SYNTHETIC']);
    expect(used.length).toBeGreaterThan(40);
    expect([...new Set(used)].filter((key) => !known.has(key))).toStrictEqual([]);
  });
});
