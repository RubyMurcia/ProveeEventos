// ADR-ARCH-001 R1, R2.
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

import { describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

const SRC = path.join(REPO_ROOT, 'backend/src');
const MODULES = [
  'administration-audit',
  'assisted-response',
  'availability-booking',
  'event-management',
  'identity-access',
  'messaging-notifications',
  'organizations',
  'provider-catalog',
  'quotation',
  'reviews',
  'rfq-offers',
  'taxonomy-templates',
];
const LAYERS = /^[^/]+\/([^/]+\/)?(domain|application|infrastructure|http)\//;

const files = (root: string): string[] =>
  readdirSync(root, { recursive: true, withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => path.relative(root, path.join(entry.parentPath, entry.name)));

const product = files(SRC).filter(
  (file) => file.endsWith('.ts') && !/^(tests|prisma\/generated)\//.test(file),
);

describe('TC-ARCH monolito modular', () => {
  it('contiene exactamente los doce módulos', () => {
    const found = readdirSync(path.join(SRC, 'modules'), { withFileTypes: true });
    expect(
      found
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .sort(),
    ).toStrictEqual(MODULES);
  });

  it('cada módulo tiene sus cuatro capas', () => {
    for (const name of MODULES) {
      const layers = readdirSync(path.join(SRC, 'modules', name));
      expect(layers).toEqual(
        expect.arrayContaining(['domain', 'application', 'infrastructure', 'http']),
      );
    }
  });

  it('ningún archivo de un módulo queda fuera de una capa o de index.ts', () => {
    const unclassified = files(path.join(SRC, 'modules')).filter(
      (file) => file.endsWith('.ts') && !LAYERS.test(file) && !/^[^/]+\/index\.ts$/.test(file),
    );
    expect(unclassified).toStrictEqual([]);
  });

  it('solo server.ts y worker.ts arrancan un proceso', () => {
    expect(product.length).toBeGreaterThan(5);
    const containing = (pattern: RegExp): string[] =>
      product.filter((file) => pattern.test(readFileSync(path.join(SRC, file), 'utf8')));
    expect(containing(/\.listen\(/)).toStrictEqual(['bootstrap/listen.ts']);
    expect(containing(/from '\.\/listen\.js'/).sort()).toStrictEqual([
      'bootstrap/server.ts',
      'bootstrap/worker.ts',
    ]);
  });

  it('no hay JavaScript en el código fuente (ADR-STACK-002 R3; los guiones k6 son la excepción de TESTs §15.3)', () => {
    const javascript = ['backend/src', 'frontend/src']
      .flatMap((dir) => files(path.join(REPO_ROOT, dir)).map((file) => `${dir}/${file}`))
      .filter((file) => /\.(js|cjs|mjs|jsx)$/.test(file))
      .filter((file) => !/^backend\/src\/(tests\/load|prisma\/generated)\//.test(file));
    expect(javascript).toStrictEqual([]);
  });
});
