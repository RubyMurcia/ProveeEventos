import { randomUUID } from 'node:crypto';

export const CORRELATION_HEADER = 'x-correlation-id';
const VALID_ID = /^[A-Za-z0-9._-]{8,128}$/;

/** Reutiliza el identificador entrante si es seguro; en otro caso genera uno (ADR-OBS-001 R3). */
export function resolveCorrelationId(incoming: string | undefined): string {
  return incoming !== undefined && VALID_ID.test(incoming) ? incoming : randomUUID();
}
