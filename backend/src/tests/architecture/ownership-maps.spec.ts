// ADR-ARCH-005 y ADR-DATA-008: los mapas de las reglas cubren el diseño completo.
import { readFileSync } from 'node:fs';
import path from 'node:path';

import { describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

const read = (file: string): string => readFileSync(path.join(REPO_ROOT, file), 'utf8');
const owners = JSON.parse(read('Tools/eslint-plugin-pe/table-ownership.json')) as Record<
  string,
  { table: string; owner: string }
>;
const tenant = (
  JSON.parse(read('Tools/eslint-plugin-pe/tenant-tables.json')) as { models: string[] }
).models;
const models = (file: string): string[] =>
  [...read(file).matchAll(/^model (\w+) \{/gm)].map(
    (m) => `${(m[1] ?? '').charAt(0).toLowerCase()}${(m[1] ?? '').slice(1)}`,
  );

describe('TC-ARCH mapas de propiedad y tenant', () => {
  const design = models('proveeeventos.prisma');

  it('hay una entrada por cada modelo del diseño', () => {
    expect(design).toHaveLength(72);
    expect(Object.keys(owners).sort()).toStrictEqual([...design].sort());
  });

  it('ningún modelo del esquema real queda sin escritor', () => {
    expect(
      models('backend/src/prisma/schema.prisma').filter((m) => owners[m] === undefined),
    ).toStrictEqual([]);
  });

  it('las 39 tablas de tenant coinciden con las de FORCE RLS del anexo', () => {
    const sql = read('proveeeventos.sql').replaceAll(/^\s*--.*$/gm, '');
    const forced = new Set(
      [...sql.matchAll(/ALTER TABLE\s+(?:public\.)?"?(\w+)"?\s+FORCE ROW LEVEL SECURITY/gi)].map(
        (m) => m[1] ?? '',
      ),
    );
    const mapped = tenant.map((model) => owners[model]?.table ?? '').sort();
    expect(mapped).toHaveLength(39);
    expect([...forced].sort()).toStrictEqual(mapped);
  });
});
