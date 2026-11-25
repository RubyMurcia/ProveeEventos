// Valida el entorno al arrancar el servidor, nunca durante `next build` (CICD §3.4).
export async function register(): Promise<void> {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { getEnv } = await import('./lib/config/env');
    getEnv();
  }
}
