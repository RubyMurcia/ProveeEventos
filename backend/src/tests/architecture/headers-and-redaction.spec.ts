// ADR-SEC-004 R5, ADR-SEC-007 R2 (parte declarada) y ADR-OBS-002 R2.
import path from 'node:path';
import { pathToFileURL } from 'node:url';

import { describe, expect, it } from 'vitest';

import { createLogger } from '../../shared/observability/logger.js';
import { REPO_ROOT } from '../support/images.js';

interface HeaderRule {
  readonly source: string;
  readonly headers: readonly { readonly key: string; readonly value: string }[];
}

// Carga por URL: el backend no importa código del frontend (ADR-ARCH-008).
async function headerRules(): Promise<HeaderRule[]> {
  const url = pathToFileURL(path.join(REPO_ROOT, 'frontend/next.config.ts')).href;
  const loaded = (await import(url)) as { default: { headers(): Promise<HeaderRule[]> } };
  return loaded.default.headers();
}

describe('TC-ARCH cabeceras', () => {
  it.each(['/r', '/invitacion'])('%s no se almacena ni envía referencia', async (source) => {
    const rules = await headerRules();
    const headers = Object.fromEntries(
      (rules.find((r) => r.source === source)?.headers ?? []).map((h) => [h.key, h.value]),
    );
    expect(headers).toMatchObject({
      'Cache-Control': 'no-store',
      'Referrer-Policy': 'no-referrer',
    });
  });

  it('toda ruta prohíbe el enmarcado y no permite unsafe-inline', async () => {
    const rules = await headerRules();
    const csp =
      rules
        .find((r) => r.source === '/:path*')
        ?.headers.find((h) => h.key === 'Content-Security-Policy')?.value ?? '';
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).not.toContain('unsafe-inline');
  });
});

describe('TC-ARCH redacción central', () => {
  it('censura credenciales y cabeceras sensibles', () => {
    let output = '';
    const logger = createLogger({
      service: 'test',
      destination: { write: (line: string) => void (output += line) },
    });
    logger.info({ headers: { authorization: 'Bearer abc', cookie: 'c=1' }, token: 't0k3n' });
    expect(output).not.toMatch(/Bearer abc|c=1|t0k3n/);
  });
});
