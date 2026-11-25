// Capa 1 de ADRs (ADR §6.1). Ruta protegida (ADR-GOV-002): cambiarla exige aprobación humana.
import { readFileSync } from 'node:fs';

import js from '@eslint/js';
import vitest from '@vitest/eslint-plugin';
import boundaries from 'eslint-plugin-boundaries';
import globals from 'globals';
import tseslint from 'typescript-eslint';

import pe from './Tools/eslint-plugin-pe/index.js';

const banned = JSON.parse(
  readFileSync(new URL('./Tools/adr-guard/banned-packages.json', import.meta.url), 'utf8'),
);

// ---------- Importaciones vetadas ----------
const escapeName = (name) => name.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '[^/]+');
const BANNED = banned.packages.map((group) => ({
  regex: `^(?:${group.names.map(escapeName).join('|')})(?:/|$)`,
  message: `${group.adr}: ${group.reason}.`,
}));
const NO_CHILD_PROCESS = { regex: '^(node:)?child_process$', message: 'ADR-SEC-007 R5.' };
const NO_NODE_CONSOLE = { regex: '^(node:)?console$', message: 'ADR-OBS-001 R2.' };
const NO_PINO = {
  regex: '^pino(/|$|-)',
  message: 'ADR-OBS-001: pino solo en shared/observability (web: lib/observability).',
};
const SDK = {
  regex:
    '^(@auth0/|auth0(/|$)|@sendgrid/|cloudinary(/|$)|@googlemaps/|@react-pdf/|bullmq(/|$)|ioredis(/|$)|redis(/|$)|nodemailer(/|$))',
  message: 'ADR-ARCH-006 R1: los SDK externos solo en infrastructure, jobs o bootstrap.',
};
const PERSISTENCE = {
  regex: '^(@prisma/|pg(/|$))|prisma/generated',
  message: 'ADR-ARCH-002: el acceso a datos vive en infrastructure.',
};
const EXPRESS = { regex: '^express(/|$)', message: 'ADR-ARCH-002 R2: sin framework HTTP aquí.' };
const NO_UNVERIFIED_JWT = {
  name: 'jose',
  importNames: ['decodeJwt', 'UnsecuredJWT'],
  message: 'ADR-SEC-001: valida la firma antes de leer un token.',
};
const imports = (...patterns) => [
  'error',
  { paths: [NO_UNVERIFIED_JWT], patterns: [...BANNED, ...patterns] },
];

// ---------- Selectores de sintaxis ----------
const sel = (selector, message) => ({ selector, message });
const SKIPS = '/^(skip|only|todo|fails|skipIf|runIf|fixme)$/';
const TEST_SABOTAGE = [
  sel(
    `MemberExpression[object.name=/^(it|test|describe|suite)$/][property.name=${SKIPS}]`,
    'ADR-TEST-006 R1: prueba omitida o enfocada.',
  ),
  sel(
    `MemberExpression[object.object.name=/^(it|test|describe|suite)$/][property.name=${SKIPS}]`,
    'ADR-TEST-006 R1: prueba omitida o enfocada.',
  ),
  sel(
    'CallExpression[callee.name=/^(xit|xtest|xdescribe|fit|fdescribe)$/]',
    'ADR-TEST-006 R1: prueba omitida o enfocada.',
  ),
  sel(
    "CallExpression[callee.property.name=/^(toBe|toEqual)$/][arguments.0.value=true][callee.object.callee.name='expect'][callee.object.arguments.0.value=true]",
    'TESTs AS-01: aserción trivial.',
  ),
];
const NO_FIXED_OFFSET = [
  sel('Literal[value=/^(UTC|GMT)?[+-]\\d{2}:\\d{2}$/]', 'ADR-DATA-012 R3: usa una zona IANA.'),
  sel('Literal[value=/^(UTC|GMT)[+-]\\d{1,2}$/]', 'ADR-DATA-012 R3: usa una zona IANA.'),
];
const MONEY = '/^(amount|price|total|rate|commission)|(Amount|Price|Total|Rate|Commission)$/';
const NO_MONEY_TO_NUMBER = [
  sel(
    `CallExpression[callee.name=/^(Number|parseFloat|parseInt)$/] > Identifier.arguments[name=${MONEY}]`,
    'ADR-DATA-013 R1: un importe no se convierte a number.',
  ),
  sel(
    `CallExpression[callee.name=/^(Number|parseFloat|parseInt)$/] > MemberExpression.arguments[property.name=${MONEY}]`,
    'ADR-DATA-013 R1: un importe no se convierte a number.',
  ),
  sel(
    `UnaryExpression[operator='+'] > Identifier.argument[name=${MONEY}]`,
    'ADR-DATA-013 R1: un importe no se convierte a number.',
  ),
  sel(
    `UnaryExpression[operator='+'] > MemberExpression.argument[property.name=${MONEY}]`,
    'ADR-DATA-013 R1: un importe no se convierte a number.',
  ),
  sel(
    "CallExpression[callee.property.name='toNumber']",
    'ADR-DATA-013 R1: un importe no se convierte a number.',
  ),
];
const SRC_COMMON = [
  sel("ImportExpression[source.type!='Literal']", 'ADR-ARCH-002: import() solo con literal.'),
  sel(
    'MemberExpression[object.object.name="process"][object.property.name=/^std(out|err)$/][property.name="write"]',
    'ADR-OBS-001 R2: usa el logger.',
  ),
  sel(
    'CallExpression[callee.property.name=/^(trace|debug|info|warn|error|fatal)$/] > Identifier.arguments[name=/^(req|request)$/]',
    'ADR-OBS-002 R3: no registres la petición.',
  ),
  sel(
    'CallExpression[callee.property.name=/^(trace|debug|info|warn|error|fatal)$/] > MemberExpression.arguments[object.name=/^(req|request)$/][property.name=/^(headers|body)$/]',
    'ADR-OBS-002 R3: no registres cabeceras ni cuerpos.',
  ),
  sel(
    'CallExpression[callee.property.name=/^(trace|debug|info|warn|error|fatal)$/] > ObjectExpression > Property > Identifier.value[name=/^(req|request)$/]',
    'ADR-OBS-002 R3: no registres la petición.',
  ),
  ...NO_FIXED_OFFSET,
  ...NO_MONEY_TO_NUMBER,
  ...TEST_SABOTAGE,
];
const BACKEND = [
  ...SRC_COMMON,
  sel('Literal[value=/SERIALIZABLE|Serializable|NOWAIT/]', 'ADR-DATA-003 R1.'),
  sel('TemplateElement[value.raw=/SERIALIZABLE|NOWAIT/i]', 'ADR-DATA-003 R1.'),
  sel("MemberExpression[property.name='Serializable']", 'ADR-DATA-003 R1.'),
  sel(
    'MemberExpression[property.name=/^\\$(queryRawUnsafe|executeRawUnsafe)$/]',
    'ADR-DATA-010 R2.',
  ),
  sel("MemberExpression[object.name='Prisma'][property.name='raw']", 'ADR-DATA-010 R2.'),
  sel(
    'MemberExpression[computed=true][property.value=/^\\$/]',
    'ADR-DATA-010: sin acceso por corchetes a métodos $.',
  ),
  sel(
    'CallExpression[callee.property.name=/^\\$(queryRaw|executeRaw)$/]',
    'ADR-DATA-010 R2: solo como plantilla etiquetada.',
  ),
  sel("MemberExpression[object.name='jwt'][property.name='decode']", 'ADR-SEC-001 R1.'),
  sel(
    "MemberExpression[object.name='Math'][property.name='random']",
    'ADR-SEC-004: usa node:crypto.',
  ),
  sel(
    'Literal[value=/:(token|magicToken|invitationToken)\\b/]',
    'ADR-SEC-004 R3: el token no viaja en la ruta.',
  ),
  sel(
    'TemplateElement[value.raw=/:(token|magicToken|invitationToken)\\b/]',
    'ADR-SEC-004 R3: el token no viaja en la ruta.',
  ),
];
const RAW_SQL_OUTSIDE_INFRA = [
  sel(
    'MemberExpression[property.name=/^\\$(queryRaw|executeRaw)$/]',
    'ADR-DATA-010 R1: SQL solo en infrastructure.',
  ),
];
const NEW_PRISMA = [
  sel(
    "NewExpression[callee.name='PrismaClient']",
    'ADR-STACK-004 R5: un solo PrismaClient, en shared/infrastructure.',
  ),
];
const QUEUE_ADD = [
  sel(
    'CallExpression[callee.property.name=/^(add|addBulk)$/][callee.object.name=/[Qq]ueue$/]',
    'ADR-DATA-006: solo el publicador y el planificador encolan.',
  ),
];
const PROVIDER_URL = [
  sel(
    'Literal[value=/(auth0\\.com|sendgrid\\.com|cloudinary\\.com|googleapis\\.com)/]',
    'ADR-ARCH-006: proveedores externos solo en su adaptador.',
  ),
];
const ERROR_STATUS = [
  sel(
    'CallExpression[callee.property.name=/^(status|sendStatus)$/] > Literal.arguments[value>=400]',
    'ADR-API-003 R3: los errores salen del manejador central.',
  ),
];
const NO_CLOCK = [
  sel(
    "NewExpression[callee.name='Date'][arguments.length=0]",
    'ADR-DATA-012 R4: usa el reloj de shared.',
  ),
  sel(
    "MemberExpression[object.name='Date'][property.name='now']",
    'ADR-DATA-012 R4: usa el reloj de shared.',
  ),
  sel(
    "MemberExpression[object.name='globalThis'][property.name='Date']",
    'ADR-DATA-012 R4: usa el reloj de shared.',
  ),
];
const HTTP_LOOSE_SCHEMA = [
  sel(
    "CallExpression[callee.object.name='z'][callee.property.name=/^(any|unknown|looseObject)$/]",
    'ADR-API-002: schema estricto.',
  ),
  sel(
    'CallExpression[callee.property.name=/^(passthrough|loose)$/]',
    'ADR-API-002: schema estricto.',
  ),
];
const BROWSER = [
  sel('MemberExpression[property.name=/^(localStorage|sessionStorage)$/]', 'ADR-SEC-002 R1.'),
  sel(
    'MemberExpression[property.value=/^(localStorage|sessionStorage|cookie)$/]',
    'ADR-SEC-002 R1.',
  ),
  sel("MemberExpression[object.name='document'][property.name='cookie']", 'ADR-SEC-002 R1.'),
];
const NO_RAW_HTML = [sel("JSXAttribute[name.name='dangerouslySetInnerHTML']", 'ADR-SEC-007 R1.')];
const syntax = (...groups) => ['error', ...groups.flat()];

// Todo lo que se ejecuta fuera de infrastructure comparte estas restricciones.
const OUTSIDE = [RAW_SQL_OUTSIDE_INFRA, NEW_PRISMA, QUEUE_ADD, PROVIDER_URL];

// ---------- Fronteras (ADR-ARCH-002 y ADR-ARCH-003 R2) ----------
const LAYERS = ['domain', 'application', 'infrastructure', 'http'];
const elements = [
  ...LAYERS.map((layer) => ({
    type: layer,
    pattern: `backend/src/modules/*/**/${layer}`,
    partialMatch: false,
    capture: ['module', 'feature'],
  })),
  { type: 'module', pattern: 'backend/src/modules/*', partialMatch: false, capture: ['module'] },
  { type: 'shared-domain', pattern: 'backend/src/shared/domain', partialMatch: false },
  { type: 'shared', pattern: 'backend/src/shared', partialMatch: false },
  { type: 'bootstrap', pattern: 'backend/src/bootstrap', partialMatch: false },
  { type: 'jobs', pattern: 'backend/src/jobs', partialMatch: false },
  { type: 'backend-http', pattern: 'backend/src/http', partialMatch: false },
  { type: 'prisma-generated', pattern: 'backend/src/prisma/generated', partialMatch: false },
  { type: 'seed', pattern: 'backend/src/prisma/seed', partialMatch: false },
  { type: 'tests', pattern: 'backend/src/tests', partialMatch: false },
  { type: 'frontend', pattern: 'frontend/src', partialMatch: false },
];
const element = (...types) => ({ element: { types } });
const own = (layer) => ({
  element: { type: layer, captured: { module: '{{ from.element.captured.module }}' } },
});
const entry = { element: { type: 'module' }, file: { categories: 'module-entry' } };
const packages = { module: { origin: ['external', 'core'] } };
const allow = (type, ...targets) => targets.map((to) => ({ from: element(type), allow: { to } }));
const policies = [
  ...allow('domain', own('domain'), element('shared-domain'), { module: { source: 'decimal.js' } }),
  ...allow(
    'application',
    own('domain'),
    own('application'),
    element('shared', 'shared-domain'),
    entry,
    packages,
  ),
  ...allow(
    'infrastructure',
    own('domain'),
    own('application'),
    own('infrastructure'),
    element('shared', 'shared-domain', 'prisma-generated'),
    entry,
    packages,
  ),
  ...allow(
    'http',
    own('domain'),
    own('application'),
    own('http'),
    element('shared', 'shared-domain'),
    entry,
    packages,
  ),
  ...allow(
    'module',
    own('domain'),
    own('application'),
    own('http'),
    own('module'),
    element('shared', 'shared-domain'),
    packages,
  ),
  ...allow('shared-domain', element('shared-domain'), { module: { source: 'decimal.js' } }),
  ...allow('shared', element('shared', 'shared-domain', 'prisma-generated'), packages),
  ...allow(
    'bootstrap',
    element(
      'bootstrap',
      'shared',
      'shared-domain',
      'jobs',
      'backend-http',
      'module',
      ...LAYERS,
      'prisma-generated',
    ),
    packages,
  ),
  ...allow('jobs', element('jobs', 'shared', 'shared-domain'), entry, packages),
  ...allow('backend-http', element('backend-http', 'shared', 'shared-domain'), entry, packages),
  ...allow('seed', element('seed', 'shared', 'shared-domain', 'prisma-generated'), entry, packages),
  ...allow('prisma-generated', element('prisma-generated'), packages),
  ...allow(
    'tests',
    element(
      'tests',
      'bootstrap',
      'shared',
      'shared-domain',
      'jobs',
      'backend-http',
      'module',
      ...LAYERS,
      'prisma-generated',
      'seed',
    ),
    packages,
  ),
  ...allow('frontend', element('frontend'), packages),
];

export function createConfig(rootDir) {
  return tseslint.config(
    {
      ignores: [
        '**/node_modules/**',
        '**/dist/**',
        '**/.next/**',
        '**/coverage/**',
        '**/prisma/generated/**',
        '**/next-env.d.ts',
        'playwright-report/**',
        'test-results/**',
        'backend/src/tests/architecture/fixtures/**',
        'Plans/**',
        'Reviews/**',
        '.agents/**',
        '.claude/**',
        '.hermes/**',
        '.zcode/**',
      ],
    },
    { linterOptions: { noInlineConfig: true, reportUnusedDisableDirectives: 'error' } },
    {
      files: ['**/*.{js,mjs,cjs,ts,tsx}'],
      extends: [js.configs.recommended],
      plugins: { pe },
      rules: {
        'pe/no-suppression-comments': 'error',
        'no-eval': 'error',
        'no-implied-eval': 'error',
        'no-new-func': 'error',
        'no-restricted-syntax': syntax(TEST_SABOTAGE),
        'no-restricted-imports': imports(),
      },
    },
    { files: ['**/*.{js,mjs,cjs}'], languageOptions: { globals: { ...globals.node } } },
    {
      files: ['backend/src/tests/load/**/*.js'],
      languageOptions: { globals: { __ENV: 'readonly', __VU: 'readonly', __ITER: 'readonly' } },
    },
    {
      files: ['**/*.{ts,tsx}'],
      extends: [tseslint.configs.recommendedTypeChecked],
      languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: rootDir } },
      rules: {
        // `no-undef` lo cubre el compilador.
        'no-undef': 'off',
        '@typescript-eslint/no-explicit-any': 'error',
        '@typescript-eslint/ban-ts-comment': [
          'error',
          { 'ts-expect-error': true, 'ts-ignore': true, 'ts-nocheck': true, 'ts-check': true },
        ],
        '@typescript-eslint/switch-exhaustiveness-check': [
          'error',
          { considerDefaultExhaustiveForUnions: false, requireDefaultForNonUnion: true },
        ],
        '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      },
    },
    {
      // Configuración raíz fuera de cualquier tsconfig: sin reglas con información de tipos.
      files: ['*.ts', 'Tools/**/*.ts'],
      extends: [tseslint.configs.disableTypeChecked],
      languageOptions: { parserOptions: { projectService: false } },
    },
    {
      files: ['backend/src/**/*.ts', 'frontend/src/**/*.{ts,tsx}'],
      plugins: { boundaries },
      settings: {
        'boundaries/root-path': rootDir,
        'boundaries/elements': elements,
        'boundaries/files': [
          {
            pattern: 'backend/src/modules/*/index.ts',
            category: 'module-entry',
            partialMatch: false,
          },
        ],
        'boundaries/dependency-nodes': ['import', 'export', 'dynamic-import', 'require'],
        'import/resolver': {
          typescript: {
            noWarnOnMultipleProjects: true,
            project: [`${rootDir}/backend/tsconfig.json`, `${rootDir}/frontend/tsconfig.json`],
          },
        },
      },
      rules: {
        'boundaries/dependencies': [
          'error',
          { default: 'disallow', checkAllOrigins: true, policies },
        ],
        'boundaries/no-unknown-files': 'error',
        'no-console': 'error',
        'no-restricted-globals': ['error', { name: 'console', message: 'ADR-OBS-001.' }],
        'no-restricted-properties': [
          'error',
          {
            object: 'process',
            property: 'env',
            message: 'CICD DC-07: solo shared/config y lib/config leen process.env.',
          },
        ],
        '@typescript-eslint/no-implied-eval': 'error',
      },
    },
    // ---------- Backend: de lo general a lo específico (gana el último bloque) ----------
    {
      files: ['backend/src/**/*.ts'],
      plugins: { pe },
      rules: {
        'pe/prisma-model-ownership': 'error',
        'pe/capacity-write-owner': 'error',
        'pe/no-io-in-transaction': 'error',
        'pe/tenant-wrapper': 'error',
        'pe/no-session-set': 'error',
        'pe/delete-allowlist': 'error',
        'pe/validate-request': 'error',
        'no-restricted-syntax': syntax(BACKEND, ...OUTSIDE),
        'no-restricted-imports': imports(NO_CHILD_PROCESS, NO_NODE_CONSOLE, NO_PINO, SDK),
      },
    },
    {
      files: ['backend/src/{bootstrap,jobs}/**/*.ts'],
      rules: {
        'no-restricted-syntax': syntax(BACKEND, ...OUTSIDE),
        'no-restricted-imports': imports(NO_CHILD_PROCESS, NO_NODE_CONSOLE, NO_PINO),
      },
    },
    {
      // `scheduler` es el nombre de carpeta del backlog; `schedules`, el de SAD §4.2.
      files: ['backend/src/jobs/{schedules,scheduler}/**/*.ts'],
      rules: {
        'no-restricted-syntax': syntax(BACKEND, RAW_SQL_OUTSIDE_INFRA, NEW_PRISMA, PROVIDER_URL),
      },
    },
    {
      files: ['backend/src/modules/*/**/infrastructure/**/*.ts'],
      rules: {
        'no-restricted-syntax': syntax(BACKEND, NEW_PRISMA, QUEUE_ADD),
        'no-restricted-imports': imports(NO_CHILD_PROCESS, NO_NODE_CONSOLE, NO_PINO),
      },
    },
    {
      files: ['backend/src/shared/infrastructure/**/*.ts'],
      rules: {
        'no-restricted-syntax': syntax(BACKEND, QUEUE_ADD),
        'no-restricted-imports': imports(NO_CHILD_PROCESS, NO_NODE_CONSOLE, NO_PINO),
      },
    },
    {
      files: ['backend/src/shared/infrastructure/outbox/**/*.ts'],
      rules: { 'no-restricted-syntax': syntax(BACKEND) },
    },
    {
      files: ['backend/src/shared/observability/**/*.ts'],
      rules: {
        'no-restricted-imports': imports(NO_CHILD_PROCESS, NO_NODE_CONSOLE, SDK, PERSISTENCE),
      },
    },
    {
      files: [
        'backend/src/modules/*/**/domain/**/*.ts',
        'backend/src/modules/*/**/application/**/*.ts',
        'backend/src/shared/domain/**/*.ts',
      ],
      rules: {
        'no-restricted-syntax': syntax(BACKEND, ...OUTSIDE, NO_CLOCK, ERROR_STATUS),
        'no-restricted-imports': imports(
          NO_CHILD_PROCESS,
          NO_NODE_CONSOLE,
          NO_PINO,
          SDK,
          PERSISTENCE,
          EXPRESS,
        ),
      },
    },
    {
      files: [
        'backend/src/modules/*/**/http/**/*.ts',
        'backend/src/http/**/*.ts',
        'backend/src/shared/http/**/*.ts',
      ],
      rules: {
        'no-restricted-syntax': syntax(BACKEND, ...OUTSIDE, HTTP_LOOSE_SCHEMA, ERROR_STATUS),
        'no-restricted-imports': imports(
          NO_CHILD_PROCESS,
          NO_NODE_CONSOLE,
          NO_PINO,
          SDK,
          PERSISTENCE,
        ),
      },
    },
    {
      // Manejador central de errores: único que fija estados 4xx y 5xx.
      files: ['backend/src/shared/http/error-handler.ts'],
      rules: { 'no-restricted-syntax': syntax(BACKEND, ...OUTSIDE, HTTP_LOOSE_SCHEMA) },
    },
    {
      files: ['backend/src/shared/config/**/*.ts'],
      rules: { 'no-restricted-properties': 'off' },
    },
    // ---------- Frontend ----------
    {
      files: ['frontend/src/**/*.{ts,tsx}'],
      plugins: { pe },
      languageOptions: { globals: { ...globals.browser } },
      rules: {
        'pe/api-client-server-only': 'error',
        'no-restricted-globals': ['error', 'console', 'localStorage', 'sessionStorage'],
        'no-restricted-syntax': syntax(SRC_COMMON, BROWSER, NO_RAW_HTML),
        'no-restricted-imports': imports(NO_CHILD_PROCESS, NO_NODE_CONSOLE, NO_PINO, PERSISTENCE, {
          regex: '(^|/)backend/|^(bullmq|ioredis|redis|nodemailer|@sendgrid|cloudinary)(/|$)',
          message: 'ADR-ARCH-008 R1: el frontend no accede al backend ni a su infraestructura.',
        }),
      },
    },
    {
      files: ['frontend/src/components/ui/safe-html.tsx'],
      rules: { 'no-restricted-syntax': syntax(SRC_COMMON, BROWSER) },
    },
    {
      files: ['frontend/src/lib/observability/**/*.ts'],
      rules: {
        'no-restricted-imports': imports(NO_CHILD_PROCESS, NO_NODE_CONSOLE, PERSISTENCE, SDK),
      },
    },
    {
      files: ['frontend/src/lib/config/**/*.ts', 'frontend/src/instrumentation.ts'],
      rules: { 'no-restricted-properties': 'off' },
    },
    // ---------- Pruebas ----------
    {
      files: ['backend/src/tests/**/*.ts'],
      plugins: { vitest },
      rules: {
        'boundaries/dependencies': 'off',
        'no-restricted-properties': 'off',
        'no-restricted-syntax': syntax(TEST_SABOTAGE),
        'no-restricted-imports': imports(),
        'vitest/no-disabled-tests': 'error',
        'vitest/no-focused-tests': 'error',
        'vitest/expect-expect': 'error',
        // Admite el mensaje como segundo argumento de `expect`.
        'vitest/valid-expect': ['error', { maxArgs: 2 }],
        'pe/prisma-model-ownership': 'off',
      },
    },
    {
      files: ['backend/src/tests/e2e/**/*.ts'],
      rules: {
        'vitest/valid-expect': 'off',
        'vitest/expect-expect': 'off',
        'vitest/no-disabled-tests': 'off',
        'vitest/no-focused-tests': 'off',
      },
    },
    {
      // ADR-TEST-002 R2: sin simular datos ni colas en las suites contra servicios reales.
      files: ['backend/src/tests/{integration,concurrency,multi-tenant}/**/*.ts'],
      rules: {
        'no-restricted-syntax': syntax(TEST_SABOTAGE, [
          sel(
            "CallExpression[callee.object.name='vi'][callee.property.name=/^(mock|doMock|spyOn|mocked)$/]",
            'ADR-TEST-002 R2: usa PostgreSQL y Redis reales.',
          ),
        ]),
      },
    },
  );
}

export default createConfig(import.meta.dirname);
