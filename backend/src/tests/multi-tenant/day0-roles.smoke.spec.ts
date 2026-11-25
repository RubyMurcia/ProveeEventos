import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { startDatabase, type TestDatabase } from '../support/postgres.js';

describe('humo: roles de mínimo privilegio (ADR-DATA-009)', () => {
  let database: TestDatabase;
  beforeAll(async () => {
    database = await startDatabase();
  });
  afterAll(async () => {
    await database.stop();
  });

  it('ningún rol pe_* es superusuario ni evita RLS', async () => {
    const client = await database.connect('pe_api');
    const roles = await client.query<{ rolsuper: boolean; rolbypassrls: boolean }>(
      "SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname LIKE 'pe\\_%'",
    );
    expect(roles.rowCount).toBe(6);
    expect(roles.rows.filter((role) => role.rolsuper || role.rolbypassrls)).toStrictEqual([]);
  });

  it.each(['pe_api', 'pe_worker', 'pe_retention', 'pe_readonly'] as const)(
    '%s no puede crear tablas',
    async (role) => {
      const client = await database.connect(role);
      await expect(client.query('CREATE TABLE public.intrusa (id int)')).rejects.toMatchObject({
        code: '42501',
      });
    },
  );
});
