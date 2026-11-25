# ProveeEventos — Reporte de Bootstrap "Día 0" (`ProveeEventos_Day0_Report.md`)

## Cabecera y Metadatos del Bootstrap

| Campo | Valor |
|:---|:---|
| Fecha | 2026-11-25 |
| Versión de Node.js | `26.x` (`.nvmrc` = `26`). Equipo: 26.8.1 · Imagen fijada: `node:26.13.1-bookworm-slim` por digest |
| Gestor de paquetes | npm 11.19.0, workspaces `backend` y `frontend`, un `package-lock.json` |
| Estado de Capa 1 | `IMPLEMENTADA` (39 ADRs con Capa 1: 32 completos, 7 parciales porque el código que verifican aún no existe; ver Sección 2) |
| Estado de Capa 2 | `OMITIDA POR DECISIÓN DEL USUARIO` |
| Estado general | `LISTO PARA AGENTES`, **después de las condiciones previas de la Sección 7.2** (nada está confirmado ni publicado en Git) |

Plan de ejecución: `Plans/Plan0001_Day0_Bootstrap.md`.

---

## Sección 1 — Inventario de Archivos y Estructura Creada

### 1.1 Árbol

```text
.
├── AGENTS.md  package.json  package-lock.json  tsconfig.base.json
├── .nvmrc  .npmrc  .editorconfig  .gitignore*  .dockerignore  .env.example
├── eslint.config.mjs  .dependency-cruiser.cjs  .prettierrc.json  .prettierignore
├── playwright.config.ts  docker-compose.yml  CLAUDE.md*
├── backend/
│   ├── Dockerfile  package.json  prisma.config.ts  vitest.config.ts  tsconfig.json  tsconfig.build.json
│   └── src/
│       ├── bootstrap/{app,listen,server,worker}.ts
│       ├── http/
│       ├── shared/{config/env.ts, http/health.ts, observability/{logger,correlation}.ts,
│       │          domain/, application/, infrastructure/, errors/, security/}
│       ├── modules/<12 módulos>/{domain,application,infrastructure,http}/
│       ├── jobs/{queues,processors,schedules}/
│       ├── prisma/{schema.prisma, bootstrap/00_extensiones_roles.sql, migrations/, rls/, seed/}
│       └── tests/{unit,integration,contract,multi-tenant,concurrency,security,
│                  architecture,infra,e2e,load,support,factories,fixtures}/
├── frontend/
│   ├── Dockerfile  package.json  next.config.ts  tailwind.config.ts  postcss.config.mjs  tsconfig.json
│   └── src/{app/{layout.tsx,globals.css,tokens.css,health/live/route.ts}, features/, components/,
│            lib/{config,observability,design,types}/, instrumentation.ts}
├── Tools/{eslint-plugin-pe/, adr-guard/{banned-packages.json,gitleaks.toml}, dev-stubs/}
├── scripts/{dev/gen-env.sh, db/{bootstrap,apply-rls}.sh}
└── docker/{images.env, pgbouncer/{pgbouncer.ini,start.sh}}
```

`*` archivo que ya existía y se modificó. Las carpetas vacías llevan `.gitkeep`.

### 1.2 Archivos y propósito

| Archivo | Propósito | Origen |
|:---|:---|:---|
| `package.json` (raíz y workspaces) | Scripts, dependencias de la Etapa 1, `overrides` | ADR §6.1; CICD §5.7, §13.2; TESTs §15.3 |
| `tsconfig*.json` | TypeScript 6.0 estricto; `tsconfig.build.json` excluye pruebas | ADR-STACK-002 |
| `eslint.config.mjs`, `Tools/eslint-plugin-pe/` | Reglas de Capa 1 y 9 reglas propias con sus mapas | ADR §6.1 |
| `.dependency-cruiser.cjs` | Capas, matriz de módulos y alcanzabilidad | ADR-ARCH-001..008 |
| `Tools/adr-guard/banned-packages.json` | Paquetes vetados | ADR-ARCH-010, ADR-STACK-001 |
| `Tools/adr-guard/gitleaks.toml` | Escaneo local de secretos | CICD §5.5, literal |
| `docker-compose.yml`, Dockerfiles, `.dockerignore`, `docker/` | Stack local | CICD §5, literal salvo D-01 |
| `.env.example`, `scripts/dev/gen-env.sh` | Catálogo de variables y secretos sintéticos | CICD §3.3, §4.1, literal |
| `scripts/db/*.sh` | Roles, contraseñas y RLS condicionada | CICD §5.5, literal |
| `backend/src/shared/config/env.ts`, `frontend/src/lib/config/env.ts` | Validación *fail-fast* (salida 78), reglas ENV-01..08 | CICD §3.4 |
| `shared/observability/*`, `shared/http/health.ts`, `bootstrap/*` | Logger Pino con redacción, `correlationId`, `/health/live` y `/health/ready` | ADR-OBS-001/002; SAD §10.8 |
| `backend/prisma.config.ts`, `schema.prisma` | Prisma 7.10.1 con `generator` y `datasource`, sin modelos | ADR-STACK-004 |
| `prisma/bootstrap/00_extensiones_roles.sql` | Bloques `SQL-001..008` del anexo, sin cambios | `proveeeventos.sql` |
| `prisma/seed/index.ts` | Entrada de semillas: valida el entorno y no siembra nada | CICD §6.5 |
| `frontend/src/app/tokens.css`, `lib/design/tokens.tokens.json`, `tailwind.config.ts` | Tokens de diseño copiados literalmente | UXUI §2.8, D-07 |
| `Tools/dev-stubs/server.ts` | Solo `/health/live`; se niega a arrancar fuera de `development`/`test` | CICD §5.6 (parcial) |
| `backend/vitest.config.ts`, `playwright.config.ts`, `tests/support/` | Harness | TESTs §2–§4, §15 |
| `AGENTS.md` | Contrato para agentes | Prompt, Paso 6 |
| `CLAUDE.md` | Deja de decir que no hay código ni Git y remite a `AGENTS.md` | Cambio de este Día 0 |

No se creó ninguna lógica de negocio, endpoint del contrato, pantalla, modelo Prisma ni migración.

---

## Sección 2 — Capa 1 de ADRs Implementada (Node.js Toolchain)

`npm run verify:adrs` = `verify:format` → `verify:types` → `verify:lint` → `verify:deps` → `verify:arch` (literal de ADR §6.1).

Cada regla propia y cada regla de dependencias tiene un fixture que falla; el conjunto válido pasa sin hallazgos. Las suites fallan si analizan cero archivos. `dependency-cruiser` tiene un árbol inválido por regla (3 de las 11 reglas de matriz se demuestran; la prueba exige que las 11 existan). Algunos selectores genéricos (`SERIALIZABLE` en plantillas, `NOWAIT`, `Prisma.raw`, acceso por corchetes a `$…`) comparten fixture o no tienen uno propio.

| ADR | Estado | Regla configurada | Pendiente o nota |
|:---|:---|:---|:---|
| `ADR-ARCH-001` | Implementada | `modules.spec.ts` (12 módulos, capas, solo `listen.ts` escucha); `no-http-between-modules`, `jobs-no-prisma` | — |
| `ADR-ARCH-002` | Implementada | `boundaries/dependencies`; `layer-domain-pure`, `layer-shared-domain-pure`, `layer-application-ports`, `layer-http-no-infra`, `wiring-only-bootstrap`; `no-restricted-imports` por capa | — |
| `ADR-ARCH-003` | Implementada | 11 reglas `matrix-*`, `no-circular`, `cross-module-only-index`, `outside-modules-only-index`; categoría `module-entry` en `boundaries` | Ver P-02 |
| `ADR-ARCH-004` | Implementada | `shared-no-modules` | R2–R4 son de Capa 3 |
| `ADR-ARCH-005` | Implementada | `pe/prisma-model-ownership` + `table-ownership.json` (72 modelos, probado contra el diseño) | — |
| `ADR-ARCH-006` | Parcial | `no-restricted-imports` de SDK por carpeta; selector de URL de proveedores | Prueba puerto + adaptador + doble: sin puertos aún (`ISS-CODE-007`, `017`) |
| `ADR-ARCH-007` | Implementada | `layer-http-no-infra`, `http-no-policies-or-repositories` (por nombre `*repository*` / `*policy*`) | R1, R3, R4: Capa 3 |
| `ADR-ARCH-008` | Implementada | `frontend-no-backend`, `pe/api-client-server-only`, `client-graph.spec.ts` (grafo transitivo) | R3, R5, R6: Capa 3 |
| `ADR-ARCH-010` | Implementada | `no-restricted-imports` desde `banned-packages.json`; `stack.spec.ts` revisa lo declarado | — |
| `ADR-STACK-001` | Implementada | `stack.spec.ts`; `no-restricted-imports`; `.nvmrc`, `engines` | — |
| `ADR-STACK-002` | Implementada | `tsc --noEmit`, `no-explicit-any`, `no-unsafe-*`, `ban-ts-comment`; `typescript-and-prisma.spec.ts`; sin JavaScript en `src` | Excepción: guiones k6 en `tests/load` |
| `ADR-STACK-004` | Implementada | Prueba de versiones y esquema; `new PrismaClient` solo en `shared/infrastructure` | «Uno por proceso» se completa en `ISS-CODE-004` |
| `ADR-DATA-001` | Implementada | `redis-restricted`; `no-restricted-imports` en `domain` y `application` | — |
| `ADR-DATA-002` | Implementada | `pe/capacity-write-owner` (modelos, campo `consumed`, SQL `_daily_capacity`) | Fija dos nombres de repositorio (`AGENTS.md` §5) |
| `ADR-DATA-003` | Implementada | Selectores `SERIALIZABLE`, `Serializable`, `NOWAIT` | — |
| `ADR-DATA-005` | Implementada | `pe/no-io-in-transaction` (llamadas directas en el callback) | Llamadas indirectas: Capa 3 |
| `ADR-DATA-006` | Implementada | `mail-only-from-worker` (alcanzabilidad desde `server.ts`); selector `queue.add` | — |
| `ADR-DATA-007` | Parcial | — | Prueba del catálogo de 48 eventos: no hay registro (`ISS-CODE-006`) |
| `ADR-DATA-008` | Implementada | `pe/tenant-wrapper` (39 modelos, probado contra el anexo), `pe/no-session-set` | Extensión de Prisma: `ISS-CODE-004` |
| `ADR-DATA-010` | Implementada | Selectores `*Unsafe`, `Prisma.raw`, no etiquetado, corchetes y carpeta | — |
| `ADR-DATA-012` | Implementada | Selectores de reloj en `domain`/`application` y de offsets fijos | — |
| `ADR-DATA-013` | Implementada | Selectores de conversión de importes a `number` | — |
| `ADR-DATA-016` | Implementada | `pe/prisma-model-ownership` (`auditLog` solo con `createMany`) | — |
| `ADR-DATA-017` | Implementada | `pe/delete-allowlist` (Prisma y `DELETE FROM`) | Excepción: `infrastructure/*.retention.ts` |
| `ADR-DATA-019` | Parcial | `switch-exhaustiveness-check` | Prueba de pares de transición: no hay máquinas (Issues de módulo) |
| `ADR-API-002` | Implementada | `pe/validate-request`; veto de `z.any`, `z.unknown`, `passthrough` en `http` | El middleware lo crea `ISS-CODE-006` |
| `ADR-API-003` | Parcial | Selector `res.status(≥400)` fuera del manejador | Prueba `ErrorCode` → estado: `ISS-CODE-006` |
| `ADR-SEC-001` | Parcial | Veto de `bcrypt`/`argon2`, `jwt.decode`, `decodeJwt` | Rutas públicas = `security: []`: `ISS-CODE-006`/`007` |
| `ADR-SEC-002` | Implementada | Veto de `localStorage`, `sessionStorage`, `document.cookie`, `cookie-parser` | — |
| `ADR-SEC-004` | Implementada | Selectores `:token` en rutas y `Math.random`; cabeceras de `/r` e `/invitacion` probadas | Cabeceras de la API: `ISS-CODE-016` |
| `ADR-SEC-006` | Parcial | — | Prueba de serializadores públicos: no hay esquemas (`ISS-CODE-010`, `013`) |
| `ADR-SEC-007` | Parcial | `dangerouslySetInnerHTML`, `eval`, `Function`, eval implícito, `child_process`; prueba de `frame-ancestors` | `script-src` con *nonce* requiere el middleware (`ISS-CODE-007`) |
| `ADR-SEC-010` | Implementada | `matrix-assisted-response`; propiedad de tablas | — |
| `ADR-OBS-001` | Implementada | `no-console`, `no-restricted-globals`, `process.std*`, `pino-only-observability`; prueba de `correlationId` en petición | Logger de jobs: `ISS-CODE-006` |
| `ADR-OBS-002` | Implementada | Prueba de redacción; selectores sobre `req`, cabeceras y cuerpo | Sentry sin integrar |
| `ADR-TEST-001` | Implementada | `tests/architecture` con fixtures válidos e inválidos | — |
| `ADR-TEST-002` | Implementada | Veto de `vi.mock`, `doMock`, `spyOn` en `integration`, `concurrency`, `multi-tenant` | Más estricto: veta todo `vi.mock` allí |
| `ADR-TEST-006` | Implementada | `@vitest/eslint-plugin`, selectores AS-01, `allowOnly:false`, `passWithNoTests:false`, `retry:0`, umbrales | R4–R5: Capa 2 |
| `ADR-GOV-003` | Implementada | `noInlineConfig`, `ban-ts-comment`, `--no-inline-config`, `pe/no-suppression-comments` | R3–R5 (lista de excepciones): Capa 2 |

No se añadió `@eslint-community/eslint-comments`: ADR §6.1 fija `noInlineConfig`, y la regla propia `pe/no-suppression-comments` cubre las directivas restantes.

---

## Sección 3 — Entorno Local Docker y Docker Compose

18 servicios; redes `edge` y `data` (interna); volúmenes `pgdata`, `redisdata`, `documents`. Las 11 imágenes de `docker/images.env` coinciden con el registro (etiqueta y digest).

| Servicio | Perfil | Puerto en `127.0.0.1` | Estado verificado |
|:---|:---|:---|:---|
| `postgres`, `redis`, `pgbouncer` | siempre | ninguno | Sanos |
| `db-bootstrap`, `migrate`, `db-rls` | siempre, una vez | — | Salida 0 (`migrate`: sin migraciones; `db-rls`: omitido) |
| `seed` | `dev`, `test` | — | Salida 0 |
| `mailpit` | `dev`, `test` | **8025** (interfaz web: `http://localhost:8025`) | Sano |
| `dev-stubs` | `dev`, `test` | 4010 | Sano (solo salud) |
| `api`, `worker`, `web` | `dev` | 4000, —, 3000 | Sanos |
| `api-test`, `worker-test`, `web-test` | `test` | 4000, —, 3000 | Sanos |
| `psql`, `db-authoring`, `secrets-scan` | `tools` | — | `psql` y `secrets-scan` ejecutados; `db-authoring` sin ejecutar |

| Acción | Comando |
|:---|:---|
| Primer arranque | `npm ci && npm run env:init && npm run dev:up` |
| Recarga en caliente | `npm run dev:watch` (alias `npm run dev`) |
| Estado y registros | `npm run dev:ps` · `npm run dev:logs` |
| Detener | `npm run dev:down` |
| Reiniciar desde cero (borra volúmenes) | `npm run dev:reset` |
| Perfil `test` | `npm run test:stack:up` · `npm run test:stack:down` |
| Base de datos | `npm run db:migrate` · `db:seed` · `db:psql` |

Aplicación en `http://localhost:3000` (solo responde `/health/live`), API en `http://localhost:4000` (solo salud).

**Puertos en este equipo:** 3000 y 8025 los ocupa otro proyecto en ejecución. La verificación usó `WEB_PORT=3300`, `MAILPIT_UI_PORT=8125`, `APP_BASE_URL=http://localhost:3300` y proyectos Compose aislados, retirados al terminar. Quedan en caché las imágenes `proveeeventos/*:local`.

---

## Sección 4 — Harness de Pruebas y Contrato `AGENTS.md`

- **Vitest 5** con 8 proyectos (`unit`, `architecture`, `integration`, `contract`, `concurrency`, `multi-tenant`, `security`, `infra`), `allowOnly:false`, `passWithNoTests:false`, `retry:0` y los umbrales de TESTs §4.1.
- **Testcontainers** con PostgreSQL 16 y 15 de las imágenes fijadas; `tests/support/postgres.ts` aplica la migración 00 y conecta con roles `pe_*`.
- **Supertest** para HTTP; **Playwright** con `retries:0`, proyectos `chromium` y `webkit`. MSW y `openapi-response-validator` quedan instalados y sin uso.
- **Pruebas de contrato en `tests/contract/`**, no en `tests/api/` (CICD `DISC-11`).
- **Humo:** al menos una prueba verde por suite (`day0-*`), todas sobre comportamiento real. `tests/unit/config/env.matrix.spec.ts` implementa `DC-08`.
- **Cobertura** (`unit` + `architecture`): líneas 100 %, ramas ≈ 94 % sobre el código existente.
- **Carga:** `tests/load/` vacío y k6 sin instalar; `test:load*` fallan hasta `ISS-TEST-006`/`ISS-CODE-050`.
- **`AGENTS.md`** creado en la raíz: forma de trabajo, mapa de carpetas, comandos previos al PR, reglas inquebrantables, convenciones que exige el linter y documentos fuente.

---

## Sección 5 — Estado de Capa 2 de ADRs (Opcional)

**Omitida intencionalmente por decisión del usuario** (2026-11-25). No existe `.github/` y no se configuró nada en GitHub.

Consecuencia mientras siga omitida: **nada verifica automáticamente** las rutas protegidas, los documentos normativos, la inmutabilidad de migraciones, la cobertura frente a `main`, el borrado de pruebas, las dependencias nuevas ni los secretos de un PR. `verify:adrs` es local y quien codifica podría modificar sus reglas: una persona debe revisar cada diff.

**Para habilitarla:** tomar `ISS-CODE-005` y su par `ISS-TEST-005`: workflows `ci-quality-and-tests.yml`, `adr-guard.yml`, `ai-reviewer.yml` (CICD §7.3–§7.5), `Tools/adr-guard/cli.ts`, `scripts/ci/`, `.github/adr-guard/{approvers.yml,suppressions.yml,ruleset.json}`, CODEOWNERS y plantilla de PR; después, una persona configura Environments, secretos y el Ruleset (§7.6, backlog §4.8). Requiere resolver antes `RR-01` de `ProveeEventos_CrossAudit_Report.md`.

---

## Sección 6 — Evidencia de Verificación en Vivo

### 6.1 Corrida completa desde árbol limpio (sin `node_modules` ni salidas de compilación)

| Comando | Salida | Resultado |
|:---|:---:|:---|
| `npm ci` | 0 | 807 paquetes |
| `npm audit --omit=dev --audit-level=high` | 0 | 0 vulnerabilidades de ejecución |
| `npm run verify:adrs` | 0 | Sin violaciones; 14 archivos, 161 pruebas |
| `npm run typecheck` | 0 | Sin errores |
| `npm run lint` | 0 | 0 errores, 0 avisos |
| `npm run lint:arch` | 0 | 64 módulos, 0 violaciones |
| `npm run build` | 0 | Backend y Next.js compilan |
| `npm run verify:env` | 0 | 4 pruebas |
| `npm run test:unit` | 0 | 46 pruebas |
| `npm run test:arch` | 0 | 115 pruebas |
| `npm run test:api` | 0 | 2 pruebas |
| `npm run test:sec` | 0 | 2 pruebas |
| `npm run test:int` | 0 | 4 pruebas (PostgreSQL 16 y 15) |
| `npm run test:mt` | 0 | 5 pruebas |
| `npm run test:conc` | 0 | 1 prueba (20 conexiones) |
| `npm run test:infra` | 0 | 18 servicios declarados |
| `prisma validate` | 0 | Esquema válido |
| `docker compose config` (base, `dev`, `test`, `tools`) | 0 | Los 4 perfiles |
| `npm run dev:up` | 0 | Todos sanos o `exited (0)` |
| `npm run db:migrate` · `db:migrate:status` · `db:seed` | 0 | Sin migraciones pendientes |
| Salud web, API, dobles y Mailpit | 0 | HTTP 200 |
| `npm run test:e2e` (`dev` y `test`) | 0 | 4 pruebas en cada perfil, sin lanzar navegador |
| `npm run dev:reset` | 0 | Volúmenes retirados |
| `npm run test:stack:up` · `test:stack:down` | 0 | Imágenes de ejecución sanas |
| `npm run secrets:scan` (árbol sin salidas de compilación) | 0 | Sin hallazgos |
| `Tools/check_openapi.py` · `Tools/check_package.py` | 0 | Paquete coherente |

Tras el último ajuste (dos reglas de ESLint) se repitieron `verify:adrs`, `typecheck`, `build`, `test:unit`, `secrets:scan` y `check_package.py`, todos en 0.

### 6.2 Criterios de aceptación locales (CICD §13.3) y comprobaciones adicionales

| Criterio | Resultado |
|:---|:---|
| AC-01 `env:init` | `.env` con modo 600, sin marcadores |
| AC-02, AC-03, AC-04 | Compose válido; arranque desde cero y repetido en 0 |
| AC-05 *fail-fast* | `api`, `worker`, `seed` y `web` (imagen de ejecución) salen con **78** sin mostrar valores. `web` en modo `dev` registra el error pero **sale con 0** (D-06) |
| AC-06 imágenes | Usuario `node`; ningún secreto de `.env` en el historial de las imágenes revisadas |
| AC-07 pooler | `pe_api` por PgBouncer: `statement_timeout = 5s`, sin `CREATE TABLE` |
| AC-08 aislamiento | `web` no resuelve `postgres` ni `redis` |
| AC-09 RLS | Con `APP_ENV=production`, `db-rls` sale con 78. No se aplicó `20_rls` (no existe aún) |
| Dockerfiles | `buildx --check` sin avisos; `hadolint` sin errores (aviso `DL3008` e informativos `DL3066`) |
| Apagado | `api` y `worker` terminan con 0 ante `SIGTERM` |
| AC-12 perfil `test` | Parcial: stack sano; falta el *smoke* E2E |
| AC-17 secretos | `secrets:scan` en 0 sobre árbol sin compilar; `.env` ignorado por Git |
| AC-10, AC-11, AC-13..AC-16 | No aplicables en Día 0 (migraciones, flujo de correo, *rollback*, Capa 2) |

### 6.3 Fallos encontrados y corregidos durante la verificación

1. `dependency-cruiser` excluía cualquier `dist/`, incluidos los paquetes de `node_modules`: dos reglas no detectaban nada. Lo destaparon los fixtures.
2. `npm audit` señalaba `nodemailer`, `postcss` (dentro de Next) y `effect` (dentro de Prisma).
3. `npm run dev:up` falló en la segunda corrida: `web` respondía 404 por límite de observadores del equipo (D-01).
4. Las reglas bloqueaban `jobs/scheduler/` y el borrado del job de retención.

### 6.4 No verificado

`dev:watch`, `db:migrate:create`, pruebas en navegador (no se instalaron Chromium ni WebKit), `test:load*`, PostgreSQL 15 en `mt` y `conc`, y todo lo que dependa de GitHub. `test:e2e:smoke` **falla (salida 1, sin pruebas)** hasta que existan los escenarios de `ISS-TEST-009`.

---

## Sección 7 — Checklist de Arranque para Agentes Codificadores

### 7.1 Confirmación binaria

| Comprobación | ¿Listo? |
|:---|:---:|
| Estructura de carpetas coherente con SAD y `allowed_paths` (salvo P-03) | Sí |
| `package.json`, lockfile y scripts | Sí |
| Capa 1 ejecutable con un solo comando y en verde | Sí |
| Docker Compose levanta el stack sano | Sí |
| Harness con una prueba verde por suite (salvo carga y *smoke* E2E) | Sí |
| `AGENTS.md` | Sí |
| Capa 2 | **No** (omitida) |
| Código confirmado y publicado para que los agentes lo clonen | **No** |
| Issues materializados y ajustados a lo que ya hizo el Día 0 | **No** |

**Veredicto:** la plataforma está lista. Antes de lanzar los agentes de `ProveeEventos_SpecialAgent.md` faltan los pasos de 7.2.

### 7.2 Condiciones previas (requieren a una persona)

1. **Revisar, confirmar y publicar** el Día 0. No hice ningún *commit* ni *push*.
2. **Aprobar las dependencias** declaradas (`ADR-STACK-003 R3`): las de `package.json`, `backend/package.json` y `frontend/package.json`, y los `overrides`.
3. **Ajustar los Issues de plataforma al materializarlos**, para que ningún agente rehaga lo hecho:

| Issue | Hecho en el Día 0 | Falta |
|:---|:---|:---|
| `ISS-CODE-001` / `TEST-001` | Casi todo el código; `stack.spec.ts` cubre parte de las pruebas | Revisión; pruebas de `unit/config/vitest-config*` |
| `ISS-CODE-002` / `TEST-002` | Compose, Dockerfiles, PgBouncer | OIDC, Cloudinary y webhook en `dev-stubs`; smoke en vivo |
| `ISS-CODE-003` / `TEST-003` | Esquemas, ENV-01..08, `DC-08` | `env.spec.ts` propio del par |
| `ISS-CODE-004` / `TEST-004` | `prisma.config.ts`, esquema vacío, SQL 00, scripts, arnés mínimo | Modelos, migraciones 01–11 y 20, extensión de tenant, `check-*.ts` |
| `ISS-CODE-005` / `TEST-005` | `eslint-plugin-pe`, `banned-packages.json`, `gitleaks.toml` | Toda la Capa 2 |
| `ISS-CODE-006` / `TEST-006` | Arranque, salud, logger, `correlationId`, tokens CSS | `problem+json`, outbox, BullMQ, idempotencia, comprobaciones reales de `/health/ready`, línea base de pruebas |

4. **Resolver las contradicciones P-01 a P-03** antes de la Wave-1.

### 7.3 Pendientes y decisiones

| ID | Pendiente | Efecto | Propuesta |
|:---|:---|:---|:---|
| P-01 | El umbral global de cobertura (80 % líneas, 75 % ramas) se mide solo con `unit` + `architecture`, pero `http` e `infrastructure` se prueban con integración (TESTs §4.1) | Es previsible que `verify:adrs` falle en cuanto se integre código de infraestructura | Decidir: excluir esas capas del umbral global o medirlo con todas las suites |
| P-02 | `ADR-ARCH-003 R2` limita `index.ts` a comandos, consultas, tipos y errores; el backlog (`ISS-CODE-006`) quiere que exporte rutas, consumidores y jobs | El linter permite exportar desde `index.ts` lo de `http` y `application`, no lo de `infrastructure` | Enmendar el ADR o el Issue |
| P-03 | El backlog asigna `frontend/src/tests-a11y/**` y `frontend/src/tests/**`; `ADR-ARCH-008 R4` solo admite `app`, `features`, `components`, `lib`, y ningún runner mira esas rutas | `ISS-CODE-049` y `ISS-TEST-059` no podrán ejecutar sus pruebas | Moverlas a `backend/src/tests/e2e/**` |
| P-04 | `ProveeEventos_API_Spec.yaml:3470` repite la clave `description` en `taxRate` | Los analizadores YAML estrictos rechazan el contrato; `check_openapi.py` no lo detecta. La prueba de humo lo tolera (`uniqueKeys: false`) | Corregir el contrato en un PR documental y retirar esa opción |
| P-05 | `secrets:scan` da 9 hallazgos en archivos generados bajo `frontend/.next` después de compilar | Falla en un árbol con compilación local | Aprobar la exclusión de `.next/` en `gitleaks.toml` (no la amplié por mi cuenta) |
| P-06 | El cliente de API tipado (UXUI §11.3) necesita un generador; `openapi-typescript` exige TypeScript 5 | No está declarado y los Issues no pueden editar `package.json` | Elegir herramienta antes de `ISS-CODE-009` |
| P-07 | `npm audit` completo: 8 avisos moderados en la cadena de `testcontainers` (desarrollo) | No bloquea el control de ejecución | Revisar al actualizar |
| P-08 | npm 11 avisa de scripts de instalación sin aprobar (`allowScripts`) | Aviso en cada instalación | Revisar con `npm install-scripts ls` |

### 7.4 Desviaciones frente a la documentación

| ID | Desviación | Motivo |
|:---|:---|:---|
| D-01 | `WATCHPACK_POLLING: "true"` en el servicio `web` de desarrollo | El equipo tiene `fs.inotify.max_user_instances=128`, ya agotado. Alternativa: `sudo sysctl fs.inotify.max_user_instances=512` y retirar la línea |
| D-02 | `nodemailer` 10.6.1 y `overrides` de `postcss` y `effect` | `npm audit` alto en dependencias de ejecución |
| D-03 | `prisma.config.ts` declara `datasource` solo si existe `DIRECT_URL` | `generate` y `validate` funcionan sin variables |
| D-04 | `schema.prisma` sin modelos (CICD §6.1 prevé copiar el diseño completo) | El encargo prohíbe adelantar modelos; lo hace `ISS-CODE-004` |
| D-05 | Archivos fuera de todo `allowed_paths`: `tsconfig.build.json`, `tailwind.config.ts`, `tokens.css`, `lib/{design,observability,types}`, `.editorconfig`, `.prettierignore` | Plataforma sin dueño en el backlog |
| D-06 | `web` en modo `dev` no propaga el código 78 | Comportamiento de `next dev` |
| D-07 | TypeScript con `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes` y otras opciones adicionales | Más estricto que ADR-STACK-002 |
| D-08 | El plan se llama `Plan0001_Day0_Bootstrap.md`, contra la numeración `DB-18` | Nombre fijado por el encargo; anotado en `Plans/INDICE.md` |
