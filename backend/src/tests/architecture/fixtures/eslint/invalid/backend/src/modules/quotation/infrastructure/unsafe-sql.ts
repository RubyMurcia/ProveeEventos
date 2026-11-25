import type { Db } from '../../../shared/infrastructure/db-types.js';
export const x = (db: Db): Promise<void> => db.$queryRawUnsafe('SELECT 1');
