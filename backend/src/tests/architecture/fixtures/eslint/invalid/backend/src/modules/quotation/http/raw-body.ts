import type { Request } from 'express';
export const x = (req: Request): unknown => req.body;
