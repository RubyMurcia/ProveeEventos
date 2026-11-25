import 'server-only';

import { pino } from 'pino';

export const logger = pino({
  base: { service: 'web' },
  redact: {
    paths: [
      'token',
      'accessToken',
      'refreshToken',
      'idToken',
      'clientSecret',
      'authorization',
      'cookie',
      '*.token',
      '*.authorization',
      '*.cookie',
    ],
    censor: '[REDACTADO]',
  },
});
