// Arnés mínimo: PostgreSQL desechable con la migración 00 y una contraseña efímera por rol.
// ISS-CODE-004 añade `migrate deploy` y `rls/` (CICD §13.2).
import { randomBytes } from 'node:crypto';
import path from 'node:path';

import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import pg from 'pg';

import { pinnedImage, REPO_ROOT } from './images.js';

export type DatabaseRole = 'pe_migrator' | 'pe_api' | 'pe_worker' | 'pe_retention' | 'pe_readonly';

export interface TestDatabase {
  readonly container: StartedPostgreSqlContainer;
  /** Cliente conectado con un rol de ejecución; las pruebas no usan el superusuario (ADR-TEST-002 R4). */
  connect(role: DatabaseRole): Promise<pg.Client>;
  stop(): Promise<void>;
}

const ROLES: readonly DatabaseRole[] = [
  'pe_migrator',
  'pe_api',
  'pe_worker',
  'pe_retention',
  'pe_readonly',
];

export async function startDatabase(imageName = 'PG_IMAGE'): Promise<TestDatabase> {
  const container = await new PostgreSqlContainer(pinnedImage(imageName))
    .withCopyFilesToContainer([
      {
        source: path.join(REPO_ROOT, 'backend/src/prisma/bootstrap/00_extensiones_roles.sql'),
        target: '/tmp/00.sql',
      },
    ])
    .start();
  const psql = async (args: string[]): Promise<void> => {
    const result = await container.exec([
      'psql',
      '-X',
      '-q',
      '-v',
      'ON_ERROR_STOP=1',
      '-U',
      container.getUsername(),
      '-d',
      container.getDatabase(),
      ...args,
    ]);
    if (result.exitCode !== 0) throw new Error(`psql falló: ${result.output}`);
  };
  await psql(['-f', '/tmp/00.sql']);
  const passwords = new Map(ROLES.map((role) => [role, randomBytes(24).toString('hex')]));
  for (const [role, password] of passwords) {
    await psql(['-c', `ALTER ROLE ${role} PASSWORD '${password}'`]);
  }
  const clients: pg.Client[] = [];
  return {
    container,
    async connect(role) {
      const client = new pg.Client({
        host: container.getHost(),
        port: container.getPort(),
        database: container.getDatabase(),
        user: role,
        password: passwords.get(role),
      });
      await client.connect();
      clients.push(client);
      return client;
    },
    async stop() {
      await Promise.all(clients.map((client) => client.end()));
      await container.stop();
    },
  };
}
