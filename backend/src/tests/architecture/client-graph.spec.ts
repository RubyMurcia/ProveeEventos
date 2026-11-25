// ADR-ARCH-008 R2: desde un módulo 'use client' no se alcanza lib/api, tampoco de forma indirecta.
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';

import ts from 'typescript';
import { describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

const sources = (root: string): string[] =>
  readdirSync(root, { recursive: true, withFileTypes: true })
    .filter((entry) => entry.isFile() && /\.tsx?$/.test(entry.name))
    .map((entry) => path.join(entry.parentPath, entry.name));

function resolveImport(root: string, from: string, specifier: string): string | undefined {
  let base: string;
  if (specifier.startsWith('@/')) base = path.join(root, specifier.slice(2));
  else if (specifier.startsWith('.')) base = path.resolve(path.dirname(from), specifier);
  else return undefined;
  const stem = base.replace(/\.js$/, '');
  return [
    base,
    `${stem}.ts`,
    `${stem}.tsx`,
    path.join(stem, 'index.ts'),
    path.join(stem, 'index.tsx'),
  ].find((candidate) => existsSync(candidate) && statSync(candidate).isFile());
}

const imports = (file: string): string[] =>
  ts
    .preProcessFile(readFileSync(file, 'utf8'), true, true)
    .importedFiles.map((entry) => entry.fileName);

const isClient = (file: string): boolean => {
  const first = ts.createSourceFile(file, readFileSync(file, 'utf8'), ts.ScriptTarget.Latest)
    .statements[0];
  return (
    first !== undefined &&
    ts.isExpressionStatement(first) &&
    ts.isStringLiteral(first.expression) &&
    first.expression.text === 'use client'
  );
};

/** Devuelve las rutas que llevan desde un módulo de cliente hasta lib/api. */
function leaks(root: string): string[] {
  const apiClient = path.join(root, 'lib/api') + path.sep;
  const found: string[] = [];
  for (const entry of sources(root).filter(isClient)) {
    const seen = new Set<string>();
    const pending = [entry];
    for (let file = pending.pop(); file !== undefined; file = pending.pop()) {
      if (seen.has(file)) continue;
      seen.add(file);
      if (file.startsWith(apiClient)) {
        found.push(`${path.relative(root, entry)} -> ${path.relative(root, file)}`);
        continue;
      }
      for (const specifier of imports(file)) {
        const target = resolveImport(root, file, specifier);
        if (target !== undefined) pending.push(target);
      }
    }
  }
  return found;
}

const FIXTURES = path.join(import.meta.dirname, 'fixtures/client-graph');

describe('TC-ARCH grafo de cliente', () => {
  it('detecta un acceso indirecto', () => {
    expect(leaks(path.join(FIXTURES, 'invalid'))).toStrictEqual([
      'components/widget.tsx -> lib/api/client.ts',
    ]);
  });

  it('acepta el árbol válido', () => {
    expect(leaks(path.join(FIXTURES, 'valid'))).toStrictEqual([]);
  });

  it('el frontend real no filtra lib/api al cliente', () => {
    const root = path.join(REPO_ROOT, 'frontend/src');
    expect(sources(root).length).toBeGreaterThan(3);
    expect(leaks(root)).toStrictEqual([]);
  });
});
