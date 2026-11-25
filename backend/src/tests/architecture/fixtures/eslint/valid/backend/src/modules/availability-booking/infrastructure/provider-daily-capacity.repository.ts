import type { Db } from '../../../shared/infrastructure/db-types.js';
export const x = (tx: Db): Promise<void> => tx.providerDailyCapacity.update({ data: { consumed: 1 } });
