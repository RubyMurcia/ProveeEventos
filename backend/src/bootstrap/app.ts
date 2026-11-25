import express, { type Express } from 'express';

import { healthRouter, type ReadinessCheck } from '../shared/http/health.js';
import { CORRELATION_HEADER, resolveCorrelationId } from '../shared/observability/correlation.js';
import type { Logger } from '../shared/observability/logger.js';

export interface AppDependencies {
  readonly logger: Logger;
  readonly readinessChecks?: readonly ReadinessCheck[];
}

/**
 * Aplicación Express mínima del Día 0. ISS-CODE-006 añade el manejador problem+json
 * y el registro de módulos por convención.
 */
export function createApp({ logger, readinessChecks = [] }: AppDependencies): Express {
  const app = express();
  app.disable('x-powered-by');
  app.use((req, res, next) => {
    const correlationId = resolveCorrelationId(req.get(CORRELATION_HEADER));
    res.set(CORRELATION_HEADER, correlationId);
    res.on('finish', () => {
      logger.debug({ correlationId, method: req.method, status: res.statusCode }, 'petición');
    });
    next();
  });
  app.use(healthRouter(readinessChecks));
  return app;
}
