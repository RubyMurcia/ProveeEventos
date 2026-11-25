// ADR-TEST-001 R2: cada regla de Capa 1 tiene un fixture inválido que falla y uno válido que pasa.
import { cpSync, mkdtempSync, rmSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

import { ESLint, type Linter } from 'eslint';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

const FIXTURES = path.join(import.meta.dirname, 'fixtures/eslint');
const M = 'backend/src/modules';
const Q = `${M}/quotation`;

// archivo inválido → regla que debe dispararse y, si hace falta, fragmento del mensaje
const CASES: readonly (readonly [string, string, string?])[] = [
  [`${Q}/domain/layer.ts`, 'boundaries/dependencies'],
  [`${M}/administration-audit/infrastructure/audit.ts`, 'pe/prisma-model-ownership', 'createMany'],
  [`${Q}/infrastructure/sql-delete.ts`, 'pe/delete-allowlist'],
  [`${Q}/http/token-route.ts`, 'no-restricted-syntax', 'ADR-SEC-004 R3'],
  [`${Q}/http/passthrough.ts`, 'no-restricted-syntax', 'ADR-API-002'],
  [`${Q}/application/raw-sql.ts`, 'no-restricted-syntax', 'ADR-DATA-010 R1'],
  [`${Q}/infrastructure/new-client.ts`, 'no-restricted-syntax', 'ADR-STACK-004'],
  [`${Q}/infrastructure/enqueue.ts`, 'no-restricted-syntax', 'ADR-DATA-006'],
  [`${Q}/application/provider-url.ts`, 'no-restricted-syntax', 'ADR-ARCH-006'],
  [`${Q}/infrastructure/jwt.ts`, 'no-restricted-syntax', 'ADR-SEC-001'],
  [`${Q}/infrastructure/unverified.ts`, 'no-restricted-imports', 'ADR-SEC-001'],
  [`${Q}/infrastructure/log-request.ts`, 'no-restricted-syntax', 'ADR-OBS-002'],
  [`${Q}/infrastructure/dynamic.ts`, 'no-restricted-syntax', 'ADR-ARCH-002'],
  [`${Q}/infrastructure/new-function.ts`, 'no-new-func'],
  [`${Q}/infrastructure/implied-eval.ts`, '@typescript-eslint/no-implied-eval'],
  ['backend/src/tests/unit/trivial.spec.ts', 'no-restricted-syntax', 'AS-01'],
  ['frontend/src/features/cookie.ts', 'no-restricted-syntax', 'ADR-SEC-002'],
  [`${Q}/domain/prisma.ts`, 'no-restricted-imports', 'ADR-ARCH-002'],
  [`${Q}/application/framework.ts`, 'no-restricted-imports', 'ADR-ARCH-002 R2'],
  [`${Q}/application/sdk.ts`, 'no-restricted-imports', 'ADR-ARCH-006'],
  [`${Q}/application/clock.ts`, 'no-restricted-syntax', 'ADR-DATA-012'],
  [`${Q}/application/money.ts`, 'no-restricted-syntax', 'ADR-DATA-013'],
  [`${Q}/domain/offset.ts`, 'no-restricted-syntax', 'ADR-DATA-012 R3'],
  [`${Q}/application/transaction.ts`, 'pe/no-io-in-transaction'],
  [`${M}/rfq-offers/application/cross.ts`, 'boundaries/dependencies'],
  [`${Q}/http/loose.ts`, 'no-restricted-syntax', 'ADR-API-002'],
  [`${Q}/http/status.ts`, 'no-restricted-syntax', 'ADR-API-003'],
  [`${Q}/http/raw-body.ts`, 'pe/validate-request'],
  [`${Q}/http/infra.ts`, 'boundaries/dependencies'],
  [`${Q}/infrastructure/unsafe-sql.ts`, 'no-restricted-syntax', 'ADR-DATA-010'],
  [`${Q}/infrastructure/serializable.ts`, 'no-restricted-syntax', 'ADR-DATA-003'],
  [`${Q}/infrastructure/foreign-model.ts`, 'pe/prisma-model-ownership'],
  [`${Q}/infrastructure/computed-model.ts`, 'pe/prisma-model-ownership'],
  [`${Q}/infrastructure/no-tenant.ts`, 'pe/tenant-wrapper'],
  [`${Q}/infrastructure/hard-delete.ts`, 'pe/delete-allowlist'],
  [`${Q}/infrastructure/session.ts`, 'pe/no-session-set'],
  [`${M}/availability-booking/infrastructure/booking.repository.ts`, 'pe/capacity-write-owner'],
  [`${Q}/infrastructure/console.ts`, 'no-console'],
  [`${Q}/infrastructure/stdout.ts`, 'no-restricted-syntax', 'ADR-OBS-001'],
  [`${Q}/infrastructure/logger.ts`, 'no-restricted-imports', 'ADR-OBS-001'],
  [`${Q}/infrastructure/suppression.ts`, 'pe/no-suppression-comments'],
  [`${Q}/infrastructure/ts-comment.ts`, '@typescript-eslint/ban-ts-comment'],
  [`${Q}/infrastructure/coverage-comment.ts`, 'pe/no-suppression-comments'],
  [`${Q}/infrastructure/format-comment.ts`, 'pe/no-suppression-comments'],
  [`${Q}/infrastructure/explicit-any.ts`, '@typescript-eslint/no-explicit-any'],
  [`${Q}/infrastructure/evaluate.ts`, 'no-eval'],
  [`${Q}/infrastructure/child.ts`, 'no-restricted-imports', 'ADR-SEC-007'],
  [`${Q}/infrastructure/banned.ts`, 'no-restricted-imports', 'ADR-ARCH-010'],
  [`${Q}/infrastructure/random.ts`, 'no-restricted-syntax', 'ADR-SEC-004'],
  [`${Q}/infrastructure/env.ts`, 'no-restricted-properties'],
  [`${Q}/domain/exhaustive.ts`, '@typescript-eslint/switch-exhaustiveness-check'],
  ['backend/src/rogue.ts', 'boundaries/no-unknown-files'],
  ['backend/src/tests/unit/skipped.spec.ts', 'vitest/no-disabled-tests'],
  ['backend/src/tests/unit/skipped.spec.ts', 'no-restricted-syntax', 'ADR-TEST-006'],
  ['backend/src/tests/unit/focused.spec.ts', 'vitest/no-focused-tests'],
  ['backend/src/tests/integration/mocked.spec.ts', 'no-restricted-syntax', 'ADR-TEST-002'],
  ['frontend/src/components/widget.tsx', 'pe/api-client-server-only'],
  ['frontend/src/features/storage.ts', 'no-restricted-syntax', 'ADR-SEC-002'],
  ['frontend/src/features/raw-html.tsx', 'no-restricted-syntax', 'ADR-SEC-007'],
  ['frontend/src/features/backend.ts', 'no-restricted-imports', 'ADR-ARCH-008'],
];

type Results = Map<string, Linter.LintMessage[]>;
const directories: string[] = [];

/** Monta un repositorio desechable y lo analiza con la configuración raíz real. */
async function lintTree(kind: 'valid' | 'invalid'): Promise<Results> {
  const root = mkdtempSync(path.join(tmpdir(), `pe-eslint-${kind}-`));
  directories.push(root);
  cpSync(path.join(FIXTURES, 'support'), root, { recursive: true });
  cpSync(path.join(FIXTURES, kind), root, { recursive: true });
  for (const file of [
    'tsconfig.base.json',
    'backend/tsconfig.json',
    'frontend/tsconfig.json',
    'backend/package.json',
    'frontend/package.json',
    'package.json',
  ]) {
    cpSync(path.join(REPO_ROOT, file), path.join(root, file));
  }
  symlinkSync(path.join(REPO_ROOT, 'node_modules'), path.join(root, 'node_modules'));
  const configUrl = path.join(REPO_ROOT, 'eslint.config.mjs');
  const { createConfig } = (await import(configUrl)) as {
    createConfig: (dir: string) => Linter.Config[];
  };
  const eslint = new ESLint({
    cwd: root,
    overrideConfigFile: true,
    overrideConfig: createConfig(root),
    allowInlineConfig: false,
  });
  const results = await eslint.lintFiles(['backend/src/**/*.ts', 'frontend/src/**/*.{ts,tsx}']);
  return new Map(results.map((result) => [path.relative(root, result.filePath), result.messages]));
}

describe('TC-ARCH reglas ESLint de Capa 1', () => {
  let invalid: Results;
  let valid: Results;
  beforeAll(async () => {
    invalid = await lintTree('invalid');
    valid = await lintTree('valid');
  });
  afterAll(() => {
    for (const directory of directories) rmSync(directory, { recursive: true, force: true });
  });

  it('analiza archivos en ambos árboles (nunca cero)', () => {
    expect(invalid.size).toBeGreaterThan(40);
    expect(valid.size).toBeGreaterThan(15);
  });

  const cases = CASES.map(([file, rule, fragment]) => ({ file, rule, fragment: fragment ?? '' }));

  it.each(cases)('$file falla por $rule', ({ file, rule, fragment }) => {
    const matches = (invalid.get(file) ?? []).filter(
      (message) => message.ruleId === rule && message.message.includes(fragment),
    );
    expect(matches, JSON.stringify(invalid.get(file))).not.toHaveLength(0);
  });

  it('los fixtures válidos no producen ningún hallazgo', () => {
    const findings = [...valid].flatMap(([file, messages]) =>
      messages.map((message) => `${file}: ${message.ruleId ?? 'parser'} ${message.message}`),
    );
    expect(findings).toStrictEqual([]);
  });
});
