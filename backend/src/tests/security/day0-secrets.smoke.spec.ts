// Humo de seguridad: la plantilla de entorno no contiene secretos reales (ADR-SEC-005).
import { readFileSync } from 'node:fs';
import path from 'node:path';

import { describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

const read = (file: string): string => readFileSync(path.join(REPO_ROOT, file), 'utf8');
const SECRET = /(PASSWORD|SECRET|_KEY|_KEYS)(=)/;

describe('humo: secretos', () => {
  it('en .env.example todo secreto es un marcador o está vacío', () => {
    const lines = read('.env.example')
      .split('\n')
      .filter((l) => SECRET.test(l) && !l.startsWith('CLOUDINARY_API_KEY='));
    expect(lines.length).toBeGreaterThan(10);
    expect(lines.filter((l) => !/=("?(\d+:)?__GENERATE_\w+__"?)?$/.test(l))).toStrictEqual([]);
  });

  it('.gitignore excluye .env y las claves', () => {
    const ignored = read('.gitignore').split('\n');
    expect(ignored).toEqual(expect.arrayContaining(['.env', '.env.*', '!.env.example', '*.pem']));
  });
});
