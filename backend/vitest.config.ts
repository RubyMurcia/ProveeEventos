// Harness de pruebas (ADR §6.1; TESTs §2.2 y §4.1). Ruta protegida (ADR-GOV-002).
import path from 'node:path';

import { defineConfig } from 'vitest/config';

const ROOT = path.join(import.meta.dirname, '..');
const SUITES = [
  'unit',
  'architecture',
  'integration',
  'contract',
  'concurrency',
  'multi-tenant',
  'security',
  'infra',
];
const WITH_CONTAINERS = new Set(['integration', 'concurrency', 'multi-tenant']);

export default defineConfig({
  test: {
    root: ROOT,
    allowOnly: false,
    passWithNoTests: false,
    retry: 0,
    projects: SUITES.map((name) => ({
      extends: true,
      test: {
        name,
        include: [`backend/src/tests/${name}/**/*.spec.ts`],
        exclude: ['backend/src/tests/architecture/fixtures/**'],
        environment: 'node',
        testTimeout:
          name === 'architecture' || WITH_CONTAINERS.has(name) || name === 'infra'
            ? 120_000
            : 10_000,
        hookTimeout: 180_000,
      },
    })),
    coverage: {
      provider: 'v8',
      reporter: ['text-summary', 'json-summary'],
      reportsDirectory: 'coverage',
      include: ['backend/src/**/*.ts'],
      // Lista protegida (ADR-TEST-006 R6): pruebas, cliente generado y puntos de entrada de proceso.
      exclude: [
        'backend/src/tests/**',
        'backend/src/prisma/generated/**',
        'backend/src/prisma/seed/index.ts',
        'backend/src/bootstrap/server.ts',
        'backend/src/bootstrap/worker.ts',
      ],
      // TESTs §4.1.
      thresholds: {
        lines: 80,
        branches: 75,
        'backend/src/modules/*/**/domain/**': { lines: 90, branches: 90 },
        'backend/src/modules/*/**/application/**': { lines: 80, branches: 80 },
        'backend/src/shared/**': { lines: 85, branches: 85 },
      },
    },
  },
});
