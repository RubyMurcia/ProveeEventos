import type { Db } from '../../../shared/infrastructure/db-types.js';
export const x = (tx: Db, name: keyof Db): unknown => tx[name];
