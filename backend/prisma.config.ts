// La CLI de Prisma usa DIRECT_URL (ADR-STACK-004 R4). `prisma generate` y `validate` no se conectan,
// por eso la fuente de datos solo se declara cuando la variable existe.
import { defineConfig } from 'prisma/config';

const directUrl = process.env['DIRECT_URL'];
const shadowUrl = process.env['SHADOW_DATABASE_URL'];

export default defineConfig({
  schema: 'src/prisma/schema.prisma',
  migrations: { path: 'src/prisma/migrations' },
  ...(directUrl === undefined || directUrl === ''
    ? {}
    : {
        datasource: {
          url: directUrl,
          ...(shadowUrl === undefined || shadowUrl === '' ? {} : { shadowDatabaseUrl: shadowUrl }),
        },
      }),
});
