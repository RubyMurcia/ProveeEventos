import { once } from 'node:events';
import type { AddressInfo } from 'node:net';

import { afterEach, describe, expect, it, vi } from 'vitest';

import { createApp } from '../../../bootstrap/app.js';
import { listen } from '../../../bootstrap/listen.js';
import { createLogger } from '../../../shared/observability/logger.js';

const logger = createLogger({ service: 'test', level: 'fatal' });

describe('humo: arranque y apagado', () => {
  afterEach(() => {
    process.removeAllListeners('SIGTERM');
    process.removeAllListeners('SIGINT');
    process.exitCode = 0;
    vi.useRealTimers();
  });

  it('escucha y cierra ante SIGTERM', async () => {
    const server = listen(createApp({ logger }), 0, logger);
    await once(server, 'listening');
    const { port } = server.address() as AddressInfo;
    expect((await fetch(`http://127.0.0.1:${String(port)}/health/live`)).status).toBe(200);
    vi.useFakeTimers({ toFake: ['setTimeout'] });
    const closed = once(server, 'close');
    process.emit('SIGTERM', 'SIGTERM');
    await closed;
    expect(server.listening).toBe(false);
  });
});
