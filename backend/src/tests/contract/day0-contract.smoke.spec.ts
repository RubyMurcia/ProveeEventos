import { readFileSync } from 'node:fs';
import path from 'node:path';

import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { parseDocument } from 'yaml';

import { createApp } from '../../bootstrap/app.js';
import { createLogger } from '../../shared/observability/logger.js';
import { REPO_ROOT } from '../support/images.js';

interface Contract {
  readonly openapi: string;
  readonly paths: Record<string, unknown>;
}

const document = parseDocument(
  readFileSync(path.join(REPO_ROOT, 'ProveeEventos_API_Spec.yaml'), 'utf8'),
  // Defecto conocido del contrato (ProveeEventos_Day0_Report.md, §7): `taxRate` repite `description`.
  { uniqueKeys: false },
);
const contract = document.toJS({ maxAliasCount: -1 }) as Contract;

describe('humo: contrato', () => {
  it('carga el OpenAPI 3.1 y los endpoints operativos quedan fuera de él (SAD §10.8)', () => {
    expect(document.errors).toStrictEqual([]);
    expect(contract.openapi).toMatch(/^3\.1\./);
    const paths = Object.keys(contract.paths);
    expect(paths.length).toBeGreaterThan(100);
    expect(paths.filter((route) => route.startsWith('/health'))).toStrictEqual([]);
  });

  it('el Día 0 no expone ninguna ruta del contrato', async () => {
    const app = createApp({ logger: createLogger({ service: 'test', level: 'fatal' }) });
    const response = await request(app).get('/api/v1/me');
    expect(response.status).toBe(404);
  });
});
