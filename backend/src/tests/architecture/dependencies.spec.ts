// ADR-ARCH-002/003: cada regla de dependency-cruiser se demuestra con un árbol que la viola.
import { cpSync, mkdtempSync, readdirSync, rmSync, symlinkSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import path from 'node:path';

import {
  cruise,
  type ICruiseOptions,
  type ICruiseResult,
  type IForbiddenRuleType,
} from 'dependency-cruiser';
import { afterAll, describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

const FIXTURES = path.join(import.meta.dirname, 'fixtures/depcruise');
const config = createRequire(import.meta.url)(path.join(REPO_ROOT, '.dependency-cruiser.cjs')) as {
  forbidden: (IForbiddenRuleType & { name: string })[];
  options: ICruiseOptions;
};
const directories: string[] = [];

async function analyse(root: string, excluded: string[]): Promise<ICruiseResult> {
  const sources = ['backend', 'frontend']
    .filter((dir) => readdirSync(root).includes(dir))
    .map((dir) => `${dir}/src`);
  const options: ICruiseOptions = {
    ...config.options,
    baseDir: root,
    ruleSet: { forbidden: config.forbidden },
    validate: true,
    exclude: { path: excluded },
  };
  delete options.tsConfig;
  const result = await cruise(sources, options);
  return result.output as ICruiseResult;
}

async function violationsIn(tree: string): Promise<{ rules: string[]; modules: number }> {
  const root = mkdtempSync(path.join(tmpdir(), 'pe-depcruise-'));
  directories.push(root);
  cpSync(path.join(FIXTURES, tree), root, { recursive: true });
  symlinkSync(path.join(REPO_ROOT, 'node_modules'), path.join(root, 'node_modules'));
  const output = await analyse(root, ['^(backend|frontend)/dist/']);
  return {
    rules: output.summary.violations.map((violation) => violation.rule.name),
    modules: output.summary.totalCruised,
  };
}

const trees = readdirSync(FIXTURES).filter((name) => name !== 'valid');

describe('TC-ARCH grafo de dependencias', () => {
  afterAll(() => {
    for (const directory of directories) rmSync(directory, { recursive: true, force: true });
  });

  it('toda regla no generada por la matriz tiene un fixture inválido', () => {
    const missing = config.forbidden
      .map((rule) => rule.name)
      .filter((name) => !name.startsWith('matrix-') && !trees.includes(name));
    expect(missing).toStrictEqual([]);
  });

  it('declara la matriz de los once módulos con dependencias restringidas', () => {
    expect(config.forbidden.filter((rule) => rule.name.startsWith('matrix-'))).toHaveLength(11);
  });

  it.each(trees)('%s detecta su violación', async (tree) => {
    const { rules, modules } = await violationsIn(tree);
    expect(modules).toBeGreaterThan(0);
    expect(rules).toContain(tree);
  });

  it('el árbol válido no tiene violaciones', async () => {
    const { rules, modules } = await violationsIn('valid');
    expect(modules).toBeGreaterThan(5);
    expect(rules).toStrictEqual([]);
  });

  it('el código real se analiza y no es un conjunto vacío (ADR-TEST-001 R3)', async () => {
    // En el repositorio real se aplican las exclusiones declaradas en la configuración.
    const output = await analyse(REPO_ROOT, (config.options.exclude as { path: string[] }).path);
    const own = output.modules.filter((module) => /^(backend|frontend)\/src\//.test(module.source));
    expect(own.length).toBeGreaterThan(10);
    expect(output.summary.violations).toStrictEqual([]);
  });
});
