import type { Db } from '../../../shared/infrastructure/db-types.js';
export const x = (db: Db): Promise<Response> => db.$transaction(() => fetch('https://example.test'));
