// Punto de entrada del worker (ADR-ARCH-001 R2). Las colas BullMQ las registra ISS-CODE-006.
import { loadWorkerEnv } from '../shared/config/env.js';
import { createLogger } from '../shared/observability/logger.js';
import { createApp } from './app.js';
import { listen } from './listen.js';

const env = loadWorkerEnv();
const logger = createLogger({ service: 'worker', level: env.LOG_LEVEL });

listen(createApp({ logger }), env.WORKER_HEALTH_PORT, logger);
