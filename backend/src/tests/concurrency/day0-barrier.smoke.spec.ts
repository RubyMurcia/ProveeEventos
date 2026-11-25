// Humo del arnés de concurrencia: barrera de N conexiones reales sobre PostgreSQL (TESTs §3.3).
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { startDatabase, type TestDatabase } from '../support/postgres.js';

const N = 20;

describe('humo: barrera de concurrencia', () => {
  let database: TestDatabase;
  beforeAll(async () => {
    database = await startDatabase();
  });
  afterAll(async () => {
    await database.stop();
  });

  it(`solo gana una de ${String(N)} inserciones simultáneas de la misma clave`, async () => {
    const owner = await database.connect('pe_migrator');
    await owner.query('CREATE TABLE public.day0_claim (key text PRIMARY KEY)');
    await owner.query('GRANT SELECT, INSERT ON public.day0_claim TO pe_api');
    const clients = await Promise.all(Array.from({ length: N }, () => database.connect('pe_api')));
    const results = await Promise.all(
      clients.map((client) =>
        client.query("INSERT INTO public.day0_claim VALUES ('k') ON CONFLICT DO NOTHING"),
      ),
    );
    expect(results.reduce((total, result) => total + (result.rowCount ?? 0), 0)).toBe(1);
  });
});
