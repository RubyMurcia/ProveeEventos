import type { Db } from '../../../shared/infrastructure/db-types.js';
export const x = (tx: Db, id: string): Promise<void> => tx.$queryRaw`SELECT 1 WHERE ${id} IS NOT NULL`;
export const sql = "SET LOCAL statement_timeout = '5s'";
