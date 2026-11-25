// Entrada de semillas (CICD §6.5). ISS-CODE-004 añade la carga por convención de reference/ y synthetic/.
import { loadSeedEnv } from '../../shared/config/env.js';
import { createLogger } from '../../shared/observability/logger.js';

const env = loadSeedEnv();
const logger = createLogger({ service: 'seed', level: env.LOG_LEVEL });

logger.info({ synthetic: env.SEED_SYNTHETIC }, 'sin semillas registradas todavía');
