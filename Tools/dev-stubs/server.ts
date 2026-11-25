// Dobles locales (CICD §5.6). Día 0: solo salud y negativa a arrancar fuera de development y test.
// OIDC, Cloudinary y el webhook de SendGrid los implementa ISS-CODE-002.
// Sin dependencias: Node ejecuta este TypeScript directamente.
import { createServer } from 'node:http';
import process from 'node:process';

const PORT = 4010;
const appEnv = process.env['APP_ENV'];

if (appEnv !== 'development' && appEnv !== 'test') {
  process.stderr.write('dev-stubs: solo se permite en APP_ENV=development o test\n');
  process.exit(78);
}

const server = createServer((request, response) => {
  const healthy = request.method === 'GET' && request.url === '/health/live';
  response.writeHead(healthy ? 200 : 501, { 'content-type': 'application/json' });
  response.end(JSON.stringify({ status: healthy ? 'ok' : 'not_implemented' }));
});

server.listen(PORT, '0.0.0.0', () => {
  process.stdout.write(`dev-stubs a la escucha en ${String(PORT)}\n`);
});

for (const signal of ['SIGTERM', 'SIGINT'] as const) {
  process.once(signal, () => server.close());
}
