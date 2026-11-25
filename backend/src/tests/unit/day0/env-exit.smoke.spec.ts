import { afterEach, describe, expect, it, vi } from 'vitest';

import {
  CONFIG_EXIT_CODE,
  loadApiEnv,
  loadSeedEnv,
  loadWorkerEnv,
} from '../../../shared/config/env.js';
import { apiSource, seedSource, workerSource } from '../../support/env.js';

describe('humo: arranque fail-fast', () => {
  afterEach(() => {
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  const stub = (source: Record<string, string>): void => {
    for (const [name, value] of Object.entries(source)) vi.stubEnv(name, value);
  };

  it.each([
    ['api', apiSource, loadApiEnv],
    ['worker', workerSource, loadWorkerEnv],
    ['seed', seedSource, loadSeedEnv],
  ])('carga el entorno de %s desde el proceso', (_name, source, load) => {
    stub(source());
    expect(load().APP_ENV).toBe('test');
  });

  it(`termina con código ${String(CONFIG_EXIT_CODE)} si falta una variable`, () => {
    stub({ ...apiSource(), TOKEN_DERIVATION_KEYS: '' });
    const exit = vi.spyOn(process, 'exit').mockImplementation((code) => {
      throw new Error(`exit ${String(code)}`);
    });
    expect(() => loadApiEnv()).toThrow('exit 78');
    expect(exit).toHaveBeenCalledWith(78);
  });
});
