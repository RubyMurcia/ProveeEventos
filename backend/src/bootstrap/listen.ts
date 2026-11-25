import type { Server } from 'node:http';

import type { Express } from 'express';

import type { Logger } from '../shared/observability/logger.js';

const SHUTDOWN_TIMEOUT_MS = 25_000;

/** Escucha y apaga en menos de 30 s ante SIGTERM o SIGINT (CICD §5.3). */
export function listen(app: Express, port: number, logger: Logger): Server {
  const server = app.listen(port, () => {
    logger.info({ port }, 'proceso a la escucha');
  });
  const shutdown = (signal: NodeJS.Signals): void => {
    logger.info({ signal }, 'apagando');
    setTimeout(() => process.exit(1), SHUTDOWN_TIMEOUT_MS).unref();
    server.close((error) => {
      process.exitCode = error === undefined ? 0 : 1;
    });
  };
  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
  return server;
}
