# AGENTS.md — contrato del repositorio ProveeEventos

Léelo entero antes de tocar código. Ruta protegida: cambiarlo exige aprobación humana.

## 1. Cómo trabajar

1. Tu única fuente de trabajo es tu Issue (`ProveeEventos_ImplBacklog.md` §4). Escribe **solo** en sus `allowed_paths`; nunca en sus `forbidden_paths`.
2. Rama desde `main`: `feat/ISS-CODE-NNN-slug` o `test/ISS-TEST-NNN-slug`. Un PR cohesivo por Issue.
3. **La Capa 2 de ADRs no está activada** (no hay `.github/`): nada verifica automáticamente rutas, supresiones ni documentos. Una persona revisa e integra **todos** los PR (backlog §4.8).
4. Un comportamiento sin fuente o dos fuentes que se contradicen: detén esa parte y repórtalo (`ADR-GOV-004`). No edites documentos normativos para resolverlo.

## 2. Arquitectura y mapa de carpetas

Monolito modular: API Express y worker BullMQ (`backend`), web Next.js con BFF (`frontend`), PostgreSQL como única autoridad, Redis solo para colas, caché y límites. Node.js 26, npm workspaces, TypeScript 6.0 estricto, Prisma 7.10.1, Tailwind 3.4.

```text
backend/
  prisma.config.ts · vitest.config.ts · tsconfig*.json · Dockerfile
  src/
    bootstrap/            app.ts, server.ts, worker.ts, listen.ts  (container.ts: ISS-CODE-006)
    http/                 composición HTTP transversal
    shared/{domain,application,infrastructure,http,errors,security,observability,config}
    modules/<módulo>/[<función>/]{domain,application,infrastructure,http}/ + modules/<módulo>/index.ts
    jobs/{queues,processors,schedules}
    prisma/{schema.prisma,bootstrap/,migrations/,rls/,seed/{reference,synthetic}}
    tests/{unit,integration,contract,multi-tenant,concurrency,security,architecture,infra,e2e,load,support,factories,fixtures}
frontend/
  tailwind.config.ts · next.config.ts
  src/{app,features,components,lib}   app/tokens.css y lib/design/tokens.tokens.json (UXUI §2.8)
Tools/{eslint-plugin-pe,adr-guard,dev-stubs}   scripts/{db,dev}   docker/   docker-compose.yml
```

Módulos (exactamente estos 12): `identity-access`, `organizations`, `provider-catalog`, `taxonomy-templates`, `event-management`, `quotation`, `availability-booking`, `rfq-offers`, `assisted-response`, `messaging-notifications`, `reviews`, `administration-audit`.

Las pruebas de contrato (`TC-API`) viven en `tests/contract/`, no en `tests/api/`.

## 3. Comandos

Primer arranque:

```bash
npm ci
npm run env:init          # genera .env con secretos sintéticos; nunca lo versiones
npm run dev:up            # web :3000 · API :4000 · Mailpit :8025 · dobles :4010
```

**Obligatorios antes de abrir un PR** (todos en código 0):

```bash
npm run verify:adrs       # formato, tipos, lint, dependencias, unit + arquitectura con cobertura
npm run verify:env        # esquemas de entorno frente a .env.example
npm run build
npm run test:unit
npm run dc -- --profile dev up -d --build --wait      # docker compose con los dos --env-file
```

Además, las suites de tu alcance: `test:int`, `test:api`, `test:mt`, `test:conc`, `test:sec`, `test:arch` (usan Docker mediante Testcontainers), `test:infra` y `test:e2e` (requieren el stack levantado; `npx playwright install chromium webkit` la primera vez que una prueba use navegador).

Atajos: `typecheck` = `verify:types` · `lint` = `verify:lint` · `lint:arch` = `verify:deps` · `dev` = `dev:watch`.
Base de datos: `db:migrate`, `db:migrate:create -- <nombre>`, `db:seed`, `db:psql`, `dev:reset` (borra volúmenes).
Si `3000`, `4000`, `4010` u `8025` están ocupados, exporta `WEB_PORT`, `API_PORT`, `DEV_STUBS_PORT` o `MAILPIT_UI_PORT` (y `APP_BASE_URL` si cambias el de la web).

## 4. Reglas inquebrantables

- **Sin supresiones:** `eslint-disable`, `/* eslint … */`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `prettier-ignore`, `v8|c8|istanbul ignore`, `gitleaks:allow`.
- **Sin pruebas debilitadas:** nada de `.skip`, `.only`, `.todo`, `.fails`, `.skipIf`, `.runIf`, `fixme`, `xit`, aserciones triviales, reintentos ni `passWithNoTests`. Borrar pruebas exige aprobación humana.
- **Sin mocks prohibidos:** en `integration`, `concurrency` y `multi-tenant` no se simula Prisma, `pg`, `ioredis`, BullMQ ni repositorios propios. Los externos se simulan solo tras sus puertos (MSW).
- **Rutas protegidas** (aprobación humana): `ProveeEventos_*.md`, `ProveeEventos_API_Spec.yaml`, `Decisiones.md`, `Trazabilidad.md`, `Glosario.md`, `proveeeventos.{prisma,sql}`, `docs/**`; `eslint.config.mjs`, `.dependency-cruiser.cjs`, `tsconfig*.json`, `vitest.config.ts`, `playwright.config.ts`, `.prettierrc.json`, `.prettierignore`, `**/package.json`, `package-lock.json`, `.nvmrc`, `.npmrc`, `.gitignore`, `prisma.config.ts`, `Tools/**`, `scripts/**`, `docker/**`, `docker-compose.yml`, `backend/src/tests/architecture/**`, `backend/src/prisma/{bootstrap,rls}/**`, `AGENTS.md`, `CLAUDE.md`, `.claude/**`, `.agents/**`, `skills-lock.json`.
- **Migraciones integradas: inmutables, sin excepción.**
- **Dependencias:** no añadas, quites ni subas de versión mayor sin aprobación (`ADR-STACK-003`). Las de la Etapa 1 ya están declaradas.
- Sin secretos reales ni `.env` en Git. Sin variables `NEXT_PUBLIC_*`.

## 5. Convenciones que el linter exige

| Tema | Regla |
|---|---|
| Imports | Backend ESM: rutas relativas con extensión `.js`. Entre módulos, solo `modules/<otro>/index.js` y según la matriz de `.dependency-cruiser.cjs` |
| Capas | `domain` solo `domain` propio, `shared/domain` y `decimal.js`; `application` sin Express, Prisma, Redis ni SDK; `http` sin `infrastructure`; todo `.ts` de un módulo vive en una capa o es `index.ts` |
| Cableado | Solo `bootstrap/container.ts` importa implementaciones de `infrastructure` |
| Prisma | Solo en la `infrastructure` del módulo escritor (`Tools/eslint-plugin-pe/table-ownership.json`); modelos de tenant, con el cliente transaccional llamado `tx`; un solo `new PrismaClient`, en `shared/infrastructure` |
| Capacidad | Solo `availability-booking/**/infrastructure/{provider,package}-daily-capacity.repository.ts` escriben capacidad o `consumed` |
| Transacciones | Sin `fetch`, puertos externos, Redis ni `queue.add` dentro; los efectos van por outbox |
| Colas | `queue.add` solo en `shared/infrastructure/outbox` y `jobs/{schedules,scheduler}` |
| Borrado | `delete*` y `DELETE FROM` solo en los modelos de `delete-allowlist.json`; la retención va en `infrastructure/<nombre>.retention.ts` (aprobación humana) |
| SQL | Solo `$queryRaw`/`$executeRaw` como plantilla etiquetada, en `infrastructure` |
| HTTP | `req.body|query|params` solo en `shared/http/validate-request.ts`; estados 4xx/5xx solo en `shared/errors/**` o `shared/http/error-handler.ts`; Zod estricto |
| Entorno | `process.env` solo en `shared/config` y `frontend/src/lib/config` |
| Logs | Pino vía `shared/observability`; sin `console` ni `process.stdout`; nunca registres `req`, cabeceras ni cuerpos |
| Tiempo y dinero | En `domain`/`application` sin `new Date()` ni `Date.now()`; sin offsets fijos; los importes nunca pasan a `number` |
| Frontend | `'use client'` no importa `lib/api`; sin `localStorage`, `sessionStorage`, `document.cookie`; HTML crudo solo en `components/ui/safe-html.tsx`; colores solo en `tokens.css` |

Una regla que te parezca errónea se reporta; no se esquiva.

## 6. Fuentes

- `ProveeEventos_ImplBacklog.md` — Issues, rutas, olas y protocolo de agentes.
- `ProveeEventos_ADRs.md` — reglas normativas y capas de cumplimiento.
- `ProveeEventos_TESTs.md` — suites, casos `TC-*` y umbrales.
- `ProveeEventos_CICD.md` — entorno, Docker, migraciones y CI.
- `ProveeEventos_UXUI.md` — pantallas y sistema de diseño.
- Jerarquía ante contradicciones: PRD → SRS → SAD → DDD → `ProveeEventos_API_Spec.yaml` → `Decisiones.md`; el TDD manda en persistencia dentro de eso.
- `ProveeEventos_Day0_Report.md` — qué dejó hecho el Día 0 y qué falta en cada Issue de plataforma.
