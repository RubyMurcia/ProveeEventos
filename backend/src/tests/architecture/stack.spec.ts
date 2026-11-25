// ADR-STACK-001 R1-R5, ADR-STACK-003 R1/R5, ADR-STACK-004 R1.
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

import { describe, expect, it } from 'vitest';

import { REPO_ROOT } from '../support/images.js';

interface Manifest {
  engines?: { node?: string };
  scripts?: Record<string, string>;
  dependencies?: Record<string, string>;
  devDependencies?: Record<string, string>;
}
const read = (file: string): string => readFileSync(path.join(REPO_ROOT, file), 'utf8');
const manifests = ['package.json', 'backend/package.json', 'frontend/package.json'].map(
  (file) => JSON.parse(read(file)) as Manifest,
);
const all: Record<string, string> = Object.assign(
  {},
  ...manifests.flatMap((m) => [m.dependencies ?? {}, m.devDependencies ?? {}]),
) as Record<string, string>;
const banned = (
  JSON.parse(read('Tools/adr-guard/banned-packages.json')) as { packages: { names: string[] }[] }
).packages.flatMap((group) => group.names);

describe('TC-ARCH stack aprobado', () => {
  it('fija Node.js 26 y npm', () => {
    expect(read('.nvmrc').trim()).toBe('26');
    for (const manifest of manifests) expect(manifest.engines?.node).toBe('26.x');
    expect(existsSync(path.join(REPO_ROOT, 'package-lock.json'))).toBe(true);
    for (const lock of ['yarn.lock', 'pnpm-lock.yaml'])
      expect(existsSync(path.join(REPO_ROOT, lock))).toBe(false);
  });

  it('declara las dependencias obligatorias', () => {
    const required = [
      'express',
      'bullmq',
      '@prisma/client',
      '@prisma/adapter-pg',
      'next',
      'tailwindcss',
      'vitest',
      'pino',
      'zod',
      'prettier',
      'eslint',
    ];
    expect(required.filter((name) => all[name] === undefined)).toStrictEqual([]);
  });

  it('fija Prisma 7.10.1 y TypeScript 6.0', () => {
    for (const name of ['prisma', '@prisma/client', '@prisma/adapter-pg'])
      expect(all[name]).toBe('7.10.1');
    expect(all['typescript']).toMatch(/^~6\.0\./);
  });

  it('no declara paquetes vetados', () => {
    expect(banned.length).toBeGreaterThan(20);
    const matches = (name: string): boolean =>
      banned.some((entry) =>
        entry.endsWith('/*') ? name.startsWith(entry.slice(0, -1)) : name === entry,
      );
    expect(Object.keys(all).filter(matches)).toStrictEqual([]);
  });

  it('no admite orígenes mutables', () => {
    expect(
      Object.entries(all).filter(([, v]) => /^(\*|latest|git|http|file:)|:\/\//.test(v)),
    ).toStrictEqual([]);
  });

  it('mantiene verify:adrs literal (ADR §6.1; ADR-GOV-002 R4)', () => {
    expect(manifests[0]?.scripts?.['verify:adrs']).toBe(
      'npm run verify:format && npm run verify:types && npm run verify:lint && npm run verify:deps && npm run verify:arch',
    );
    expect(manifests[0]?.scripts?.['verify:lint']).toBe(
      'eslint . --max-warnings 0 --no-inline-config',
    );
    expect(
      Object.values(manifests[0]?.scripts ?? {}).filter((s) =>
        /\|\|\s*true|passWithNoTests=true/.test(s),
      ),
    ).toStrictEqual([]);
  });

  it('fija las 11 imágenes por digest y los Dockerfiles usan la misma de Node', () => {
    const images = [...read('docker/images.env').matchAll(/^[A-Z0-9_]+=(\S+)$/gm)].map(
      (m) => m[1] ?? '',
    );
    expect(images).toHaveLength(11);
    expect(
      images.filter((i) => !/:[\w.-]+@sha256:[0-9a-f]{64}$/.test(i) || i.includes(':latest')),
    ).toStrictEqual([]);
    const node = images.find((i) => i.startsWith('node:')) ?? '';
    for (const file of [
      'backend/Dockerfile',
      'frontend/Dockerfile',
      'Tools/dev-stubs/Dockerfile',
    ]) {
      expect(read(file)).toContain(`ARG NODE_IMAGE=${node}\n`);
      expect(read(file)).toContain('\nUSER node\n');
    }
  });
});
