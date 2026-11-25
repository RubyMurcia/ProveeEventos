import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { startDatabase, type TestDatabase } from '../support/postgres.js';

describe.each(['PG_IMAGE', 'PG_IMAGE_MIN'])('humo: migración 00 sobre %s', (image) => {
  let database: TestDatabase;
  beforeAll(async () => {
    database = await startDatabase(image);
  });
  afterAll(async () => {
    await database.stop();
  });

  it('instala las extensiones y la función de inmutabilidad', async () => {
    const client = await database.connect('pe_api');
    const extensions = await client.query<{ extname: string }>(
      "SELECT extname FROM pg_extension WHERE extname IN ('citext','pg_trgm','unaccent','btree_gist')",
    );
    expect(extensions.rowCount).toBe(4);
    const fn = await client.query("SELECT 1 FROM pg_proc WHERE proname = 'fn_reject_mutation'");
    expect(fn.rowCount).toBe(1);
  });

  it('es repetible', async () => {
    const result = await database.container.exec([
      'psql',
      '-X',
      '-q',
      '-v',
      'ON_ERROR_STOP=1',
      '-U',
      database.container.getUsername(),
      '-d',
      database.container.getDatabase(),
      '-f',
      '/tmp/00.sql',
    ]);
    expect(result.exitCode).toBe(0);
  });
});
