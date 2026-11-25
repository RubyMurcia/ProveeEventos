import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { createApp } from '../../../bootstrap/app.js';
import { createLogger } from '../../../shared/observability/logger.js';

const lines: string[] = [];
const logger = createLogger({
  service: 'test',
  level: 'debug',
  destination: { write: (line: string) => void lines.push(line) },
});

describe('humo: salud', () => {
  it('responde /health/live sin detalles internos', async () => {
    const response = await request(createApp({ logger })).get('/health/live');
    expect(response.status).toBe(200);
    expect(response.body).toStrictEqual({ status: 'ok' });
    expect(response.headers['cache-control']).toBe('no-store');
    expect(response.headers['x-powered-by']).toBeUndefined();
  });

  it('responde 503 en /health/ready cuando una dependencia falla', async () => {
    const down = createApp({ logger, readinessChecks: [() => Promise.reject(new Error('caída'))] });
    const response = await request(down).get('/health/ready');
    expect(response.status).toBe(503);
    expect(response.body).toStrictEqual({ status: 'unavailable' });
  });

  it('responde 200 en /health/ready cuando las comprobaciones pasan', async () => {
    const up = createApp({ logger, readinessChecks: [() => Promise.resolve()] });
    const response = await request(up).get('/health/ready');
    expect(response.status).toBe(200);
  });

  it('propaga el correlationId válido y sustituye el inseguro (ADR-OBS-001 R3)', async () => {
    const app = createApp({ logger });
    const kept = await request(app).get('/health/live').set('x-correlation-id', 'abc-12345678');
    expect(kept.headers['x-correlation-id']).toBe('abc-12345678');
    const replaced = await request(app).get('/health/live').set('x-correlation-id', 'a b');
    expect(replaced.headers['x-correlation-id']).toMatch(/^[0-9a-f-]{36}$/);
    expect(lines.join('')).toContain('"correlationId":"abc-12345678"');
  });
});
