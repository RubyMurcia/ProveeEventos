import { type Router, Router as createRouter } from 'express';

/** Comprobación de una dependencia. Debe resolver si está disponible y rechazar si no lo está. */
export type ReadinessCheck = () => Promise<void>;

/**
 * Endpoints operativos de SAD §10.8: fuera de /api/v1, sin autenticación y sin detalles internos.
 * Las comprobaciones de PostgreSQL, Redis y colas las inyecta ISS-CODE-006.
 */
export function healthRouter(checks: readonly ReadinessCheck[] = []): Router {
  const router = createRouter();
  router.get('/health/live', (_req, res) => {
    res.set('Cache-Control', 'no-store').json({ status: 'ok' });
  });
  router.get('/health/ready', async (_req, res) => {
    const results = await Promise.allSettled(checks.map((check) => check()));
    const ready = results.every((result) => result.status === 'fulfilled');
    res.set('Cache-Control', 'no-store');
    res.status(ready ? 200 : 503).json({ status: ready ? 'ok' : 'unavailable' });
  });
  return router;
}
