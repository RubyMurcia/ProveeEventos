// Humo E2E sobre el stack levantado (CICD §13.4). Los escenarios de SRS §8 los añade ISS-TEST-009.
import { expect, test } from '@playwright/test';

const apiPort = process.env['API_PORT'] ?? '4000';

test('humo: la web responde salud', async ({ request }) => {
  const response = await request.get('/health/live');
  expect(response.status()).toBe(200);
});

test('humo: la API está lista', async ({ request }) => {
  const response = await request.get(`http://127.0.0.1:${apiPort}/health/ready`);
  expect(response.status()).toBe(200);
});
