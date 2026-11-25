// Dobles locales (CICD §5.6): Auth0 (OIDC, Authorization Code con PKCE y refresh rotatorio),
// Cloudinary (carga firmada, consulta y borrado) y el webhook firmado de SendGrid.
// Solo APP_ENV=development o test. Sin dependencias: Node ejecuta este TypeScript directamente,
// así que solo se usa sintaxis borrable (sin enum, namespace ni propiedades de parámetro).
// Nunca se registran tokens, secretos, cuerpos ni cabeceras.
import {
  createHash,
  createPrivateKey,
  generateKeyPairSync,
  randomBytes,
  sign,
  timingSafeEqual,
  type KeyObject,
} from 'node:crypto';
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import process from 'node:process';

const PORT = 4010;

const appEnv = process.env['APP_ENV'];
if (appEnv !== 'development' && appEnv !== 'test') {
  process.stderr.write('dev-stubs: solo se permite en APP_ENV=development o test\n');
  process.exit(78);
}

// ---------- Límites ----------
const BODY_LIMIT = 16 * 1024;
const UPLOAD_LIMIT = 101 * 1024 * 1024; // vídeo de 100 MiB (MEDIA_MAX_VIDEO_BYTES) más el sobre multipart
const MEDIA_STORE_LIMIT = 512 * 1024 * 1024;
const MAX_ENTRIES = 10_000;
const PARAM_MAX = 2048;
const PENDING_TTL_S = 600;
const CODE_TTL_S = 60;
const ACCESS_TOKEN_TTL_S = 3600;
const ID_TOKEN_TTL_S = 3600;
const REFRESH_IDLE_S = 15 * 86_400;
const REFRESH_ABSOLUTE_S = 30 * 86_400;
const UPLOAD_SIGNATURE_MAX_AGE_S = 3600;
const API_TIMEOUT_MS = 3000;
// Mismo destino que API_BASE_URL de la web (docker-compose.yml): la API en la red edge.
const SENDGRID_WEBHOOK_TARGET = 'http://api:4000/api/v1/webhooks/sendgrid/events';

// ---------- Configuración ----------
interface Config {
  readonly publicBase: string;
  readonly issuer: string;
  readonly audience: string;
  readonly clientId: string;
  readonly clientSecret: string;
  readonly appOrigin: string;
  readonly redirectUris: ReadonlySet<string>;
  readonly logoutUrls: ReadonlySet<string>;
  readonly cloudName: string;
  readonly cloudApiKey: string;
  readonly cloudApiSecret: string;
  readonly sendgridKey: KeyObject | null;
}

const trimSlash = (value: string): string => value.replace(/\/+$/, '');

function loadConfig(env: NodeJS.ProcessEnv): Config {
  const problems: string[] = [];
  const text = (name: string): string => {
    const value = env[name];
    if (value === undefined || value.trim() === '') {
      problems.push(`${name}: obligatoria`);
      return '';
    }
    if (value.includes('__GENERATE')) {
      problems.push(`${name}: marcador sin generar`);
      return '';
    }
    return value;
  };
  const secret = (name: string): string => {
    const value = text(name);
    if (value !== '' && value.length < 32) problems.push(`${name}: mínimo 32 caracteres`);
    return value;
  };
  const baseUrl = (name: string): string => {
    const value = text(name);
    if (value === '') return '';
    try {
      const url = new URL(value);
      const valid =
        (url.protocol === 'http:' || url.protocol === 'https:') &&
        url.username === '' &&
        url.password === '' &&
        url.search === '' &&
        url.hash === '';
      if (valid) return trimSlash(`${url.origin}${url.pathname}`);
    } catch {
      // Se informa abajo.
    }
    problems.push(`${name}: URL inválida`);
    return '';
  };

  const publicBase = baseUrl('AUTH0_ISSUER_BASE_URL');
  const appBase = baseUrl('APP_BASE_URL');
  const audience = text('AUTH0_AUDIENCE');
  const clientId = text('AUTH0_CLIENT_ID');
  const clientSecret = secret('AUTH0_CLIENT_SECRET');
  const cloudName = text('CLOUDINARY_CLOUD_NAME');
  const cloudApiKey = text('CLOUDINARY_API_KEY');
  const cloudApiSecret = secret('CLOUDINARY_API_SECRET');
  if (cloudName !== '' && !/^[A-Za-z0-9_-]{1,64}$/.test(cloudName)) {
    problems.push('CLOUDINARY_CLOUD_NAME: formato inválido');
  }

  let sendgridKey: KeyObject | null = null;
  const rawKey = env['DEV_SENDGRID_WEBHOOK_PRIVATE_KEY'] ?? '';
  if (rawKey !== '') {
    sendgridKey = parseEcPrivateKey(rawKey);
    if (sendgridKey === null) {
      problems.push('DEV_SENDGRID_WEBHOOK_PRIVATE_KEY: clave ECDSA P-256 en base64 inválida');
    }
  }

  if (problems.length > 0) {
    for (const problem of problems) process.stderr.write(`dev-stubs: ${problem}\n`);
    process.exit(78);
  }

  return {
    publicBase,
    // Como Auth0: el emisor termina en barra.
    issuer: `${publicBase}/`,
    audience,
    clientId,
    clientSecret,
    appOrigin: new URL(appBase).origin,
    // SAD §9.1 nombra /auth/callback; ISS-CODE-007 nombra /api/auth/callback. Coincidencia exacta.
    redirectUris: new Set([`${appBase}/auth/callback`, `${appBase}/api/auth/callback`]),
    logoutUrls: new Set([appBase, `${appBase}/`]),
    cloudName,
    cloudApiKey,
    cloudApiSecret,
    sendgridKey,
  };
}

function parseEcPrivateKey(base64: string): KeyObject | null {
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(base64)) return null;
  const der = Buffer.from(base64, 'base64');
  for (const type of ['sec1', 'pkcs8'] as const) {
    try {
      const key = createPrivateKey({ key: der, format: 'der', type });
      if (key.asymmetricKeyType === 'ec' && key.asymmetricKeyDetails?.namedCurve === 'prime256v1') {
        return key;
      }
    } catch {
      // Se prueba el siguiente formato.
    }
  }
  return null;
}

const config = loadConfig(process.env);

// ---------- Identidades sintéticas (una por rol; deben coincidir con las semillas) ----------
// El rol es solo una etiqueta de la pantalla: el token no lleva roles (ADR-SEC-001 R3).
interface SyntheticUser {
  readonly role: string;
  readonly sub: string;
  readonly email: string;
  readonly name: string;
}

const USERS: readonly SyntheticUser[] = [
  {
    role: 'PROPIETARIO',
    sub: 'auth0|pe-dev-propietario',
    email: 'propietario@test.proveeeventos.co',
    name: 'Paula Propietaria',
  },
  {
    role: 'ADMIN_EMPRESA',
    sub: 'auth0|pe-dev-admin-empresa',
    email: 'admin.empresa@test.proveeeventos.co',
    name: 'Andrés Administrador',
  },
  {
    role: 'COORDINADOR',
    sub: 'auth0|pe-dev-coordinador',
    email: 'coordinador@test.proveeeventos.co',
    name: 'Carla Coordinadora',
  },
  {
    role: 'COORDINADOR_RESTRINGIDO',
    sub: 'auth0|pe-dev-coordinador-restringido',
    email: 'coordinador.restringido@test.proveeeventos.co',
    name: 'Camilo Coordinador Restringido',
  },
  {
    role: 'PROVEEDOR',
    sub: 'auth0|pe-dev-proveedor',
    email: 'proveedor@test.proveeeventos.co',
    name: 'Pedro Proveedor',
  },
  {
    role: 'ADMIN_PLATAFORMA',
    sub: 'auth0|pe-dev-admin-plataforma',
    email: 'admin.plataforma@test.proveeeventos.co',
    name: 'Ana Administradora de Plataforma',
  },
];

// ---------- Utilidades ----------
class HttpError extends Error {
  readonly status: number;
  readonly code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const nowS = (): number => Math.floor(Date.now() / 1000);
const randomToken = (bytes = 32): string => randomBytes(bytes).toString('base64url');
const sha256 = (value: string): string => createHash('sha256').update(value).digest('base64url');
const b64url = (value: unknown): string => Buffer.from(JSON.stringify(value)).toString('base64url');

function safeEqual(a: string, b: string): boolean {
  const left = createHash('sha256').update(a).digest();
  const right = createHash('sha256').update(b).digest();
  return timingSafeEqual(left, right) && a.length === b.length;
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (char) => `&#${String(char.charCodeAt(0))};`);
}

const BASE_HEADERS = {
  'cache-control': 'no-store',
  pragma: 'no-cache',
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'no-referrer',
} as const;

function sendJson(
  res: ServerResponse,
  status: number,
  body: unknown,
  headers: Record<string, string> = {},
): void {
  res.writeHead(status, {
    ...BASE_HEADERS,
    'content-type': 'application/json; charset=utf-8',
    ...headers,
  });
  res.end(JSON.stringify(body));
}

function sendHtml(res: ServerResponse, status: number, title: string, body: string): void {
  res.writeHead(status, {
    ...BASE_HEADERS,
    'content-type': 'text/html; charset=utf-8',
    'content-security-policy': `default-src 'none'; form-action 'self' ${config.appOrigin}; frame-ancestors 'none'; base-uri 'none'`,
    'x-frame-options': 'DENY',
  });
  res.end(
    `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>${escapeHtml(title)}</title></head><body><main><h1>${escapeHtml(title)}</h1>${body}</main></body></html>`,
  );
}

function redirect(res: ServerResponse, status: 302 | 303, location: string): void {
  res.writeHead(status, { ...BASE_HEADERS, location });
  res.end();
}

function readBody(req: IncomingMessage, limit: number): Promise<Buffer<ArrayBuffer>> {
  return new Promise((resolve, reject) => {
    const declared = Number(req.headers['content-length'] ?? '0');
    if (Number.isFinite(declared) && declared > limit) {
      reject(new HttpError(413, 'payload_too_large', 'cuerpo demasiado grande'));
      return;
    }
    const chunks: Buffer[] = [];
    let size = 0;
    let done = false;
    req.on('data', (chunk: Buffer) => {
      if (done) return;
      size += chunk.length;
      if (size > limit) {
        done = true;
        reject(new HttpError(413, 'payload_too_large', 'cuerpo demasiado grande'));
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      if (!done) resolve(Buffer.concat(chunks));
    });
    req.on('error', (error) => {
      if (!done) reject(error);
    });
  });
}

const mediaType = (req: IncomingMessage): string =>
  (req.headers['content-type'] ?? '').split(';')[0]?.trim().toLowerCase() ?? '';

/** Parámetros sin repetir (RFC 6749 §3.1) y con longitud acotada. */
function uniqueParams(entries: Iterable<[string, string]>): Map<string, string> {
  const params = new Map<string, string>();
  for (const [key, value] of entries) {
    if (params.has(key)) throw new HttpError(400, 'invalid_request', `parámetro repetido: ${key}`);
    if (value.length > PARAM_MAX) throw new HttpError(400, 'invalid_request', 'parámetro largo');
    params.set(key, value);
  }
  return params;
}

async function readFormOrJson(req: IncomingMessage): Promise<Map<string, string>> {
  const type = mediaType(req);
  const body = (await readBody(req, BODY_LIMIT)).toString('utf8');
  if (type === 'application/x-www-form-urlencoded') return uniqueParams(new URLSearchParams(body));
  if (type === 'application/json') {
    const parsed = parseJsonObject(body);
    const entries: [string, string][] = [];
    for (const [key, value] of Object.entries(parsed)) {
      if (typeof value !== 'string')
        throw new HttpError(400, 'invalid_request', 'valor no textual');
      entries.push([key, value]);
    }
    return uniqueParams(entries);
  }
  throw new HttpError(400, 'invalid_request', 'tipo de contenido no admitido');
}

function parseJsonObject(body: string): Record<string, unknown> {
  let parsed: unknown;
  try {
    parsed = JSON.parse(body);
  } catch {
    throw new HttpError(400, 'invalid_request', 'JSON inválido');
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    throw new HttpError(400, 'invalid_request', 'se esperaba un objeto JSON');
  }
  return parsed as Record<string, unknown>;
}

function boundedSet<K, V>(map: Map<K, V>, key: K, value: V): void {
  if (map.size >= MAX_ENTRIES) {
    throw new HttpError(503, 'temporarily_unavailable', 'demasiadas entradas en memoria');
  }
  map.set(key, value);
}

// ---------- Claves y JWT (RS256, generadas al arrancar) ----------
const { publicKey: signingPublicKey, privateKey: signingKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
});
const publicJwk = signingPublicKey.export({ format: 'jwk' });
// Huella RFC 7638 como kid.
const kid = sha256(JSON.stringify({ e: publicJwk.e, kty: publicJwk.kty, n: publicJwk.n }));
const JWKS = {
  keys: [{ kty: 'RSA', use: 'sig', alg: 'RS256', kid, n: publicJwk.n, e: publicJwk.e }],
};

function signJwt(payload: Record<string, unknown>): string {
  const input = `${b64url({ alg: 'RS256', typ: 'JWT', kid })}.${b64url(payload)}`;
  return `${input}.${sign('sha256', Buffer.from(input), signingKey).toString('base64url')}`;
}

const SUPPORTED_SCOPES = new Set(['openid', 'profile', 'email', 'offline_access']);
// Claims propios de Auth0 en el access token (Action), con espacio de nombres de la audiencia.
const claimNamespace = `${trimSlash(config.audience)}/`;

const DISCOVERY = {
  issuer: config.issuer,
  authorization_endpoint: `${config.publicBase}/authorize`,
  token_endpoint: `${config.publicBase}/oauth/token`,
  jwks_uri: `${config.publicBase}/.well-known/jwks.json`,
  response_types_supported: ['code'],
  response_modes_supported: ['query'],
  grant_types_supported: ['authorization_code', 'refresh_token'],
  subject_types_supported: ['public'],
  id_token_signing_alg_values_supported: ['RS256'],
  token_endpoint_auth_methods_supported: ['client_secret_basic', 'client_secret_post'],
  code_challenge_methods_supported: ['S256'],
  scopes_supported: [...SUPPORTED_SCOPES],
  claims_supported: [
    'iss',
    'sub',
    'aud',
    'exp',
    'iat',
    'auth_time',
    'nonce',
    'sid',
    'amr',
    'name',
    'email',
    'email_verified',
  ],
  request_parameter_supported: false,
  request_uri_parameter_supported: false,
};

// ---------- Estado OIDC en memoria ----------
interface Authorization {
  readonly clientId: string;
  readonly redirectUri: string;
  readonly state: string;
  readonly nonce: string | null;
  readonly codeChallenge: string;
  readonly scopes: readonly string[];
  readonly audience: string;
}

interface Session {
  readonly user: SyntheticUser;
  readonly mfa: boolean;
  readonly authTime: number;
  readonly sid: string;
}

interface PendingLogin {
  readonly authorization: Authorization;
  readonly expiresAt: number;
}

interface CodeGrant {
  readonly authorization: Authorization;
  readonly session: Session;
  readonly expiresAt: number;
  used: boolean;
  family: string | null;
}

interface RefreshEntry {
  readonly family: string;
  readonly clientId: string;
  readonly scopes: readonly string[];
  readonly audience: string;
  readonly session: Session;
  readonly expiresAt: number;
  used: boolean;
}

interface RefreshFamily {
  readonly expiresAt: number;
  revoked: boolean;
}

// Los códigos y refresh tokens se guardan por su hash.
const pendingLogins = new Map<string, PendingLogin>();
const codes = new Map<string, CodeGrant>();
const refreshTokens = new Map<string, RefreshEntry>();
const families = new Map<string, RefreshFamily>();

function revokeFamily(family: string | null): void {
  if (family === null) return;
  const entry = families.get(family);
  if (entry !== undefined) entry.revoked = true;
}

function sweep(): void {
  const now = nowS();
  for (const [key, value] of pendingLogins) if (value.expiresAt <= now) pendingLogins.delete(key);
  // Los códigos usados se conservan un rato para detectar su reutilización.
  for (const [key, value] of codes) if (value.expiresAt + PENDING_TTL_S <= now) codes.delete(key);
  for (const [key, value] of refreshTokens) if (value.expiresAt <= now) refreshTokens.delete(key);
  for (const [key, value] of families) if (value.expiresAt <= now) families.delete(key);
}
setInterval(sweep, 60_000).unref();

// ---------- /authorize ----------
function authorizeError(
  res: ServerResponse,
  redirectUri: string,
  state: string | undefined,
  error: string,
  description: string,
): void {
  const target = new URL(redirectUri);
  target.searchParams.set('error', error);
  target.searchParams.set('error_description', description);
  if (state !== undefined) target.searchParams.set('state', state);
  redirect(res, 302, target.href);
}

function handleAuthorize(res: ServerResponse, query: URLSearchParams): void {
  let params: Map<string, string>;
  try {
    params = uniqueParams(query);
  } catch {
    sendHtml(res, 400, 'Solicitud inválida', '<p>Parámetros repetidos o demasiado largos.</p>');
    return;
  }
  const clientId = params.get('client_id') ?? '';
  const redirectUri = params.get('redirect_uri') ?? '';
  // Sin cliente o redirect_uri registrados no se redirige: evita la redirección abierta.
  if (!safeEqual(clientId, config.clientId) || !config.redirectUris.has(redirectUri)) {
    sendHtml(res, 400, 'Solicitud inválida', '<p>client_id o redirect_uri no registrados.</p>');
    return;
  }
  const state = params.get('state');
  const fail = (error: string, description: string): void =>
    authorizeError(res, redirectUri, state, error, description);

  if (params.get('response_type') !== 'code') {
    fail('unsupported_response_type', 'solo response_type=code');
    return;
  }
  const responseMode = params.get('response_mode');
  if (responseMode !== undefined && responseMode !== 'query') {
    fail('invalid_request', 'solo response_mode=query');
    return;
  }
  if (state === undefined || state === '') {
    fail('invalid_request', 'state obligatorio');
    return;
  }
  const codeChallenge = params.get('code_challenge') ?? '';
  if (
    params.get('code_challenge_method') !== 'S256' ||
    !/^[A-Za-z0-9_-]{43}$/.test(codeChallenge)
  ) {
    fail('invalid_request', 'PKCE S256 obligatorio');
    return;
  }
  const scopes = (params.get('scope') ?? '').split(' ').filter((scope) => scope !== '');
  if (!scopes.includes('openid') || scopes.some((scope) => !SUPPORTED_SCOPES.has(scope))) {
    fail(
      'invalid_scope',
      'scope debe incluir openid y solo openid, profile, email, offline_access',
    );
    return;
  }
  // Sin audience se usa la audiencia por defecto del tenant (como Auth0 con "Default Audience").
  const audience = params.get('audience') ?? config.audience;
  if (audience !== config.audience) {
    fail('invalid_request', 'audience desconocida');
    return;
  }
  const maxAge = params.get('max_age');
  if (maxAge !== undefined && !/^\d{1,9}$/.test(maxAge)) {
    fail('invalid_request', 'max_age inválido');
    return;
  }
  // No hay sesión SSO: cada autorización exige elegir identidad (auth_time es siempre reciente).
  if (params.get('prompt') === 'none') {
    fail('login_required', 'no hay sesión en el doble local');
    return;
  }
  const nonce = params.get('nonce') ?? null;
  const txn = randomToken();
  try {
    boundedSet(pendingLogins, sha256(txn), {
      authorization: { clientId, redirectUri, state, nonce, codeChallenge, scopes, audience },
      expiresAt: nowS() + PENDING_TTL_S,
    });
  } catch {
    fail('temporarily_unavailable', 'demasiadas solicitudes pendientes');
    return;
  }

  const rows = USERS.map(
    (user) =>
      `<li><form method="post" action="/u/login"><input type="hidden" name="txn" value="${escapeHtml(txn)}"><input type="hidden" name="user" value="${escapeHtml(user.sub)}"><strong>${escapeHtml(user.name)}</strong> · ${escapeHtml(user.email)} · <code>${escapeHtml(user.role)}</code> <button type="submit" name="mfa" value="0">Entrar</button> <button type="submit" name="mfa" value="1">Entrar con MFA</button></form></li>`,
  ).join('');
  sendHtml(
    res,
    200,
    'Inicio de sesión local (dev-stubs)',
    `<p>Identidades sintéticas de desarrollo; sin contraseñas. Vuelves a <code>${escapeHtml(redirectUri)}</code>.</p><ul>${rows}</ul>`,
  );
}

async function handleLoginDecision(req: IncomingMessage, res: ServerResponse): Promise<void> {
  if (mediaType(req) !== 'application/x-www-form-urlencoded') {
    sendHtml(res, 400, 'Solicitud inválida', '<p>Formulario no válido.</p>');
    return;
  }
  const form = uniqueParams(new URLSearchParams((await readBody(req, BODY_LIMIT)).toString()));
  const key = sha256(form.get('txn') ?? '');
  const pending = pendingLogins.get(key);
  pendingLogins.delete(key);
  const user = USERS.find((candidate) => candidate.sub === form.get('user'));
  const mfa = form.get('mfa');
  if (pending === undefined || pending.expiresAt <= nowS() || user === undefined) {
    sendHtml(res, 400, 'Solicitud caducada', '<p>Vuelve a iniciar sesión desde la aplicación.</p>');
    return;
  }
  if (mfa !== '0' && mfa !== '1') {
    sendHtml(res, 400, 'Solicitud inválida', '<p>Opción de MFA no válida.</p>');
    return;
  }
  const code = randomToken();
  const now = nowS();
  boundedSet(codes, sha256(code), {
    authorization: pending.authorization,
    session: { user, mfa: mfa === '1', authTime: now, sid: randomToken(16) },
    expiresAt: now + CODE_TTL_S,
    used: false,
    family: null,
  });
  const target = new URL(pending.authorization.redirectUri);
  target.searchParams.set('code', code);
  target.searchParams.set('state', pending.authorization.state);
  redirect(res, 303, target.href);
}

// ---------- /oauth/token ----------
function oauthError(res: ServerResponse, status: number, error: string, description: string): void {
  const headers: Record<string, string> =
    status === 401 ? { 'www-authenticate': 'Basic realm="dev-stubs"' } : {};
  sendJson(res, status, { error, error_description: description }, headers);
}

function authenticateClient(req: IncomingMessage, params: Map<string, string>): string | null {
  const header = req.headers.authorization;
  const bodyId = params.get('client_id');
  const bodySecret = params.get('client_secret');
  let id: string;
  let secret: string;
  if (header !== undefined) {
    if (bodySecret !== undefined) return null; // Un solo método de autenticación (RFC 6749 §2.3).
    const match = /^Basic ([A-Za-z0-9+/]+={0,2})$/.exec(header);
    if (match?.[1] === undefined) return null;
    const decoded = Buffer.from(match[1], 'base64').toString('utf8');
    const colon = decoded.indexOf(':');
    if (colon < 0) return null;
    try {
      id = decodeURIComponent(decoded.slice(0, colon));
      secret = decodeURIComponent(decoded.slice(colon + 1));
    } catch {
      return null;
    }
    if (bodyId !== undefined && bodyId !== id) return null;
  } else {
    if (bodyId === undefined || bodySecret === undefined) return null;
    id = bodyId;
    secret = bodySecret;
  }
  const valid = safeEqual(id, config.clientId) && safeEqual(secret, config.clientSecret);
  return valid ? id : null;
}

function issueTokens(
  clientId: string,
  scopes: readonly string[],
  audience: string,
  session: Session,
  nonce: string | null,
  family: string | null,
): Record<string, unknown> {
  const now = nowS();
  const { user } = session;
  const amr = session.mfa ? { amr: ['pwd', 'mfa'] } : { amr: ['pwd'] };
  const accessToken = signJwt({
    iss: config.issuer,
    sub: user.sub,
    aud: audience,
    iat: now,
    exp: now + ACCESS_TOKEN_TTL_S,
    azp: clientId,
    scope: scopes.join(' '),
    auth_time: session.authTime,
    ...amr,
    [`${claimNamespace}email`]: user.email,
    [`${claimNamespace}email_verified`]: true,
  });
  const idToken = signJwt({
    iss: config.issuer,
    sub: user.sub,
    aud: clientId,
    iat: now,
    exp: now + ID_TOKEN_TTL_S,
    auth_time: session.authTime,
    sid: session.sid,
    ...amr,
    ...(nonce === null ? {} : { nonce }),
    ...(scopes.includes('profile') ? { name: user.name } : {}),
    ...(scopes.includes('email') ? { email: user.email, email_verified: true } : {}),
  });
  const response: Record<string, unknown> = {
    access_token: accessToken,
    id_token: idToken,
    token_type: 'Bearer',
    expires_in: ACCESS_TOKEN_TTL_S,
    scope: scopes.join(' '),
  };
  if (family !== null) {
    const familyEntry = families.get(family);
    const refreshToken = randomToken();
    boundedSet(refreshTokens, sha256(refreshToken), {
      family,
      clientId,
      scopes,
      audience,
      session,
      expiresAt: Math.min(now + REFRESH_IDLE_S, familyEntry?.expiresAt ?? now),
      used: false,
    });
    response['refresh_token'] = refreshToken;
  }
  return response;
}

function newFamily(scopes: readonly string[]): string | null {
  if (!scopes.includes('offline_access')) return null; // Como Auth0: refresh solo con offline_access.
  const family = randomToken(16);
  boundedSet(families, family, { expiresAt: nowS() + REFRESH_ABSOLUTE_S, revoked: false });
  return family;
}

async function handleToken(req: IncomingMessage, res: ServerResponse): Promise<void> {
  const params = await readFormOrJson(req);
  const clientId = authenticateClient(req, params);
  if (clientId === null) {
    oauthError(res, 401, 'invalid_client', 'autenticación del cliente fallida');
    return;
  }
  const grantType = params.get('grant_type');
  if (grantType === 'authorization_code') {
    const key = sha256(params.get('code') ?? '');
    const grant = codes.get(key);
    if (grant === undefined) {
      oauthError(res, 400, 'invalid_grant', 'código inválido');
      return;
    }
    if (grant.used) {
      // Reutilización: se invalida lo emitido con ese código (RFC 6749 §4.1.2).
      revokeFamily(grant.family);
      oauthError(res, 400, 'invalid_grant', 'código ya utilizado');
      return;
    }
    grant.used = true; // Un solo intento por código, válido o no.
    const verifier = params.get('code_verifier') ?? '';
    const challenge = createHash('sha256').update(verifier, 'ascii').digest('base64url');
    const valid =
      grant.expiresAt > nowS() &&
      safeEqual(clientId, grant.authorization.clientId) &&
      params.get('redirect_uri') === grant.authorization.redirectUri &&
      /^[A-Za-z0-9._~-]{43,128}$/.test(verifier) &&
      safeEqual(challenge, grant.authorization.codeChallenge);
    if (!valid) {
      oauthError(res, 400, 'invalid_grant', 'código, redirect_uri o code_verifier inválidos');
      return;
    }
    const { authorization } = grant;
    grant.family = newFamily(authorization.scopes);
    sendJson(
      res,
      200,
      issueTokens(
        clientId,
        authorization.scopes,
        authorization.audience,
        grant.session,
        authorization.nonce,
        grant.family,
      ),
    );
    return;
  }
  if (grantType === 'refresh_token') {
    const entry = refreshTokens.get(sha256(params.get('refresh_token') ?? ''));
    const family = entry === undefined ? undefined : families.get(entry.family);
    if (entry === undefined || family === undefined || family.revoked) {
      oauthError(res, 400, 'invalid_grant', 'refresh token inválido');
      return;
    }
    if (entry.used) {
      // Detección de reutilización: se revoca toda la familia.
      family.revoked = true;
      oauthError(res, 400, 'invalid_grant', 'refresh token reutilizado');
      return;
    }
    entry.used = true;
    const now = nowS();
    if (entry.expiresAt <= now || family.expiresAt <= now || !safeEqual(clientId, entry.clientId)) {
      family.revoked = true;
      oauthError(res, 400, 'invalid_grant', 'refresh token caducado o de otro cliente');
      return;
    }
    const requested = params.get('scope');
    const scopes =
      requested === undefined ? entry.scopes : requested.split(' ').filter((s) => s !== '');
    if (scopes.some((scope) => !entry.scopes.includes(scope)) || !scopes.includes('openid')) {
      oauthError(res, 400, 'invalid_scope', 'scope fuera del concedido');
      return;
    }
    sendJson(
      res,
      200,
      issueTokens(clientId, scopes, entry.audience, entry.session, null, entry.family),
    );
    return;
  }
  oauthError(res, 400, 'unsupported_grant_type', 'solo authorization_code y refresh_token');
}

// ---------- /v2/logout ----------
function handleLogout(res: ServerResponse, query: URLSearchParams): void {
  let params: Map<string, string>;
  try {
    params = uniqueParams(query);
  } catch {
    sendHtml(res, 400, 'Solicitud inválida', '<p>Parámetros repetidos o demasiado largos.</p>');
    return;
  }
  const clientId = params.get('client_id');
  const returnTo = params.get('returnTo');
  if (clientId !== undefined && !safeEqual(clientId, config.clientId)) {
    sendHtml(res, 400, 'Solicitud inválida', '<p>client_id no registrado.</p>');
    return;
  }
  if (returnTo === undefined) {
    sendHtml(res, 200, 'Sesión cerrada', '<p>Puedes cerrar esta ventana.</p>');
    return;
  }
  if (!config.logoutUrls.has(returnTo)) {
    sendHtml(res, 400, 'Solicitud inválida', '<p>returnTo no registrado.</p>');
    return;
  }
  redirect(res, 302, returnTo);
}

// ---------- Cloudinary ----------
type ResourceType = 'image' | 'video';

interface MediaInfo {
  readonly format: string;
  readonly resourceType: ResourceType;
  readonly contentType: string;
  readonly width?: number;
  readonly height?: number;
  readonly duration?: number;
}

interface StoredResource {
  readonly publicId: string;
  readonly folder: string;
  readonly version: number;
  readonly versionId: string;
  readonly assetId: string;
  readonly createdAt: string;
  readonly etag: string;
  readonly info: MediaInfo;
  readonly data: Buffer;
}

const resources = new Map<string, StoredResource>();
let storedBytes = 0;

const PUBLIC_ID = /^[A-Za-z0-9_-]+(\/[A-Za-z0-9_-]+)*$/;
const UNSIGNED_PARAMS = new Set(['file', 'cloud_name', 'resource_type', 'api_key', 'signature']);

function cloudinaryError(res: ServerResponse, status: number, message: string): void {
  sendJson(res, status, { error: { message } });
}

function corsHeaders(req: IncomingMessage): Record<string, string> {
  return req.headers.origin === config.appOrigin
    ? { 'access-control-allow-origin': config.appOrigin, vary: 'Origin' }
    : { vary: 'Origin' };
}

/** Firma de Cloudinary: parámetros no vacíos ordenados, `k=v&…` y el secreto; SHA-1 o SHA-256. */
function cloudinarySignatureValid(params: Map<string, string>): boolean {
  const signature = params.get('signature') ?? '';
  const algorithm = /^[0-9a-f]{40}$/.test(signature)
    ? 'sha1'
    : /^[0-9a-f]{64}$/.test(signature)
      ? 'sha256'
      : null;
  if (algorithm === null) return false;
  const toSign = [...params]
    .filter(([key, value]) => !UNSIGNED_PARAMS.has(key) && value !== '')
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
    .map(([key, value]) => `${key}=${value}`)
    .join('&');
  const expected = createHash(algorithm).update(`${toSign}${config.cloudApiSecret}`).digest();
  return timingSafeEqual(expected, Buffer.from(signature, 'hex'));
}

/** Verifica api_key, marca de tiempo (máximo 1 h, como Cloudinary) y firma. */
function verifySignedRequest(res: ServerResponse, params: Map<string, string>): boolean {
  if (!safeEqual(params.get('api_key') ?? '', config.cloudApiKey)) {
    cloudinaryError(res, 401, 'Unknown API key');
    return false;
  }
  const timestamp = params.get('timestamp') ?? '';
  if (
    !/^\d{1,12}$/.test(timestamp) ||
    Math.abs(nowS() - Number(timestamp)) > UPLOAD_SIGNATURE_MAX_AGE_S
  ) {
    cloudinaryError(res, 400, 'Stale request - timestamp missing or older than 1 hour');
    return false;
  }
  if (!cloudinarySignatureValid(params)) {
    cloudinaryError(res, 401, 'Invalid Signature');
    return false;
  }
  return true;
}

async function readCloudinaryForm(
  req: IncomingMessage,
  limit: number,
): Promise<{ params: Map<string, string>; file: File | null }> {
  const type = mediaType(req);
  if (type !== 'multipart/form-data' && type !== 'application/x-www-form-urlencoded') {
    throw new HttpError(400, 'invalid_request', 'Unsupported content type');
  }
  const body = await readBody(req, limit);
  let form: FormData;
  try {
    form = await new Request('http://dev-stubs.invalid/', {
      method: 'POST',
      headers: { 'content-type': req.headers['content-type'] ?? '' },
      body,
    }).formData();
  } catch {
    throw new HttpError(400, 'invalid_request', 'Invalid form body');
  }
  const entries: [string, string][] = [];
  let file: File | null = null;
  for (const [key, value] of form) {
    if (key === 'file') {
      // Solo carga binaria: el doble no descarga URLs remotas (SSRF).
      if (file !== null || typeof value === 'string') {
        throw new HttpError(400, 'invalid_request', 'file must be a single binary upload');
      }
      file = value;
      entries.push([key, '']);
    } else if (typeof value === 'string') {
      entries.push([key, value]);
    } else {
      throw new HttpError(400, 'invalid_request', `unexpected file field: ${key}`);
    }
  }
  return { params: uniqueParams(entries), file };
}

function sniffMedia(data: Buffer): MediaInfo | null {
  if (data.length >= 24 && data.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex'))) {
    return {
      format: 'png',
      resourceType: 'image',
      contentType: 'image/png',
      width: data.readUInt32BE(16),
      height: data.readUInt32BE(20),
    };
  }
  if (data.length >= 4 && data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff) {
    return { format: 'jpg', resourceType: 'image', contentType: 'image/jpeg', ...jpegSize(data) };
  }
  const head = data.subarray(0, 12).toString('latin1');
  if (head.startsWith('RIFF') && head.endsWith('WEBP')) {
    return { format: 'webp', resourceType: 'image', contentType: 'image/webp', ...webpSize(data) };
  }
  if ((head.startsWith('GIF87a') || head.startsWith('GIF89a')) && data.length >= 10) {
    return {
      format: 'gif',
      resourceType: 'image',
      contentType: 'image/gif',
      width: data.readUInt16LE(6),
      height: data.readUInt16LE(8),
    };
  }
  if (data.length >= 12 && head.slice(4, 8) === 'ftyp') {
    const quicktime = head.slice(8, 12) === 'qt  ';
    const duration = mp4Duration(data);
    return {
      format: quicktime ? 'mov' : 'mp4',
      resourceType: 'video',
      contentType: quicktime ? 'video/quicktime' : 'video/mp4',
      ...(duration === null ? {} : { duration }),
    };
  }
  return null;
}

function jpegSize(data: Buffer): { width?: number; height?: number } {
  let offset = 2;
  while (offset + 9 < data.length) {
    if (data[offset] !== 0xff) return {};
    const marker = data[offset + 1] ?? 0;
    if (marker === 0xff) {
      offset += 1;
      continue;
    }
    const isSof = marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker);
    if (isSof)
      return { height: data.readUInt16BE(offset + 5), width: data.readUInt16BE(offset + 7) };
    if (marker === 0xd8 || marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) {
      offset += 2;
      continue;
    }
    offset += 2 + data.readUInt16BE(offset + 2);
  }
  return {};
}

function webpSize(data: Buffer): { width?: number; height?: number } {
  if (data.length < 30) return {};
  const chunk = data.subarray(12, 16).toString('latin1');
  if (chunk === 'VP8X')
    return { width: 1 + data.readUIntLE(24, 3), height: 1 + data.readUIntLE(27, 3) };
  if (chunk === 'VP8 ') {
    return { width: data.readUInt16LE(26) & 0x3fff, height: data.readUInt16LE(28) & 0x3fff };
  }
  if (chunk === 'VP8L') {
    const bits = data.readUInt32LE(21);
    return { width: (bits & 0x3fff) + 1, height: ((bits >>> 14) & 0x3fff) + 1 };
  }
  return {};
}

/** Duración en segundos desde moov/mvhd de un contenedor ISO BMFF. */
function mp4Duration(data: Buffer): number | null {
  const findBox = (start: number, end: number, type: string): [number, number] | null => {
    let offset = start;
    while (offset + 8 <= end) {
      let size = data.readUInt32BE(offset);
      let header = 8;
      if (size === 1) {
        if (offset + 16 > end) return null;
        size = Number(data.readBigUInt64BE(offset + 8));
        header = 16;
      } else if (size === 0) {
        size = end - offset;
      }
      if (size < header || offset + size > end) return null;
      if (data.toString('latin1', offset + 4, offset + 8) === type) {
        return [offset + header, offset + size];
      }
      offset += size;
    }
    return null;
  };
  const moov = findBox(0, data.length, 'moov');
  const mvhd = moov === null ? null : findBox(moov[0], moov[1], 'mvhd');
  if (mvhd === null) return null;
  const [start, end] = mvhd;
  const version = data[start];
  const fields = version === 1 ? start + 4 + 16 : start + 4 + 8;
  if (fields + (version === 1 ? 12 : 8) > end) return null;
  const timescale = data.readUInt32BE(fields);
  const units =
    version === 1 ? Number(data.readBigUInt64BE(fields + 4)) : data.readUInt32BE(fields + 4);
  return timescale === 0 ? null : Math.round((units / timescale) * 1000) / 1000;
}

function describeResource(resource: StoredResource): Record<string, unknown> {
  const { info } = resource;
  const url = `${config.publicBase}/cloudinary/${config.cloudName}/${info.resourceType}/upload/v${String(resource.version)}/${resource.publicId}.${info.format}`;
  return {
    asset_id: resource.assetId,
    public_id: resource.publicId,
    version: resource.version,
    version_id: resource.versionId,
    format: info.format,
    resource_type: info.resourceType,
    type: 'upload',
    created_at: resource.createdAt,
    bytes: resource.data.length,
    ...(info.width === undefined ? {} : { width: info.width }),
    ...(info.height === undefined ? {} : { height: info.height }),
    ...(info.duration === undefined ? {} : { duration: info.duration }),
    ...(resource.folder === '' ? {} : { asset_folder: resource.folder }),
    etag: resource.etag,
    placeholder: false,
    url,
    secure_url: url,
  };
}

function storeResource(resource: StoredResource): void {
  const key = `${resource.info.resourceType}/${resource.publicId}`;
  const previous = resources.get(key);
  if (previous !== undefined) {
    storedBytes -= previous.data.length;
    resources.delete(key);
  }
  // Memoria acotada: se descartan los recursos más antiguos.
  for (const [oldKey, old] of resources) {
    if (storedBytes + resource.data.length <= MEDIA_STORE_LIMIT) break;
    storedBytes -= old.data.length;
    resources.delete(oldKey);
  }
  resources.set(key, resource);
  storedBytes += resource.data.length;
}

async function handleUpload(
  req: IncomingMessage,
  res: ServerResponse,
  resourceType: ResourceType,
): Promise<void> {
  const { params, file } = await readCloudinaryForm(req, UPLOAD_LIMIT);
  if (file === null) {
    cloudinaryError(res, 400, 'Missing required parameter - file');
    return;
  }
  if (!verifySignedRequest(res, params)) return;
  const folder = params.get('folder') ?? '';
  const requestedId = params.get('public_id') ?? '';
  if (
    (folder !== '' && !PUBLIC_ID.test(folder)) ||
    (requestedId !== '' && !PUBLIC_ID.test(requestedId))
  ) {
    cloudinaryError(res, 400, 'Invalid folder or public_id');
    return;
  }
  const leaf = requestedId === '' ? randomBytes(10).toString('hex') : requestedId;
  const publicId = folder === '' ? leaf : `${folder}/${leaf}`;
  if (publicId.length > 200) {
    cloudinaryError(res, 400, 'public_id too long');
    return;
  }
  const data = Buffer.from(await file.arrayBuffer());
  // El formato se deduce del contenido, nunca de la extensión ni del tipo declarado.
  const info = data.length === 0 ? null : sniffMedia(data);
  if (info?.resourceType !== resourceType) {
    cloudinaryError(
      res,
      400,
      resourceType === 'image' ? 'Invalid image file' : 'Invalid video file',
    );
    return;
  }
  const resource: StoredResource = {
    publicId,
    folder,
    version: nowS(),
    versionId: randomBytes(16).toString('hex'),
    assetId: randomBytes(16).toString('hex'),
    createdAt: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
    etag: createHash('md5').update(data).digest('hex'),
    info,
    data,
  };
  storeResource(resource);
  const signature = createHash('sha1')
    .update(`public_id=${publicId}&version=${String(resource.version)}${config.cloudApiSecret}`)
    .digest('hex');
  sendJson(res, 200, { ...describeResource(resource), signature }, corsHeaders(req));
}

async function handleDestroy(
  req: IncomingMessage,
  res: ServerResponse,
  resourceType: ResourceType,
): Promise<void> {
  const { params, file } = await readCloudinaryForm(req, BODY_LIMIT);
  if (file !== null) {
    cloudinaryError(res, 400, 'Unexpected file');
    return;
  }
  if (!verifySignedRequest(res, params)) return;
  const key = `${resourceType}/${params.get('public_id') ?? ''}`;
  const resource = resources.get(key);
  if (resource === undefined) {
    sendJson(res, 200, { result: 'not found' });
    return;
  }
  storedBytes -= resource.data.length;
  resources.delete(key);
  sendJson(res, 200, { result: 'ok' });
}

/** Admin API: Basic api_key:api_secret, como Cloudinary. */
function handleResourceLookup(
  req: IncomingMessage,
  res: ServerResponse,
  resourceType: ResourceType,
  encodedId: string,
): void {
  const match = /^Basic ([A-Za-z0-9+/]+={0,2})$/.exec(req.headers.authorization ?? '');
  const decoded = match?.[1] === undefined ? '' : Buffer.from(match[1], 'base64').toString('utf8');
  const colon = decoded.indexOf(':');
  const authorized =
    colon > 0 &&
    safeEqual(decoded.slice(0, colon), config.cloudApiKey) &&
    safeEqual(decoded.slice(colon + 1), config.cloudApiSecret);
  if (!authorized) {
    cloudinaryError(res, 401, 'Invalid credentials');
    return;
  }
  let publicId: string;
  try {
    publicId = decodeURIComponent(encodedId);
  } catch {
    cloudinaryError(res, 400, 'Invalid public_id');
    return;
  }
  const resource = PUBLIC_ID.test(publicId)
    ? resources.get(`${resourceType}/${publicId}`)
    : undefined;
  if (resource === undefined) {
    cloudinaryError(res, 404, 'Resource not found');
    return;
  }
  sendJson(res, 200, describeResource(resource));
}

function handleDelivery(
  res: ServerResponse,
  resourceType: ResourceType,
  version: string,
  publicId: string,
  format: string,
): void {
  const resource = resources.get(`${resourceType}/${publicId}`);
  if (
    resource === undefined ||
    String(resource.version) !== version ||
    resource.info.format !== format
  ) {
    sendJson(res, 404, { error: 'not_found' });
    return;
  }
  res.writeHead(200, {
    ...BASE_HEADERS,
    'content-type': resource.info.contentType,
    'content-length': String(resource.data.length),
    'content-security-policy': "default-src 'none'",
  });
  res.end(resource.data);
}

// ---------- SendGrid: evento de entrega firmado hacia la API ----------
const SENDGRID_EVENTS = new Set([
  'processed',
  'deferred',
  'delivered',
  'bounce',
  'dropped',
  'spamreport',
]);
const RESERVED_EVENT_FIELDS = new Set([
  'email',
  'timestamp',
  'event',
  'sg_event_id',
  'sg_message_id',
  'type',
  'status',
  'reason',
  'response',
  'attempt',
]);

function optionalText(value: unknown, pattern: RegExp, field: string): string | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== 'string' || !pattern.test(value)) {
    throw new HttpError(400, 'invalid_request', `${field} inválido`);
  }
  return value;
}

function buildSendgridEvent(input: Record<string, unknown>): Record<string, unknown> {
  const known = new Set([
    'event',
    'email',
    'sg_message_id',
    'sg_event_id',
    'type',
    'reason',
    'timestamp',
    'custom_args',
  ]);
  for (const key of Object.keys(input)) {
    if (!known.has(key)) throw new HttpError(400, 'invalid_request', `campo desconocido: ${key}`);
  }
  const event = input['event'];
  if (typeof event !== 'string' || !SENDGRID_EVENTS.has(event)) {
    throw new HttpError(
      400,
      'invalid_request',
      `event debe ser uno de ${[...SENDGRID_EVENTS].join(', ')}`,
    );
  }
  const email = optionalText(input['email'], /^[^\s@<>]{1,64}@[^\s@<>]{1,189}$/, 'email');
  const messageId = optionalText(
    input['sg_message_id'],
    /^[A-Za-z0-9._-]{1,200}$/,
    'sg_message_id',
  );
  if (email === undefined || messageId === undefined) {
    throw new HttpError(400, 'invalid_request', 'email y sg_message_id son obligatorios');
  }
  const eventId =
    optionalText(input['sg_event_id'], /^[A-Za-z0-9_-]{1,100}$/, 'sg_event_id') ?? randomToken(16);
  const bounceType = optionalText(input['type'], /^(bounce|blocked)$/, 'type');
  if (bounceType !== undefined && event !== 'bounce') {
    throw new HttpError(400, 'invalid_request', 'type solo aplica a bounce');
  }
  const reason = optionalText(input['reason'], /^\P{Cc}{1,500}$/u, 'reason');
  const now = nowS();
  const rawTimestamp = input['timestamp'];
  if (
    rawTimestamp !== undefined &&
    (typeof rawTimestamp !== 'number' ||
      !Number.isInteger(rawTimestamp) ||
      rawTimestamp < now - 30 * 86_400 ||
      rawTimestamp > now + 86_400)
  ) {
    throw new HttpError(400, 'invalid_request', 'timestamp: entero Unix de los últimos 30 días');
  }
  const timestamp = typeof rawTimestamp === 'number' ? rawTimestamp : now;

  const customArgs: Record<string, string> = {};
  const rawArgs = input['custom_args'];
  if (rawArgs !== undefined) {
    if (typeof rawArgs !== 'object' || rawArgs === null || Array.isArray(rawArgs)) {
      throw new HttpError(400, 'invalid_request', 'custom_args debe ser un objeto');
    }
    const entries = Object.entries(rawArgs);
    if (entries.length > 10) throw new HttpError(400, 'invalid_request', 'custom_args: máximo 10');
    for (const [key, value] of entries) {
      if (!/^[a-z][a-z0-9_]{0,49}$/.test(key) || RESERVED_EVENT_FIELDS.has(key)) {
        throw new HttpError(400, 'invalid_request', 'custom_args: clave inválida');
      }
      if (typeof value !== 'string' || value.length > 200) {
        throw new HttpError(400, 'invalid_request', 'custom_args: valor inválido');
      }
      customArgs[key] = value;
    }
  }

  const details: Record<string, unknown> = {};
  if (event === 'bounce') {
    const permanent = (bounceType ?? 'bounce') === 'bounce';
    details['type'] = bounceType ?? 'bounce';
    details['status'] = permanent ? '5.1.1' : '4.0.0';
    details['reason'] = reason ?? (permanent ? '550 5.1.1 Mailbox does not exist' : 'Blocked');
  } else if (event === 'dropped') {
    details['reason'] = reason ?? 'Bounced Address';
  } else if (event === 'deferred') {
    details['response'] = reason ?? '421 Try again later';
    details['attempt'] = '1';
  } else if (event === 'delivered') {
    details['response'] = '250 OK';
  }
  return {
    ...customArgs,
    email,
    timestamp,
    event,
    sg_event_id: eventId,
    sg_message_id: messageId,
    ...details,
  };
}

async function handleSendgridEvent(req: IncomingMessage, res: ServerResponse): Promise<void> {
  if (config.sendgridKey === null) {
    sendJson(res, 503, { error: 'sendgrid_key_missing' });
    return;
  }
  // application/json obliga al navegador a una comprobación CORS previa que aquí no se concede.
  if (mediaType(req) !== 'application/json') {
    throw new HttpError(415, 'unsupported_media_type', 'se esperaba application/json');
  }
  const event = buildSendgridEvent(parseJsonObject((await readBody(req, BODY_LIMIT)).toString()));
  const body = JSON.stringify([event]);
  // Como SendGrid: la cabecera lleva la hora de envío de la petición, no la del evento (cuerpo).
  const timestamp = String(nowS());
  // ECDSA P-256 con SHA-256 sobre timestamp + cuerpo crudo, firma DER en base64.
  const signature = sign('sha256', Buffer.from(timestamp + body), {
    key: config.sendgridKey,
    dsaEncoding: 'der',
  }).toString('base64');
  const headers = {
    'content-type': 'application/json',
    'user-agent': 'SendGrid Event API',
    'x-twilio-email-event-webhook-signature': signature,
    'x-twilio-email-event-webhook-timestamp': timestamp,
  };
  const delivery = { url: SENDGRID_WEBHOOK_TARGET, headers, body };
  try {
    const response = await fetch(SENDGRID_WEBHOOK_TARGET, {
      method: 'POST',
      headers,
      body,
      redirect: 'manual',
      signal: AbortSignal.timeout(API_TIMEOUT_MS),
    });
    await response.body?.cancel();
    sendJson(res, 200, { forwarded: true, apiStatus: response.status, delivery });
  } catch {
    sendJson(res, 502, { forwarded: false, error: 'api_unreachable', delivery });
  }
}

// ---------- Enrutado ----------
const UPLOAD_PATH = /^\/cloudinary\/v1_1\/([^/]+)\/(image|video)\/upload$/;
const DESTROY_PATH = /^\/cloudinary\/v1_1\/([^/]+)\/(image|video)\/destroy$/;
const RESOURCE_PATH = /^\/cloudinary\/v1_1\/([^/]+)\/resources\/(image|video)\/upload\/(.+)$/;
const DELIVERY_PATH =
  /^\/cloudinary\/([^/]+)\/(image|video)\/upload\/v(\d{1,12})\/(.+)\.([a-z0-9]{2,5})$/;

function methodNotAllowed(res: ServerResponse, allow: string): void {
  sendJson(res, 405, { error: 'method_not_allowed' }, { allow });
}

async function route(req: IncomingMessage, res: ServerResponse): Promise<void> {
  // La URL base es fija: nunca se usa la cabecera Host.
  const url = new URL(req.url ?? '/', 'http://dev-stubs.invalid');
  const path = url.pathname;
  const method = req.method ?? 'GET';
  const is = (expected: string, allow = expected): boolean => {
    if (method === expected) return true;
    methodNotAllowed(res, allow);
    return false;
  };

  if (path === '/health/live') {
    if (is('GET')) sendJson(res, 200, { status: 'ok' });
    return;
  }
  if (path === '/.well-known/openid-configuration') {
    if (is('GET')) sendJson(res, 200, DISCOVERY);
    return;
  }
  if (path === '/.well-known/jwks.json') {
    if (is('GET')) sendJson(res, 200, JWKS);
    return;
  }
  if (path === '/authorize') {
    if (is('GET')) handleAuthorize(res, url.searchParams);
    return;
  }
  if (path === '/u/login') {
    if (is('POST')) await handleLoginDecision(req, res);
    return;
  }
  if (path === '/oauth/token') {
    if (is('POST')) await handleToken(req, res);
    return;
  }
  if (path === '/v2/logout') {
    if (is('GET')) handleLogout(res, url.searchParams);
    return;
  }
  if (path === '/dev/sendgrid/event') {
    if (is('POST')) await handleSendgridEvent(req, res);
    return;
  }

  const upload = UPLOAD_PATH.exec(path);
  if (upload !== null) {
    if (method === 'OPTIONS') {
      res.writeHead(204, {
        ...corsHeaders(req),
        'access-control-allow-methods': 'POST',
        'access-control-allow-headers': 'content-type, x-requested-with',
        'access-control-max-age': '600',
      });
      res.end();
      return;
    }
    if (!is('POST', 'POST, OPTIONS')) return;
    if (upload[1] !== config.cloudName) {
      cloudinaryError(res, 404, 'Invalid cloud_name');
      return;
    }
    await handleUpload(req, res, upload[2] === 'video' ? 'video' : 'image');
    return;
  }
  const destroy = DESTROY_PATH.exec(path);
  if (destroy !== null) {
    if (!is('POST')) return;
    if (destroy[1] !== config.cloudName) {
      cloudinaryError(res, 404, 'Invalid cloud_name');
      return;
    }
    await handleDestroy(req, res, destroy[2] === 'video' ? 'video' : 'image');
    return;
  }
  const lookup = RESOURCE_PATH.exec(path);
  if (lookup !== null) {
    if (!is('GET')) return;
    if (lookup[1] !== config.cloudName) {
      cloudinaryError(res, 404, 'Invalid cloud_name');
      return;
    }
    handleResourceLookup(req, res, lookup[2] === 'video' ? 'video' : 'image', lookup[3] ?? '');
    return;
  }
  const delivery = DELIVERY_PATH.exec(path);
  if (delivery !== null && delivery[1] === config.cloudName) {
    if (!is('GET')) return;
    const [, , type, version = '', publicId = '', format = ''] = delivery;
    handleDelivery(res, type === 'video' ? 'video' : 'image', version, publicId, format);
    return;
  }
  sendJson(res, 404, { error: 'not_found' });
}

const server = createServer((req, res) => {
  route(req, res).catch((error: unknown) => {
    if (error instanceof HttpError) {
      if (!res.headersSent) {
        sendJson(
          res,
          error.status,
          { error: error.code, error_description: error.message },
          error.status === 413 ? { connection: 'close' } : {},
        );
      }
      return;
    }
    // Solo el tipo de error: el mensaje podría contener datos de la petición.
    process.stderr.write(
      `dev-stubs: error interno (${error instanceof Error ? error.name : 'desconocido'})\n`,
    );
    if (res.headersSent) res.destroy();
    else sendJson(res, 500, { error: 'server_error' });
  });
});
server.headersTimeout = 10_000;
server.requestTimeout = 120_000;
server.maxHeadersCount = 100;

server.listen(PORT, '0.0.0.0', () => {
  process.stdout.write(`dev-stubs a la escucha en ${String(PORT)}\n`);
});

for (const signal of ['SIGTERM', 'SIGINT'] as const) {
  process.once(signal, () => {
    server.close();
    server.closeIdleConnections();
  });
}
