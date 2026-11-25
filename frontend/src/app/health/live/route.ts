// Salud del proceso web, sin dependencias (CICD DC-11).
export function GET(): Response {
  return Response.json({ status: 'ok' }, { headers: { 'Cache-Control': 'no-store' } });
}
