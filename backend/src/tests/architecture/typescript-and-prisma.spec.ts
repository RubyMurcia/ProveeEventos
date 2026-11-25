// ADR-STACK-002 R2 y ADR-STACK-004 R2, R3, R6.
import { readFileSync } from 'node:fs';
import path from 'node:path';

import ts from 'typescript';
import { describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

const read = (file: string): string => readFileSync(path.join(REPO_ROOT, file), 'utf8');
const STRICT = [
  'noImplicitAny',
  'strictNullChecks',
  'strictFunctionTypes',
  'strictBindCallApply',
  'strictPropertyInitialization',
  'noImplicitThis',
  'useUnknownInCatchVariables',
  'alwaysStrict',
] as const;

describe('TC-ARCH tsconfig estricto', () => {
  it.each(['backend/tsconfig.json', 'backend/tsconfig.build.json', 'frontend/tsconfig.json'])(
    '%s extiende la base sin desactivar opciones',
    (file) => {
      const absolute = path.join(REPO_ROOT, file);
      const parsed = ts.getParsedCommandLineOfConfigFile(
        absolute,
        {},
        { ...ts.sys, onUnRecoverableConfigFileDiagnostic: () => undefined },
      );
      expect(parsed?.options.strict).toBe(true);
      expect(parsed?.options.noUncheckedIndexedAccess).toBe(true);
      expect(STRICT.filter((option) => parsed?.options[option] === false)).toStrictEqual([]);
    },
  );
});

describe('TC-ARCH esquema Prisma', () => {
  const schema = read('backend/src/prisma/schema.prisma').replaceAll(/\/\/.*$/gm, '');
  const block = (name: string): string =>
    new RegExp(`${name} \\w+ \\{([^}]*)\\}`).exec(schema)?.[1] ?? '';

  it('declara el generador aprobado con partialIndexes como única función preliminar', () => {
    expect(block('generator')).toMatch(/provider\s*=\s*"prisma-client"/);
    expect(block('generator')).toMatch(/output\s*=\s*"\.\/generated\/prisma"/);
    expect(block('generator')).toMatch(/previewFeatures\s*=\s*\["partialIndexes"\]/);
  });

  it('declara en datasource solo el proveedor y no usa dbgenerated', () => {
    expect(block('datasource').trim()).toMatch(/^provider\s*=\s*"postgresql"$/);
    expect(schema).not.toContain('dbgenerated');
  });
});
