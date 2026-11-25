import { describe, expect, it } from 'vitest';

import { createLogger, REDACTED_FIELDS } from '../../../shared/observability/logger.js';

describe('humo: redacción de telemetría (ADR-OBS-002)', () => {
  it.each(REDACTED_FIELDS)('oculta %s en la raíz y anidado', (field) => {
    const lines: string[] = [];
    const logger = createLogger({
      service: 'test',
      destination: { write: (line: string) => void lines.push(line) },
    });
    logger.info({
      [field]: 'VALOR-SENSIBLE',
      a: { [field]: 'VALOR-SENSIBLE' },
      b: { c: { [field]: 'VALOR-SENSIBLE' } },
    });
    expect(lines.join('')).toContain('[REDACTADO]');
    expect(lines.join('')).not.toContain('VALOR-SENSIBLE');
  });
});
