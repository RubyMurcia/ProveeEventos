// Punto de entrada de la API (ADR-ARCH-001 R2).
import { loadApiEnv } from '../shared/config/env.js';
import { createLogger } from '../shared/observability/logger.js';
import { createApp } from './app.js';
import { listen } from './listen.js';

const env = loadApiEnv();
const logger = createLogger({ service: 'api', level: env.LOG_LEVEL });

listen(createApp({ logger }), env.API_PORT, logger);
