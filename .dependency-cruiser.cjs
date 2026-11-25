// Capa 1 de ADRs: grafo de dependencias. La matriz de ADR-ARCH-003 se declara SOLO aquí. Ruta protegida.
const MATRIX = {
  'identity-access': [],
  organizations: ['identity-access'],
  'taxonomy-templates': ['organizations'],
  'provider-catalog': ['identity-access', 'taxonomy-templates'],
  'event-management': ['organizations', 'taxonomy-templates'],
  'availability-booking': ['organizations', 'provider-catalog'],
  'rfq-offers': ['organizations', 'provider-catalog', 'availability-booking'],
  quotation: [
    'organizations',
    'event-management',
    'provider-catalog',
    'taxonomy-templates',
    'availability-booking',
    'rfq-offers',
  ],
  'assisted-response': ['rfq-offers'],
  reviews: ['organizations', 'availability-booking'],
  'messaging-notifications': ['identity-access', 'organizations', 'taxonomy-templates'],
  'administration-audit': '*',
};

const MODULES = Object.keys(MATRIX);
const MODULE = '^backend/src/modules/';
const TESTS = '^backend/src/tests/';
const NPM = (names) => `(^|/)node_modules/(${names})(/|$)`;

const rule = (name, from, to, comment) => ({ name, comment, severity: 'error', from, to });

const matrixRules = MODULES.filter((m) => MATRIX[m] !== '*').map((m) =>
  rule(
    `matrix-${m}`,
    { path: `${MODULE}${m}/` },
    { path: `${MODULE}(${MODULES.filter((o) => o !== m && !MATRIX[m].includes(o)).join('|')})/` },
    'ADR-ARCH-003 R1 y R4: dependencia entre módulos no permitida.',
  ),
);

module.exports = {
  forbidden: [
    rule('no-circular', {}, { circular: true }, 'ADR-ARCH-003 R3.'),
    rule('not-to-unresolvable', {}, { couldNotResolve: true }, 'Importación sin resolver.'),
    rule(
      'layer-domain-pure',
      { path: `${MODULE}([^/]+)/(.*/|)domain/` },
      {
        pathNot: [`${MODULE}$1/(.*/|)domain/`, '^backend/src/shared/domain/', NPM('decimal\\.js')],
      },
      'ADR-ARCH-002 R1.',
    ),
    rule(
      'layer-shared-domain-pure',
      { path: '^backend/src/shared/domain/' },
      { pathNot: ['^backend/src/shared/domain/', NPM('decimal\\.js')] },
      'ADR-ARCH-002 R1 y ADR-ARCH-004.',
    ),
    rule(
      'layer-application-ports',
      { path: `${MODULE}[^/]+/(.*/|)application/` },
      {
        path: [
          `${MODULE}[^/]+/(.*/|)(infrastructure|http)/`,
          '^backend/src/(jobs|bootstrap|http|prisma)/',
          NPM('express|@prisma|pg|ioredis|bullmq|@sendgrid|cloudinary|@auth0|nodemailer|pino'),
        ],
      },
      'ADR-ARCH-002 R2.',
    ),
    rule(
      'layer-http-no-infra',
      { path: [`${MODULE}[^/]+/(.*/|)http/`, '^backend/src/(http|shared/http)/'] },
      { path: [`${MODULE}[^/]+/(.*/|)infrastructure/`, '^backend/src/prisma/', NPM('@prisma|pg')] },
      'ADR-ARCH-002 R4.',
    ),
    rule(
      'http-no-policies-or-repositories',
      { path: `${MODULE}[^/]+/(.*/|)http/` },
      { path: `${MODULE}[^/]+/(.*/|)domain/.*(repository|policy)[^/]*\\.ts$` },
      'ADR-ARCH-007 R2.',
    ),
    rule(
      'wiring-only-bootstrap',
      {
        pathNot: [
          '^backend/src/bootstrap/container\\.ts$',
          TESTS,
          `${MODULE}[^/]+/(.*/|)infrastructure/`,
        ],
      },
      { path: `${MODULE}[^/]+/(.*/|)infrastructure/` },
      'ADR-ARCH-002 R5: solo bootstrap/container.ts une implementaciones con interfaces.',
    ),
    rule(
      'cross-module-only-index',
      { path: `${MODULE}([^/]+)/` },
      { path: `${MODULE}[^/]+/`, pathNot: [`${MODULE}$1/`, `${MODULE}[^/]+/index\\.ts$`] },
      'ADR-ARCH-003 R2.',
    ),
    rule(
      'outside-modules-only-index',
      { path: '^backend/src/(jobs|http|shared|prisma)/' },
      { path: MODULE, pathNot: `${MODULE}[^/]+/index\\.ts$` },
      'ADR-ARCH-003 R2.',
    ),
    ...matrixRules,
    rule(
      'shared-no-modules',
      { path: '^backend/src/shared/' },
      { path: '^backend/src/(modules|jobs|bootstrap)/' },
      'ADR-ARCH-004 R1.',
    ),
    rule(
      'jobs-no-prisma',
      { path: '^backend/src/jobs/' },
      {
        path: [
          NPM('@prisma|pg'),
          '^backend/src/prisma/',
          '^backend/src/shared/infrastructure/database/',
        ],
      },
      'ADR-ARCH-001 R4.',
    ),
    rule(
      'no-http-between-modules',
      { path: `${MODULE}[^/]+/(.*/|)(domain|application|http)/` },
      { path: ['^(node:)?(http|https|http2)$', NPM('axios|got|undici|node-fetch')] },
      'ADR-ARCH-001 R3.',
    ),
    rule(
      'redis-restricted',
      {
        path: '^backend/src/',
        pathNot: [
          '^backend/src/(shared/infrastructure|jobs|bootstrap)/',
          `${MODULE}messaging-notifications/(.*/|)infrastructure/`,
          TESTS,
        ],
      },
      { path: NPM('ioredis|bullmq|redis') },
      'ADR-DATA-001 R2.',
    ),
    {
      name: 'mail-only-from-worker',
      comment: 'ADR-DATA-006 R2: el correo no es alcanzable desde la API.',
      severity: 'error',
      from: { path: '^backend/src/bootstrap/server\\.ts$' },
      to: {
        path: [NPM('nodemailer|@sendgrid'), '^backend/src/shared/infrastructure/email/'],
        reachable: true,
      },
    },
    rule(
      'pino-only-observability',
      {
        path: '^(backend|frontend)/src/',
        pathNot: ['^backend/src/shared/observability/', '^frontend/src/lib/observability/', TESTS],
      },
      { path: NPM('pino') },
      'ADR-OBS-001.',
    ),
    rule(
      'frontend-no-backend',
      { path: '^frontend/' },
      { path: ['^backend/', NPM('@prisma|pg|ioredis|bullmq')] },
      'ADR-ARCH-008 R1.',
    ),
    rule('backend-no-frontend', { path: '^backend/' }, { path: '^frontend/' }, 'ADR-ARCH-008.'),
    rule(
      'src-no-tests',
      { path: '^(backend|frontend)/src/', pathNot: TESTS },
      { path: TESTS },
      'El código de producto no importa pruebas.',
    ),
  ],
  options: {
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'frontend/tsconfig.json' },
    doNotFollow: { path: 'node_modules' },
    exclude: {
      path: [
        '^backend/src/tests/architecture/fixtures/',
        '(^|/)\\.next/',
        '^(backend|frontend)/dist/',
        '^backend/src/prisma/generated/',
      ],
    },
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default', 'types', 'react-server'],
      extensions: ['.ts', '.tsx', '.d.ts', '.js', '.mjs', '.cjs', '.json'],
    },
  },
};
