// Valida la declaración del stack sin levantarlo; ISS-TEST-002 añade las comprobaciones en vivo.
import { execFileSync } from 'node:child_process';

import { describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

describe('humo: Compose', () => {
  it('declara los 18 servicios de CICD §5.4', () => {
    const output = execFileSync(
      'docker',
      [
        'compose',
        '--env-file',
        'docker/images.env',
        '--env-file',
        '.env',
        '--profile',
        'dev',
        '--profile',
        'test',
        '--profile',
        'tools',
        'config',
        '--services',
      ],
      { cwd: REPO_ROOT, encoding: 'utf8' },
    );
    expect(output.trim().split('\n')).toHaveLength(18);
  });
});
