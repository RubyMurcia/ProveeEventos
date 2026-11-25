import type { Db } from '../../../shared/infrastructure/db-types.js';
export const x = (prisma: Db): Promise<void> => prisma.quotation.findMany();
