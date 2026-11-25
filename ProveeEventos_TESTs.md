# ProveeEventos — Estrategia de Pruebas y Plan de Pruebas (`ProveeEventos_TESTs.md`)

## Sección 0 — Cabecera y Metadatos del Documento

| Campo | Valor |
|---|---|
| Documento | Estrategia de Pruebas y Plan de Pruebas de ProveeEventos |
| Versión | 1.0 |
| Fecha | 2026-11-25 |
| Stack objetivo | Node.js 20+, TypeScript estricto (ADR-STACK-002), Express (API REST), Next.js 14+ (BFF), Prisma + PostgreSQL 15/16, Redis/BullMQ (worker), Vitest |
| Documentos de diseño base | PRD v2.4 · SRS v1.3 · SAD v1.4 · DDD v1.4 · API Spec OpenAPI 3.1.0 v1.4.0 (TEC-013, pendiente de aprobación) · ADRs (71 + ADR-001..022) · UXUI v1.1 · Decisiones v1.6 |
| Normativa de pruebas heredada | ADR-TEST-001..006 · SAD §16 · TDD §10.3 · DDD §19 · SRS §14 · UXUI §11.5 (QA-01..QA-15) |
| Alcance del documento | Todas las suites de prueba que los agentes implementadores deben codificar (unitarias, integración, API/contrato, E2E, accesibilidad, multi-tenant, concurrencia, seguridad, carga y arquitectura), su gestión de datos, sus Quality Gates y el handoff de implementación. La instalación del tooling se difiere a `Plan0002_Test_Harness_Setup.md` y la codificación a `Plan0003_Test_Suites_Implementation.md`. |

**Totales de casos de prueba por categoría** (conteo real de este documento; total general: 264 casos únicos):

| Categoría | Prefijo | Total |
|---|---|---|
| Unitarias de dominio | `TC-UNIT` | 54 |
| Integración | `TC-INT` | 49 |
| API y contrato | `TC-API` | 38 |
| End-to-End y accesibilidad | `TC-E2E` | 28 |
| Aislamiento multi-tenant | `TC-MT` | 28 |
| Concurrencia reservas/adjudicaciones | `TC-CONC` | 16 |
| Seguridad | `TC-SEC` | 31 |
| Carga y resiliencia | `TC-LOAD` | 8 |
| Arquitectura y cumplimiento de ADRs | `TC-ARCH` | 12 |

**Quality Gates clave:** cobertura `domain` ≥ 90% líneas y ramas, `application` ≥ 80% (ADR-TEST-006); 0 tests saltados; 100% pass en `TC-MT` y `TC-CONC` (bloqueante en CI, ADR-TEST-003); 0 vulnerabilidades críticas/altas; WCAG 2.1 AA sin violaciones serias/críticas; concurrencia con cero sobreventas y cero adjudicaciones dobles (SRS-NFR-PERF-006).

---

## Sección 1 — Propósito, Alcance e Inventario de Documentos Fuente

### 1.1 Propósito y alcance

Este documento define, de forma determinista y trazable, **qué pruebas se deben escribir, cómo deben ejecutarse, contra qué datos, con qué criterios de aprobación y en qué etapa de CI/CD**, para el sistema ProveeEventos (plataforma multi-tenant para que empresas organizadoras de eventos cotizen y contraten proveedores en Colombia). Está redactado para ser consumido directamente por agentes de IA implementadores: cada caso de prueba `TC-CAT-NNN` es una especificación implementable, no una sugerencia.

**Riesgos de negocio que motivan la estrategia (mapa de riesgos reconciliado):**

1. **Fuga entre tenants** (39 tablas multi-tenant con RLS; aislamiento primario en casos de uso con `organization_id`, RLS como defensa en profundidad con `FORCE ROW LEVEL SECURITY`; ADR-018/ADR-DATA-008).
2. **Carrera en reservas/adjudicaciones** (sobreventa o doble adjudicación; capacidad en dos niveles DEC-006; `ConfirmBooking` único TEC-009 con orden de bloqueo ADR-DATA-18; restricciones únicas parciales como última barrera).
3. **Duplicación de efectos** (doble clic/reintento; idempotencia `Idempotency-Key` TEC-003 con hash de cuerpo y TTL 24 h; consumidores de Outbox idempotentes).
4. **Efectos externos fuera de transacción** (Transactional Outbox TEC-004; prohibido llamar a Auth0/SendGrid/Cloudinary dentro de transacción de BD).
5. **Credenciales Magic Link** (token solo como hash, uso único, consumo+oferta en una transacción, sin tokens en logs ni `Referer`; TEC-008/SAD §7.3).
6. **Autorización RBAC de 6 roles** (`PROPIETARIO`, `ADMIN_EMPRESA`, `COORDINADOR`, `COORDINADOR_RESTRINGIDO`, `PROVEEDOR`, `ADMIN_PLATAFORMA`) con pruebas negativas sistemáticas (DEC-011: "la autorización por evento debe probarse cuidadosamente").
7. **Seguridad OWASP API Top 10** (webhook SendGrid firmado, archivos subidos, SSRF, inyecciones, PII/Ley 1581 de 2012).
8. **Rendimiento** (SRS-NFR-PERF-001..006: búsqueda p95 < 1 s, cotización p95 < 3 s, reserva/adjudicación p95 < 2 s, 500 usuarios simultáneos con error < 1%).
9. **Integridad de datos históricos** (snapshots inmutables DEC-018, 18 triggers de inmutabilidad, redondeo half-up DEC-032, `NUMERIC(14,2)`).

### 1.2 Inventario de documentos fuente

| # | Documento | Contenido relevante para pruebas |
|---|---|---|
| 1 | `ProveeEventos_PRD.md` v2.4 | 79 requisitos `RF-*` en 15 módulos, 22 `RNF-*` medibles, 4 fases (E1/E2/Fase 2/Fase 3), flujos críticos §10 (cotización integral, e-RFQ con rondas, Instant Book, reseñas). Fuente de User Journeys E2E y objetivos RNF. |
| 2 | `ProveeEventos_SRS.md` v1.3 | 13 áreas `SRS-<AREA>-NNN` (AUTH, TEN, CAT, EVT, QUO, BOOK, RFQ, MAGIC, WA, TRK, REV, ADM, NOT) + 46 NFR `SRS-NFR-*` con valores medibles. §8 = 12 escenarios de aceptación (base E2E obligatoria); §14 = estrategia de pruebas derivada (unitarias/integración/seguridad/concurrencia 7 casos/E2E); §9 máquinas de estado normativas; §11 criterios globales de aceptación. |
| 3 | `ProveeEventos_SAD.md` v1.4 | 12 módulos §4.1 con capas `domain/application/infrastructure/http` y matriz de dependencias §4.4 (base de `TC-ARCH`); reglas de consistencia §7.1–7.6 (ConfirmBooking, adjudicación, Magic Link, Outbox, suspensión); colas y 12 jobs §8.2; contrato de errores/idempotencia/paginación §10.5–10.8; observabilidad §12; despliegue y ambientes §13; estrategia de pruebas arquitectónica §16 y suite de concurrencia obligatoria §16.5. |
| 4 | `ProveeEventos_DDD.md` v1.4 | 12 bounded contexts, agregados, value objects (`Money`, `TenantContext`, `MagicLinkTokenHash`…), catálogo de 47 eventos de dominio §8.1, máquinas de estado §15 (Event, Booking, RfqRequest, Offer, Quotation, ItemTracking, Provider), invariantes explícitas por agregado, políticas de dominio (`QuotationPricingService`, `ProviderRankingPolicy` 40/30/20/10, `CapacityDatesPolicy` DEC-025, `ReviewScoreCalculator`), §19 estrategia de pruebas de dominio (18 unitarias + 10 integración + 8 reglas de arquitectura). |
| 5 | `ProveeEventos_TDD.md` | Modelo físico: 72 tablas (39 multi-tenant clase a / 28 globales b / 5 de sistema c), contexto por `set_config` transaccional (`app.organization_id`, `app.provider_id`, `app.user_id`, `app.platform_admin`, `app.magic_token_hash`, `app.invitation_token_hash`), 11 flujos transaccionales F1–F11, orden global de bloqueo N1–N11, idempotencia, Outbox (sondeo 5 s, 10 reintentos), §10.3 estrategia de pruebas de persistencia (7 bloques: integridad por CHECK, concurrencia F1–F11 con barrera N=20 × 100 repeticiones, aislamiento 7 casos × 39 tablas, idempotencia 6 casos, Outbox 8 casos, planes/carga con `EXPLAIN (ANALYZE, BUFFERS)`, migración/reversión). |
| 6 | `ProveeEventos_API_Spec.yaml` (OpenAPI 3.1.0, v1.4.0) | 123 paths / 151 operaciones bajo `/api/v1`; `bearerAuth` JWT Auth0; cabecera `X-Organization-Id` (TEC-006); 9 operaciones públicas; 47 operaciones con `Idempotency-Key` y 7 exenciones documentadas; 6 operaciones con `ETag`/`If-Match`; paginación página vs cursor (TEC-012); 20 `ErrorCode` con su HTTP en `application/problem+json` (RFC 9457); webhook `receiveSendgridEvents` con firma y `sg_event_id`; rate limiting con `429`+`Retry-After` en endpoints sensibles. |
| 7 | `proveeeventos.prisma` | 72 modelos, 55 enums en español (DEC-022), 6 modelos con `version Int` (EventTemplate, Provider, ServicePackage, Event, ProviderAvailability, Quotation) base del locking optimista, únicos parciales con nombre exacto (`uq_bookings__active_item`, `uq_awards__organization_id_cycle_id`, `uq_rfq_offers__current`, `uq_magic_link_grants__active`, `uq_reviews__organization_id_booking_id`, `uq_memberships__single_owner`, `uq_idempotency_keys__tenant/global`), tablas de capacidad con PK compuesta. |
| 8 | `proveeeventos.sql` | Migraciones 00–11 + `20_rls`: 39 tablas con `ENABLE`+`FORCE ROW LEVEL SECURITY`, funciones de contexto `fn_current_*`, roles `pe_owner/pe_migrator/pe_api/pe_worker/pe_retention/pe_readonly` (ninguno `BYPASSRLS`), 91 constraints `ck_*`, 2 `EXCLUDE` (`ex_organization_plans__sin_solape`, `ex_commission_rates__sin_solape`), 18 triggers de inmutabilidad, checks de capacidad `consumed <= capacity`. |
| 9 | `ProveeEventos_ADRs.md` | 71 ADRs en 8 categorías. **`ADR-TEST-001..006` son la normativa de pruebas aprobada** (arquitectura con dependency-cruiser; integración solo contra PostgreSQL 15/16 y Redis reales con prohibición de mockear Prisma/`pg`/`ioredis`/BullMQ/repositorios; suite de concurrencia bloqueante N=20×100; pruebas negativas de tenant por tabla; pruebas por requisito con `adr-guard`; sin pruebas omitidas con umbrales de cobertura). Complementan: ADR-DATA-001..021 (autoridad PostgreSQL, ConfirmBooking, orden de bloqueo, Outbox, dinero exacto, snapshots, máquinas de estado con enums en español), ADR-API-001..008, ADR-SEC-001..010, ADR-OBS-001..005, ADR-GOV-001..007 (anti-sabotaje: GOV-002 controles protegidos, GOV-003 sin directivas de supresión, GOV-005 contrato de PR). |
| 10 | `ProveeEventos_UXUI.md` v1.1 | 65 pantallas `SCR-001..065` por rol y entrega; flujos críticos F-01..F-08; accesibilidad WCAG 2.1 AA (§8: contraste, teclado, foco, ARIA, `axe-core` sin serious/critical, NVDA+Firefox y VoiceOver+iOS en SCR-012/015/021/025/029/050); breakpoints 360–1536 (mínimo 360 px sin scroll horizontal); componentes clave (CMP-28 Comparator, CMP-40 Stepper, CMP-53 AvailabilityCalendar); criterios QA-01..QA-15 §11.5; convención de selectores `data-testid="scr-NNN"` y `scr-NNN-<elemento>`. |
| 11 | `Decisiones.md` v1.6 | DEC-001..037 y TEC-001..012 aprobados (TEC-013 pendiente). Críticos para pruebas: DEC-006 (capacidad 2 por fecha + paquete), DEC-016 (PDF desde snapshot), DEC-018 (snapshots inmutables), DEC-022 (enums en español MAYÚSCULAS sin tildes), DEC-025 (fechas locales y cruce de medianoche ≤ 06:00), DEC-026 (rondas no se reabren), DEC-030 (ventana reseñas 30 días), DEC-031 (verificación ⊥ cuenta), DEC-034/036 (suspensión y revisión con FOR SHARE), DEC-035 (cierre de rondas y precedencia del ítem), DEC-037 (plazos titulares en días hábiles), TEC-006 (`X-Organization-Id`), TEC-008/009, TEC-011 (exenciones idempotencia), TEC-012 (paginación). |
| 12 | `Glosario.md` | Modalidades `INSTANT_BOOK`/`E_RFQ`, canales (`EMAIL_MAGIC_LINK`, `PORTAL_PROVEEDOR`, `WHATSAPP_IA_ASISTIDO`), origen de revisión (`CONTRAPARTE`/`PLATAFORMA`), estados de oferta (solo `RECIBIDA` es adjudicable). Vocabulario obligatorio de este documento. |
| 13 | `Trazabilidad.md` | Matriz SRS-ID → contexto DDD → operationId → eventos → entrega (vía `Tools/check_package.py`). Fuente primaria de la matriz de trazabilidad de pruebas (Sección 13); los `SRS-NFR-*` se trazan aquí. |
| 14 | `CLAUDE.md` | Jerarquía de prevalencia PRD > SRS > SAD > DDD > API; convención de enums; regla de decisiones pendientes. |
| 15 | `Plans/Plan0002.md` (§D4/P04) | Anteproyecto histórico del plan de pruebas (escenario por NFR, E2E de SRS §8, suite de concurrencia, contrato de paginación/idempotencia). Este documento lo sustituye y amplía sin contradecir sus criterios. |

### 1.3 Reglas de prevalencia y reconciliación

* Si dos fuentes se contradicen: PRD > SRS > SAD > DDD > API Spec (CLAUDE.md / DEC-019). No se encontraron contradicciones que afecten la estrategia de pruebas; la única decisión abierta es **TEC-013** (contrato 1.4.0, pendiente de aprobación): las pruebas de contrato se escriben contra el YAML v1.4.0 ya presente en el repositorio y se revalidan si TEC-013 cambia.
* Los IDs (`SRS-*`, `SCR-NNN`, `ADR-*`, `DEC-*`, `TEC-*`, nombres de jobs y constraints) se citan literalmente; ninguna prueba renumera o reinterpreta un ID existente.
* Cuando una regla ya está cubierta por un validador automatizado del paquete (`Tools/check_package.py`, `Tools/check_openapi.py`) o por un linter normativo (ADR-TEST-001), este documento la **referencia** en vez de duplicar pruebas unitarias redundantes.

---

## Sección 2 — Estrategia Global de Pruebas y Matriz de Ejecución CI/CD

### 2.1 Pirámide/trofeo de pruebas y política de mocks vs. servicios reales

ProveeEventos adopta un **trofeo de pruebas** (testing trophy) con dominio denso: la mayor confianza por unidad de tiempo proviene de **integración contra PostgreSQL real** y de **estática** (tipos estrictos + pruebas de arquitectura), con unitarias concentradas en la capa `domain` pura y E2E solo para los flujos que el SRS §14.5 declara: "ningún flujo crítico se considera listo solo por unitarias".

| Nivel | Volumen objetivo | Qué valida | Autoridad |
|---|---|---|---|
| Estática (tipos + lint) | 100% del código | TypeScript estricto, matriz de dependencias, reglas anti-sabotaje | `tsc --noEmit`, ESLint, dependency-cruiser |
| Pruebas de arquitectura (`TC-ARCH`) | 12 reglas | Capas y fronteras de los 12 módulos | ADR-TEST-001 |
| Unitarias (`TC-UNIT`) | Alta (dominio puro) | Invariantes, máquinas de estado, cálculos, parsers | DDD §19, SRS §14.1 |
| Integración (`TC-INT`, `TC-MT`, `TC-CONC`) | Muy alta (banda principal) | PostgreSQL real: constraints, RLS, transacciones, Outbox, jobs, idempotencia | ADR-TEST-002/003/004, TDD §10.3, SAD §16.2/16.5 |
| API/contrato (`TC-API`) | Media-alta | OpenAPI, errores, idempotencia, paginación, webhooks | SAD §10, ADR-API-* |
| E2E (`TC-E2E`) | Baja y selectiva (12 escenarios SRS §8 + flujos UXUI) | Journeys completos en navegador real + WCAG 2.1 AA | SRS §14.5, UXUI §11.5 |
| Carga (`TC-LOAD`) | 4 perfiles en `staging-perf` | NFR-PERF, saturación, fugas | SRS §7.1, SAD §12.2 |

**Política de mocks (estricta):**

1. **Permitido** únicamente en: (a) `TC-UNIT` — la capa `domain` no tiene I/O por diseño (SAD §4.3), por lo que no hay nada que mockear; el tiempo (`reloj`) y los generadores de ID se inyectan como puertos; (b) pruebas de integración/adaptadores para **terceros externos** (Auth0 JWKS, SendGrid API, Cloudinary, Google Maps) mediante stubs wire-level controlados (DT-04) — ADR-TEST-002: "externos con dobles de puertos, suite sin red externa"; (c) `TC-E2E` para simular estados de red/5xx del backend cuando el escenario lo exige (QA-01).
2. **Prohibido** en `tests/integration`, `tests/concurrency` y `tests/multi-tenant`: mock de Prisma, `pg`, `ioredis`, BullMQ, repositorios propios o de la base de datos (ADR-TEST-002 es explícito: "prohibido mockear Prisma/pg/ioredis/BullMQ/repositorios propios"). Toda prueba de aislamiento multi-tenant, concurrencia, Outbox y migraciones corre contra PostgreSQL real en contenedor desechable (Testcontainers, DT-03) con el esquema creado por las migraciones reales y los roles `pe_*` (nunca superusuario).
3. **PostgreSQL es la única autoridad** de capacidad, reservas, adjudicaciones y comisiones (ADR-DATA-001): ninguna prueba debe validar lógica de negocio en Redis o en el frontend; Redis solo se prueba como coordinador de jobs (colas persistentes, AVL-005).
4. Los eventos de dominio salen **solo** por el Outbox en la misma transacción (ADR-DATA-006): una prueba que observe un efecto externo (email, notificación) debe atravesar `outbox_events` + worker, nunca llamar al adaptador directamente desde el caso de uso (verificado también por `TC-ARCH`).

### 2.2 Stack de herramientas de testing

| Necesidad | Herramienta (versión objetivo) | Justificación / fuente |
|---|---|---|
| Runner unitarias/integración/arquitectura/concurrencia | **Vitest** con `allowOnly:false`, `passWithNoTests:false`, `retry:0` | ADR-TEST-001/006 fija Vitest y estas banderas |
| Cobertura | `@vitest/coverage-v8` | ADR-TEST-006 (umbrales por capa; Sección 4) |
| Pruebas de arquitectura | **dependency-cruiser** + reglas custom Vitest (`tests/architecture`) | ADR-TEST-001 |
| Cliente HTTP para pruebas API | **Supertest** contra la app Express montada (sin red) | Decisión de integración con el stack Express (DT-02) |
| Validación de contrato de respuesta | `openapi-response-validator` cargando `ProveeEventos_API_Spec.yaml` como artefacto del repo + `Tools/check_openapi.py` para el contrato mismo | ADR-API-001/002 (DT-02) |
| PostgreSQL real efímero | **Testcontainers** (`postgres:15` y `postgres:16`, matriz de dos versiones) con migraciones reales y roles `pe_*` | ADR-TEST-002, TDD §10.3 (DT-03) |
| Redis real efímero | Testcontainers (`redis:7`) para BullMQ en integración | AVL-005, ADR-TEST-002 |
| Stub wire-level de externos | **MSW** (intercepción HTTP de SendGrid/Cloudinary/Auth0 JWKS) | ADR-ARCH-006/ADR-TEST-002 (DT-04) |
| E2E navegador | **Playwright** (Chromium + WebKit; Firefox para NVDA en pipeline de a11y manual) | SRS §14.5, UXUI §11.5 |
| Accesibilidad automatizada | **@axe-core/playwright** (0 violaciones serious/critical) | SRS-NFR-USA-008, UXUI §8.5 (DT-12) |
| Carga | **k6** (scripts JS en `tests/load`; thresholds como criterio de fallo) | Plan0002 §D4 y perfiles de Sección 11 (DT-05) |
| SAST / SCA / secretos | **Semgrep** (reglas OWASP + anti-sabotaje), `npm audit --audit-level=high`, **gitleaks** | SAD §13.3 paso 5, ADR-STACK-003 |
| DAST nocturno | **OWASP ZAP** baseline contra staging | SRS-NFR-SEC-004, DT-05 |
| SQL de evidencia de rendimiento | `EXPLAIN (ANALYZE, BUFFERS)` como evidencia adjunta a los casos de carga de consultas | TDD §10.3 bloque 6 |

### 2.3 Matriz de ejecución por etapa (con presupuestos de tiempo, DT-07)

| Etapa | Suites ejecutadas | Presupuesto | Bloqueante |
|---|---|---|---|
| **Local / pre-commit** (agente codificador, antes de abrir PR) | lint + `tsc --noEmit`; `TC-UNIT` de los módulos tocados; `TC-ARCH`; `adr-guard` (ADR-TEST-005); `npm run verify:adrs` | ≤ 3 min | Sí (contrato de PR, ADR-GOV-005) |
| **PR Required Status Check** (GitHub Actions) | 1) lint/typecheck; 2) `TC-UNIT` completa + cobertura; 3) `TC-ARCH`; 4) `TC-API`; 5) `TC-INT`; 6) `TC-MT` (matriz completa, ADR-TEST-004 exige CI con RLS activa y rol `pe_api`); 7) `TC-CONC` (suite completa, ADR-TEST-003 la hace bloqueante siempre); 8) Semgrep + `npm audit` + gitleaks; 9) `TC-E2E` smoke (los 12 escenarios SRS §8 en Chromium); 10) Gates de cobertura (Sección 12.2) | ≤ 25 min total (unit 5, arch 2, api 6, int 12, mt 12, conc 15 — en jobs paralelos; e2e-smoke 10) | Sí (todas) |
| **Post-merge a `main`** | `TC-E2E` completa (desktop+móvil+axe) contra ambiente efímero con migraciones desde cero; suite `TC-LOAD` smoke; build de imágenes; verificación de migraciones compatibles N-1 | ≤ 60 min | Sí (E2E y smoke) |
| **Nightly** | ZAP baseline (DAST); `TC-LOAD` Baseline en `staging-perf`; mezcla aleatoria de concurrencia 10 min con cero `40P01` (TDD §10.3); verificación de restauración PITR (semanal; ADR-009/DEC-012); re-escaneo completo de dependencias | ≤ 3 h | Alerta + issue automático (no bloquea merges ya hechos) |
| **Pre-release / pre-producción** | `TC-LOAD` completa (Baseline+Spike+Stress+Soak en `staging-perf`); suite E2E completa en Firefox/WebKit; a11y manual NVDA/VoiceOver en SCR-012/015/021/025/029/050; UAT de los 12 escenarios SRS §8; validación de restauración dentro de RTO 4 h | 2–3 días de ventana | Sí (criterios de Sección 12.2) |

Reglas de activación por PR (ADR-TEST-003/005): todo PR que toque `capacity`, `rfq-offers`, `availability-booking`, `idempotency`, bloqueos, RLS o migraciones **debe** pasar la suite de concurrencia y la matriz multi-tenant completas (en este proyecto son bloqueantes en todos los PR por ser la garantía principal). `retry:0` en todo el pipeline: los fallos nunca se ocultan con reintentos (ADR-TEST-006).

### 2.4 Controles anti-sabotaje de pruebas para agentes de IA

Objetivo: impedir que un agente codificador manipule el suite para "hacer pasar el build". Controles (normativos: ADR-TEST-006, ADR-GOV-002/003/006; verificación automatizada obligatoria):

| # | Control | Implementación verificable |
|---|---|---|
| AS-01 | Prohibición de omisión de pruebas | ESLint `no-restricted-syntax` sobre `CallExpression` con propiedad `skip/only/todo/fails/skipIf/runIf` en `test/it/describe`, y `xit/xdescribe`; Semgrep rule dedicada; Vitest con `allowOnly:false` y `passWithNoTests:false` — un repo sin pruebas o con pruebas filtradas no compila el suite. Prohibidas las cadenas `test.skip`, `it.only`, `describe.skip`, `xit`, `xdescribe`, `expect(true).toBe(true)` (regla Semgrep `trivial-assertion`). |
| AS-02 | Sin directivas de supresión de cobertura | Prohibidos comentarios `v8 ignore`/`c8 ignore`/`istanbul ignore` (ADR-GOV-003); Semgrep los detecta y falla. |
| AS-03 | Cobertura no descendente y umbrales congelados | Los umbrales (Sección 4) viven en `vitest.config.ts` protegido por `CODEOWNERS` (requiere aprobación humana); el job de CI compara la cobertura total con la de `main` y falla si disminuye (ADR-TEST-006). |
| AS-04 | Configs y workflows protegidos | `CODEOWNERS` obliga revisión humana para: `vitest.config.*`, `playwright.config.*`, `tests/load/*` (thresholds k6), `.github/workflows/*`, `tests/architecture/*`, scripts de migraciones de prueba y cualquier archivo de fixtures compartidas (ADR-GOV-002). |
| AS-05 | `adr-guard` por requisito | Un PR que modifique `modules/*/domain` o `modules/*/application` sin casos de prueba asociados **falla** (ADR-TEST-005). El mapeo módulo→suite de este documento es la fuente que consulta el guard. |
| AS-06 | Fallar con cero análisis | dependency-cruiser y las suites de arquitectura fallan si analizan cero archivos (ADR-TEST-001). |
| AS-07 | Sin reintentos que oculten fallos | `retry:0` en Vitest y Playwright (`retries:0`); los únicos reintentos permitidos son los de negocio especificados (deadlock ≤ 3 en transacciones, DT del mecanismo TDD §5.1). |
| AS-08 | Borrar/reducir pruebas exige humano | Cualquier diff que elimine archivos de `tests/` o reduzca casos de una suite marca el PR como "requiere aprobación humana" (check de CI que compara el número de IDs `TC-*` con `main`; solo admite incremento o igualdad salvo aprobación explícita). |
| AS-09 | Críticos no negociables | `TC-MT` y `TC-CONC` con 100% de aprobación requerido (0 fallos, 0 saltos) en cada PR (SAD §16.5, SRS §11 ítem 19). |
| AS-10 | Assertions de seguridad protegidas | Los archivos de aserciones de RLS/autorización (`tests/multi-tenant/**`, `tests/security/**`) requieren `CODEOWNERS`; Semgrep detecta `expect` con valores literales siempre-verdaderos en esos directorios. |

---

## Sección 3 — Gestión de Datos de Prueba y Entornos

### 3.1 Principios

1. **Determinismo total:** sin datos aleatorios sin semilla, sin "datos de hoy" (los tiempos se fijan inyectando el reloj en unitarias y fijando fechas absolutas en integración; para expiraciones se actualiza `sla_expira_at`/`available_at` con UPDATE directo — nunca se espera al reloj real).
2. **Sin PII real:** todos los datos sintéticos con formato válido colombiano de prueba (NIT `9xxxxxxxx-x` sintético, teléfono E.164 `+57300XXXXXXX`, emails `@test.proveeeventos.co`). Prohibido copiar datos de producción (SAD §13.2).
3. **Trazable:** cada fixture declara los `SRS-*` que habilita (heredado de Plan0002 P04) y usa IDs deterministas derivados por UUIDv5 de un namespace fijo (DT-11).
4. **Aislamiento por construcción:** cada worker de Vitest recibe su propia base de datos (esquema `tenant-<worker>` o base separada por Testcontainers) para evitar interferencia; en Playwright cada worker siembra sus datos con sufijo de worker (`-[wN]`).

### 3.2 Arquitectura de factories/builders (Test Data Builders)

Ubicación: `tests/factories/`. API de builders: `buildX(overrides?)` crea el objeto en memoria; `seedX(db, overrides?)` persiste respetando el módulo propietario de cada tabla (un solo módulo escritor por tabla, ADR-ARCH-005).

| Familia | Factory | Datos que fija |
|---|---|---|
| Tenancy | `seedTenant(letter: 'A'\|'B')` | Organización `Org-A`/`Org-B` (NIT sintético), plan `PRO`, membresías: `PROPIETARIO`, `ADMIN_EMPRESA`, `COORDINADOR`, `COORDINADOR_RESTRINGIDO` (con evento asignado y otro sin asignar), usuarios con `auth_subject` sintético |
| Proveedores | `seedProvider(opts)` | Proveedor `VERIFICADO`+`ACTIVO` (visible), variantes `PENDIENTE`/`RECHAZADO`, cuenta `SUSPENDIDO`, disponibilidad con capacidad global 2 (DEC-006), paquetes `INSTANT_BOOK` y `E_RFQ` con `package_daily_capacity` (inventario independiente o compartido), cobertura |
| Eventos/Cotizaciones | `seedEventWithItem(opts)` | Evento en zona `America/Bogota` con intervalos configurables (incluye cruce de medianoche DEC-025), cotización `GENERADA` con snapshot (DEC-018), ítem con subtipo |
| RFQ | `seedRfqRound(opts)` | `RfqCycle` (ronda N de máx 5), solicitudes `ENVIADO` con `sla_expira_at` parametrizable, `MagicLinkGrant` `ACTIVO` con token/hash de prueba conocido, ofertas `RECIBIDA`/`VENCIDA`/`REEMPLAZADA` |
| Contrataciones | `seedBooking(opts)` | Booking `CONFIRMADO` con snapshot inmutable, fechas consumidas, `CommissionRecord` `PENDIENTE`, historial de estados |
| Sistema | `seedReferenceData()` | 21 categorías `CAT-01..21` (DEC-020), subtipos, plantillas globales, planes, tasas de comisión 3% (DEC-027), festivos Colombia (tabla `Holiday`, para DEC-037), plantillas WhatsApp |
| Notificaciones | `seedNotification(...)` | Notificación con `dedupe_key`, `DeliveryAttempt` |

Reglas: los builders nunca insertan fuera de la transacción/envoltorio de contexto de tenant cuando la tabla es clase (a); para seeds de sistema se usa `pe_owner` sin contexto (roles de política `__sistema`). Los fixtures compartidos versionan su `schemaVersion`.

### 3.3 Aislamiento y limpieza

| Suite | Estrategia |
|---|---|
| `TC-UNIT` | Sin BD ni red; reloj/ID inyectados (fake timers solo aquí). |
| `TC-INT` / `TC-API` | 1 PostgreSQL Testcontainers por worker; migraciones reales 00→11+20_rls; **truncado determinista** de todas las tablas (excepto `Holiday`/catálogos seeded) entre casos con `TRUNCATE ... RESTART IDENTITY CASCADE` usando `pe_owner`; semillas por caso vía builders. |
| `TC-MT` | Igual que INT, pero **sin truncar entre los 7 patrones por tabla**: cada patrón siembra sus propios tenants A/B frescos por tabla (generación parametrizada, DT-10). |
| `TC-CONC` | PostgreSQL con `max_connections ≥ 40`; barrera sincronizada (los N requests se arman antes, se liberan juntos); truncado total entre escenarios; `retry:0`; verificación de invariantes post-carrera con queries de auditoría (Sección 9). |
| `TC-E2E` | Ambiente efímero con BD migrada desde cero por run; Playwright con `retries:0`; datos con sufijo de worker; limpieza por API de administración de pruebas (endpoint interno de test o seed por worker). |
| `TC-LOAD` | `staging-perf` restaurado a un snapshot conocido antes de cada perfil; medición de pool (`pg_stat_activity`) durante el run. |

### 3.4 Mapa de entornos

| Entorno | Uso | Datos | Servicios |
|---|---|---|---|
| `local-dev` | Desarrollo del agente; Local/pre-commit | Seeds sintéticos locales | PostgreSQL/Redis en Docker Compose con migraciones reales |
| `ci-ephemeral` | PR/Post-merge | Creados por Testcontainers desde migraciones 00→11+20_rls; roles `pe_api`/`pe_worker`; sin superusuario | PostgreSQL 15 y 16 (matriz), Redis 7; externos con MSW (DT-04) |
| `staging-perf` | Nightly/pre-release (carga, ZAP, a11y) | Dataset de referencia: ≥ 200 proveedores verificados con paquetes, ≥ 1.000 eventos/cotizaciones, catálogo 21 categorías; volumen ×3 para `EXPLAIN` (TDD §10.3) | PostgreSQL con RLS activa, Redis, worker real; SendGrid/Cloudinary con credenciales de sandbox o interceptados |
| `production` | Fuera de alcance de pruebas automatizadas (solo smoke post-despliegue) | — | — |

Cada entorno declara: `DATABASE_URL` con el rol correcto (`pe_api` para API, `pe_worker` para jobs), secretos solo por variables de entorno (SRS-NFR-SEC-007), y `TZ=UTC` en procesos con zona por evento explícita (DEC-007).

## Sección 4 — Pruebas Unitarias (`TC-UNIT`)

### 4.1 Alcance, umbrales y reglas de ejecución

* **Alcance exacto:** capa `modules/*/domain` (entidades, value objects, políticas de dominio, máquinas de estado, servicios de cálculo) y las reglas puras de `modules/*/application` (autorización por operación, validadores). **Fuera de alcance:** HTTP, Prisma, Redis, SDKs (no existen en `domain` por diseño, SAD §4.3).
* **Herramienta:** Vitest, sin red ni BD, reloj e ID inyectados como puertos. Duración máxima de la suite completa: **90 s**.
* **Umbrales de cobertura (bloqueantes, ADR-TEST-006 + DT-01):**

| Capa | Líneas | Ramas | Nota |
|---|---|---|---|
| `modules/*/domain` | ≥ 90% | ≥ 90% | Mínimo exigido por ADR-TEST-006 |
| `modules/*/application` | ≥ 80% | ≥ 80% | Mínimo exigido por ADR-TEST-006 |
| `shared/` | ≥ 85% | ≥ 85% | DT-01: código transversal estable |
| Global (todo `src/`) | ≥ 80% | ≥ 75% | DT-01; además **no descendente** contra `main` |
| `http` e `infrastructure` | sin umbral propio | — | Se validan por `TC-INT`/`TC-API` reales, no con mocks |

* Las transiciones de máquina de estado se prueban **de forma exhaustiva**: para cada máquina (DDD §15 / SRS §9) toda transición válida tiene un caso positivo y las inválidas se cubren por matriz de pares estado×acción rechazados.
* Cuando una regla ya está garantizada por un constraint de BD verificado en `TC-INT` (p. ej. `uq_reviews__organization_id_booking_id`), la unitaria verifica solo la **decisión temprana del dominio** (error de dominio antes de llegar a la BD), no el constraint.

### 4.2 Catálogo de casos — VOs transversales y organizaciones

| ID | Unidad (módulo) | Escenario / Precondiciones | Entrada / Acción | Resultado esperado (aserción) | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-UNIT-001 | `Money` (shared) | Importe con 2 decimales | Redondeo half-up de `1234.005` al peso por línea | `1234.01` (half-up, no half-even); tipo decimal exacto, nunca float | P0 | DEC-032, SRS-QUO-013 |
| TC-UNIT-002 | `Money` (shared) | Suma de líneas ya redondeadas | Sumar 3 líneas redondeadas `10.01+10.02+10.00` | Subtotal `30.03`; sin recálculo sobre valores sin redondear | P0 | DEC-032, SRS-QUO-008 |
| TC-UNIT-003 | `Money` (shared) | Moneda distinta de COP | Construir `Money(100, 'USD')` | Rechazo con error de dominio (`currency` fija `COP`) | P1 | ck_quotations__importes, SRS §4.3 |
| TC-UNIT-004 | `TenantContext` (organizations) | Usuario con 2 membresías sin organización activa | Resolver `TenantContext` | Error de dominio equivalente a `ORGANIZATION_REQUIRED` | P0 | TEC-006, SRS-AUTH-010 |
| TC-UNIT-005 | `Membership` (organizations) | Empresa con 1 PROPIETARIO activo | Agregar segundo `PROPIETARIO` | Rechazo: único propietario por empresa | P0 | DEC-008, `uq_memberships__single_owner` |
| TC-UNIT-006 | Autorización de operación (organizations) | Membresía `SUSPENDIDO`/`INVITADO` | Ejecutar caso de uso de escritura de la empresa | Rechazo `FORBIDDEN`; solo membresía `ACTIVO` con rol habilitante opera | P0 | DDD §5.3, SRS-AUTH-005 |
| TC-UNIT-007 | `CoordinatorRestrictionPolicy` (organizations) | `COORDINADOR_RESTRINGIDO` + evento no asignado | Intentar operar el evento (editar ítem, adjudicar, cancelar) | Rechazo de dominio; para eventos asignados permite leer y operar según matriz UXUI §3.2 | P0 | SRS-AUTH-011, DEC-011 |
| TC-UNIT-008 | Invitación (organizations) | Token de invitación expirado por job | Aceptar invitación con token `EXPIRADA` | Rechazo con error de dominio determinista | P1 | Job «Expiración de invitaciones y transferencias» |

### 4.3 Catálogo — provider-catalog, taxonomy y eventos

| ID | Unidad (módulo) | Escenario / Precondiciones | Entrada / Acción | Resultado esperado (aserción) | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-UNIT-009 | Visibilidad de proveedor (provider-catalog) | Matriz `verificationStatus` × `accountStatus` | Evaluar publicabilidad para VERIFICADO+ACTIVO, VERIFICADO+SUSPENDIDO, `PENDIENTE`+ACTIVO, RECHAZADO+ACTIVO | Solo `VERIFICADO ∧ ACTIVO ∧ publicable` es visible; las otras 3 combinaciones no | P0 | DEC-031, SRS-CAT-010 |
| TC-UNIT-010 | `ProviderProfile` (provider-catalog) | Perfil con 5 categorías asignadas | Asignar una 6ª categoría | Rechazo: máximo 5 categorías | P1 | SRS-CAT-005 |
| TC-UNIT-011 | `ServicePackage` (provider-catalog) | Precio negativo o no exacto | Crear paquete con `basePrice = -1` o 3 decimales | Rechazo de dominio (precio exacto ≥ 0) | P1 | SRS-CAT-006, ck_service_packages__precios |
| TC-UNIT-012 | Cambio de capacidad (provider-catalog) | Reserva activa con consumed=1 y proveedor baja capacidad a 0 | Intentar invalidar retroactivamente la reserva existente | La reducción aplica a futuras reservas; la reserva vigente no se invalida (el dominio no emite liberación) | P0 | SRS-BOOK-003 |
| TC-UNIT-013 | Integridad taxonómica (taxonomy-templates) | Subtipo con paquetes activos | Desactivar categoría padre | Rechazo o archivado sin reutilización de código; código de categoría nunca reutilizable | P1 | SRS-CAT-004, DEC-020 |
| TC-UNIT-014 | Transiciones `Event` (event-management) | Evento `BORRADOR` | Aplicar cada acción (cotizar, enviar RFQ, cancelar, completar) | `BORRADOR→COTIZADO` y `BORRADOR→CANCELADO` válidas; `→EN_PROGRESO`, `→COMPLETADO` rechazadas | P0 | DDD §15 Event, SRS-EVT-006 |
| TC-UNIT-015 | Transiciones `Event` (event-management) | Evento `ENVIADO` | Cancelar sin contratación `EN_PROGRESO+` | Permite `ENVIADO→CANCELADO` y emite cancelación de RFQ abiertas | P0 | SRS-EVT-009, DEC-024 |
| TC-UNIT-016 | Transiciones `Event` (event-management) | Evento `ENVIADO` con booking `CONFIRMADO`/`EN_PROGRESO` | Editar fecha/zona/horario del evento | Rechazo de edición de fechas con compromisos activos | P0 | SRS-EVT-008, DEC-024 |
| TC-UNIT-017 | Clonación (event-management) | Evento con cotizaciones y RFQ | Clonar evento | Nuevo `eventId`; sin compromisos, sin RFQ, sin bookings; plantilla copiada | P1 | SRS-EVT-005 |
| TC-UNIT-018 | `EventDate` (shared) | Zona IANA vs offset fijo | Crear fecha con `timeZone='America/Bogota'` y con offset fijo `-05:00` | Acepta IANA; rechaza offset fijo (DEC-007); `startsAtUtc`/`endsAtUtc` + local consistentes | P0 | DEC-007, SRS §4.3 |

### 4.4 Catálogo — quotation (cálculo, ranking, versionado, tracking)

| ID | Unidad (módulo) | Escenario / Precondiciones | Entrada / Acción | Resultado esperado (aserción) | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-UNIT-019 | `QuotationPricingService` (quotation) | 15 ítems con precio base y por persona | Calcular subtotal, comisión referencial 3% (base = precio+extras antes de impuestos, DEC-027) y total | Totales exactos sobre líneas redondeadas; único resultado para pantalla, PDF y snapshot | P0 | SRS-QUO-008, DEC-027, DEC-032 |
| TC-UNIT-020 | `QuotationPricingService` (quotation) | Ítem con impuestos `INCLUIDO` | Calcular total | El impuesto no se suma dos veces; `NO_APLICA`/`POR_CONFIRMAR` sin ajuste | P1 | DEC-010, TaxMode |
| TC-UNIT-021 | `ProviderRankingPolicy` (quotation) | 20 candidatos con puntajes | Ordenar con pesos 40/30/20/10 | Orden determinista; desempate por `published_at`; `ranking_version` incluida y reproducible | P0 | SRS-QUO-004, DEC-004 |
| TC-UNIT-022 | `ProviderRankingPolicy` (quotation) | Datos incompletos (sin reseñas) | Calcular ranking | Fallback determinista del SRS aplicado; nunca `NaN`/crash | P1 | SRS-QUO-004 (fallback) |
| TC-UNIT-023 | Elegibilidad (quotation) | Proveedores mixtos: no verificado, suspendido, sin paquete en categoría, fuera de cobertura, con capacidad | Filtrar elegibles para cotización rápida | Solo elegibles; capacidad y precio estimado provenientes de `searchProviders` | P0 | SRS-QUO-002, SRS-CAT-014 |
| TC-UNIT-024 | Snapshot de cotización (quotation) | Cotización `GENERADA` (snapshot v1) | Editar datos vivos y regenerar | Snapshot v1 intacto (inmutable); versión nueva con `version_number+1` | P0 | SRS-QUO-012, DEC-018 |
| TC-UNIT-025 | Selección/sustitución (quotation) | Ítem con proveedor seleccionado | Sustituir proveedor y recalcular | Selección anterior reemplazada sin perder otras selecciones; totales recalculados | P1 | SRS-QUO-007, RF-INT-05 |
| TC-UNIT-026 | `Quotation` estados (quotation) | Matriz de estados BORRADOR/GENERADA/ENVIADA/CERRADA | Intentar eliminar ítem con solicitudes/contrataciones en `ENVIADA`; intentar editar `CERRADA` | En `ENVIADA` se rechaza eliminar ítem comprometido; `CERRADA` es solo lectura | P0 | DDD §15 Quotation, SRS-QUO-009 |
| TC-UNIT-027 | `ItemTracking` estados (quotation) | Ítem `COTIZADO` | Transición directa `COTIZADO→CALIFICADO` y `COTIZADO→COMPLETADO` | Ambas rechazadas: prohibido sin contratación | P0 | SRS-TRK-003, SRS §9.3 |
| TC-UNIT-028 | `ItemTracking` precedencia (quotation) | Ronda terminada con ítem sin RFQ abiertas | Aplicar precedencia DEC-035 con distintos históricos (cancelado+expirado+rechazado…) | Destino = primero que aplique: `CANCELADO > NO_ADJUDICADO > EXPIRADO > RECHAZADO > COTIZADO` | P0 | DEC-035, SRS §9.3 |
| TC-UNIT-029 | `ItemTracking` reactivación (quotation) | Ítem `RECHAZADO`/`EXPIRADO`/`NO_ADJUDICADO`/`CANCELADO` | Nueva ronda enviada / nuevo Instant Book | Transición válida a `ENVIADO`/`CONFIRMADO` según origen; historial registrado con `sourceEventId` | P1 | DDD §15 ItemTracking |
| TC-UNIT-030 | Render WhatsApp (quotation/rfq) | Plantilla con placeholders y datos de contacto | Renderizar mensaje dos veces con la misma entrada | Salida byte-idéntica (determinista, SRS-WA-002); teléfonos/emails sustituidos por marcadores antes del prompt IA (PRIV-008) | P1 | SRS-WA-002, PRIV-008 |

### 4.5 Catálogo — availability-booking (capacidad, estados, comisión, cancelación, suspensión)

| ID | Unidad (módulo) | Escenario / Precondiciones | Entrada / Acción | Resultado esperado (aserción) | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-UNIT-031 | `BookingCapacityPolicy` (availability-booking) | Capacidad 2, consumed 2 | Validar reserva de 1 más | Rechazo de dominio (equivalente a `CAPACITY_EXHAUSTED`) antes de tocar BD | P0 | SRS-BOOK-003, SAD §7.1 |
| TC-UNIT-032 | `BookingCapacityPolicy` | Capacidad por paquete ≠ global (inventario independiente) | Reservar paquete con cupo propio agotado y global libre | Rechazo por cupo de paquete; y viceversa (global agotado, paquete libre → rechazo) | P0 | DEC-006, ADR-013 |
| TC-UNIT-033 | `CapacityDatesPolicy` (availability-booking) | Intervalo vie 18:00 → dom 14:00 | Calcular fechas locales a consumir | 3 fechas (vie/sáb/dom); cada una en zona del evento | P0 | DEC-025, SRS-EVT-010 |
| TC-UNIT-034 | `CapacityDatesPolicy` | Intervalo vie 20:00 → sáb 03:00 (termina ≤ 06:00) | Calcular fechas a consumir | Solo fecha de inicio (viernes) | P0 | DEC-025 |
| TC-UNIT-035 | `Booking` estados (availability-booking) | Matriz F-05: CONFIRMADO, CANCELACION_SOLICITADA, CANCELACION_EN_REVISION, EN_PROGRESO, SERVICIO_REALIZADO, INCIDENCIA, COMPLETADO, CANCELADO, NO_PRESTADO | Aplicar cada transición válida e inválida del DDD §15 | Válidas aceptadas con evento correspondiente; inválidas (p. ej. `CANCELADO→CONFIRMADO`, `COMPLETADO→EN_PROGRESO`) rechazadas con `INVALID_STATE_TRANSITION` | P0 | DEC-023, SRS-BOOK-009 |
| TC-UNIT-036 | `CommissionPolicy` (availability-booking) | Booking por estado | Derivar estado de comisión | `PENDIENTE` (confirmado/en progreso), `RETENIDA` (INCIDENCIA), `DEVENGADA` (COMPLETADO), `NO_APLICA` (CANCELADO/NO_PRESTADO), `REVERTIDA` solo por corrección auditada | P0 | SRS-BOOK-010, DEC-002 |
| TC-UNIT-037 | `CancellationPolicy` (availability-booking) | Cancelación aceptada / disputada / sin respuesta 72 h | Resolver destino y capacidad | Aceptada → `CANCELADO` y libera capacidad; disputada o 72 h → `CANCELACION_EN_REVISION` **sin** liberar; servicio iniciado no cancela por autoservicio | P0 | SRS-BOOK-007, DEC-001 |
| TC-UNIT-038 | `SuspensionReviewPolicy` (availability-booking) | Booking futuro con inicio a 10 días; y otro con inicio a 24 h | Calcular ventana de decisión `reviewDecisionDueAt` | `min(72 h, inicio local del servicio)` aplicado por caso | P0 | DEC-036, SRS-ADM-013 |
| TC-UNIT-039 | Decisión de revisión (availability-booking) | Origen `PLATAFORMA`, ventana vigente; organizadora decide | Aplicar `MANTENER` y `CANCELAR` | `MANTENER` registra decisión (reversible en ventana); `CANCELAR` → `CANCELADO` + liberación con orden de bloqueo; fuera de ventana → solo administración | P0 | DEC-036, SRS-ADM-013 |
| TC-UNIT-040 | Cierre automático (availability-booking) | `SERVICIO_REALIZADO` hace 5 días sin incidencia | Determinar cierre | Transición a `COMPLETADO` + `BookingClosed` + comisión `DEVENGADA`; con incidencia abierta no cierra | P1 | SRS-BOOK-008, DEC-002 |

### 4.6 Catálogo — rfq-offers, magic links, assisted-response, reviews, administración

| ID | Unidad (módulo) | Escenario / Precondiciones | Entrada / Acción | Resultado esperado (aserción) | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-UNIT-041 | `SlaAcceptancePolicy` (rfq-offers) | `received_at == sla_expires_at` y 1 ms después | Evaluar aceptación en el límite (hora del servidor) | Acepta si `received_at <= sla_expires_at`; después rechaza; `RESPONDIDO` nunca pasa a `EXPIRADO` | P0 | SRS-RFQ-004, SAD §8.4 |
| TC-UNIT-042 | Invitación por ronda (rfq-offers) | 0, 6 y 5 proveedores seleccionados | Validar tamaño de ronda | Rechazo con 0 y 6; acepta 5 (`slot 1..5`) | P0 | SRS-RFQ-001, `ck_rfq_requests__cupo` |
| TC-UNIT-043 | `AwardPolicy` (rfq-offers) | Ofertas RECIBIDA vigente / VENCIDA / REEMPLAZADA; ítem con ganador previo | Evaluar adjudicabilidad | Solo `RECIBIDA` vigente sin ganador es adjudicable; estados finales `ADJUDICADA` + competidoras `NO_ADJUDICADA` | P0 | SRS-RFQ-009, DEC-005 |
| TC-UNIT-044 | Rondas terminales (rfq-offers) | `RfqRequest` en terminal (RECHAZADO/EXPIRADO/ADJUDICADO/NO_ADJUDICADO/CANCELADO) | Intentar reabrir | Rechazo; única vía = nueva ronda `RfqCycle`; reintento solo válido desde `ERROR_ENVIO` con `retry_count ≤ 3` | P0 | DEC-026, `ck_rfq_requests__reintentos` |
| TC-UNIT-045 | Vigencia de oferta (rfq-offers) | `offerValidityUntil` vencida | Intentar adjudicar | Rechazo (equivalente a `OFFER_EXPIRED`); revisión permitida mientras solicitud abierta (DEC-026) | P0 | SRS-RFQ-012 |
| TC-UNIT-046 | `MagicLinkAccessPolicy` (rfq-offers) | Grants ACTIVO/CONSUMIDO/REVOCADO/EXPIRADO; token de otra solicitud | Validar acceso y consumo | Solo `ACTIVO` de su propia solicitud; consumo = uso único (un solo `MagicLinkConsumed`); expiración en `sla_expira_at` | P0 | SRS-MAGIC-002/003, TEC-008 |
| TC-UNIT-047 | `MagicLinkTokenHash` (shared/rfq) | Token claro en entrada | Calcular representación y logs | Solo se manipula el hash; el token claro jamás aparece en representaciones/logging del dominio | P0 | SAD §7.3, SRS-NFR-SEC-011 |
| TC-UNIT-048 | Validación JSON asistido (assisted-response) | JSON válido / con campo extra / faltante / precio inconsistente / ítem distinto al solicitado | Validar contra esquema estricto | Solo esquema exacto pasa; mismatch de ítem → error `ASSISTED_RESPONSE_MISMATCH`; nunca crea oferta sin confirmación humana | P0 | SRS-WA-006/007, SAD §10.6 |
| TC-UNIT-049 | Origen de oferta (assisted-response) | Confirmación humana completada | Registrar oferta | `origin = WHATSAPP_IA_ASISTIDO` trazado; rechaza confirmación automática | P1 | SRS-WA-008 |
| TC-UNIT-050 | `ReviewEligibilityPolicy` + `ReviewScoreCalculator` (reviews) | Booking COMPLETADO / EN_PROGRESO; reseña previa en mismo booking; ventana 30 días vencida | Evaluar elegibilidad y promedio de 4 dimensiones | Elegible solo COMPLETADO dentro de 30 días y sin reseña previa (una por contratación); promedio = media exacta de puntualidad, calidad, comunicación, precio-calidad (coherente con `ck_reviews__promedio`); respuesta del proveedor no altera puntaje | P0 | SRS-REV-001..004, DEC-030 |
| TC-UNIT-051 | Verificación de proveedor (administration-audit) | Proveedor `PENDIENTE` / `RECHAZADO` | Registrar decisión VERIFICADO/RECHAZADO con motivo | Transiciones válidas del DDD §15 (incl. `RECHAZADO→PENDIENTE` al corregir); decisión auditada con autor | P1 | SRS-ADM-001, DEC-009 |
| TC-UNIT-052 | Purga con `LegalHold` (administration-audit) | Recurso con `legal_hold` activo | Evaluar purga por retención | Purga bloqueada mientras `legal_hold` activo; liberación registrada | P0 | SRS-ADM-012, DEC-003 |
| TC-UNIT-053 | Plazos de titulares (administration-audit) | Solicitud CONSULTA/RECLAMO con festivos CO sembrados | Calcular vencimiento en días hábiles | 10 días hábiles (+5 prórroga) para consulta; 15 (+8) para reclamo; prórroga solo informada antes de vencer | P1 | DEC-037, SRS-ADM-012 |
| TC-UNIT-054 | Máquina `Offer` (rfq-offers) | Matriz RECIBIDA/REEMPLAZADA/ADJUDICADA/NO_ADJUDICADA/INVALIDADA/VENCIDA | Aplicar transiciones válidas e inválidas | Solo `RECIBIDA` transiciona a adjudicada/reemplazada; terminales no mutan; cada revisión crea oferta nueva inmutable | P0 | DDD §15 Offer, DEC-005 |

**Criterio de aceptación de la suite (por módulo):** cada caso de arriba tiene su `it()` con aserciones exactas; la suite completa < 90 s; cobertura por capa según §4.1; cero accesos a red/BD (verificado con regla ESLint que prohíbe importar `prisma`/`pg`/`ioredis` desde `tests/unit/**`).

## Sección 5 — Pruebas de Integración (`TC-INT`)

### 5.1 Alcance, entorno y reglas de aislamiento

* **Alcance exacto:** capa de persistencia y orquestación contra **PostgreSQL real** (Testcontainers `postgres:15` y `postgres:16` en matriz) y **Redis real** (`redis:7` para BullMQ): migraciones, constraints, índices, triggers, RLS (la matriz completa de RLS vive en Sección 8), transacciones de los flujos F1–F11 del TDD §3, Outbox, idempotencia, colas/jobs, workers, proyecciones y adaptadores externos con stubs wire-level (MSW, DT-04).
* **Prohibiciones (ADR-TEST-002):** mock de Prisma, `pg`, `ioredis`, BullMQ o repositorios propios. El esquema se crea **desde cero con las migraciones reales** (00→11 + `20_rls`) y el suite corre con los roles de BD reales (`pe_api`, `pe_worker`); nunca superusuario.
* **Aislamiento:** truncado determinista entre casos (§3.3); transacciones con rollback explícito cuando el flujo lo permite; `retry:0`.
* Las filas "Rechazo" se asertan por **SQLSTATE + código de error de dominio mapeado** (`23505`→409, `23503`→400/409, `23514`→400), no por mensaje de texto.

### 5.2 Catálogo — migraciones e integridad estructural

| ID | Alcance | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-INT-001 | Migraciones | BD vacía PG15 (y matriz PG16) | Ejecutar migraciones 00→11+`20_rls` | 72 tablas creadas; 39 con `relforcerowsecurity=true`; roles `pe_*` creados; segunda ejecución idempotente | P0 | TDD §10.1, ADR-018 |
| TC-INT-002 | Deriva de esquema | BD migrada | `prisma migrate diff` esquema↔BD | Sin deriva (diff vacío) | P0 | TDD §10.3 (7) |
| TC-INT-003 | Roles de mínimo privilegio | BD migrada | Conectar como `pe_api` y `pe_worker`; consultar `rolbypassrls` | Ambos operan; `rolbypassrls=false` en todos los roles de ejecución; `pe_owner` sin login | P0 | TDD §5.2 |
| TC-INT-004 | FK compuestas cross-tenant | Tenant A y B sembrados | INSERT booking de A con `organization_id` de B y `event_id` de A | Rechazo `23503` (FK compuesta impide mezclar tenants) | P0 | TDD §5.2 |
| TC-INT-005 | CHECK de capacidad | Fila `provider_daily_capacity` (capacity=2, consumed=2) y `package_daily_capacity` | `UPDATE consumed = 3` en ambas tablas | Rechazo `23514` por `ck_provider_daily_capacity__cupo`/`ck_package_daily_capacity__cupo` | P0 | ADR-016, TDD SQL-150/151 |
| TC-INT-006 | CHECK de importes | Cotización en construcción | INSERT con `currency='USD'` o `subtotal < 0` | Rechazo `23514` (`ck_quotations__importes` fuerza `COP` y ≥ 0) | P1 | SRS §4.3 |
| TC-INT-007 | CHECK promedio reseñas | Reseña 4 dimensiones | INSERT/UPDATE con `average ≠ media(puntuality+service_quality+communication+value_for_money)/4` | Rechazo `23514` (`ck_reviews__promedio`) | P1 | SRS-REV-003 |
| TC-INT-008 | Cupo de ronda | RfqCycle activo | INSERT solicitudes con `slot=6` y con `(cycle_id, slot)` duplicado | Rechazo por `ck_rfq_requests__cupo` y `uq_rfq_requests__cycle_id_slot`; máx 5 invitados | P0 | SRS-RFQ-001, TEC-002 |
| TC-INT-009 | Reintentos de despacho | RfqRequest en `ERROR_ENVIO` | UPDATE `retry_count = 4` | Rechazo `23514` (`ck_rfq_requests__reintentos`, rango 0..3) | P1 | DEC-026 |
| TC-INT-010 | EXCLUDE sin solape | `organization_plans` con vigencia activa | INSERT plan solapado; igual para `commission_rates` | Rechazo `ex_organization_plans__sin_solape` / `ex_commission_rates__sin_solape` | P1 | ADR-DATA-011 |
| TC-INT-011 | Inmutabilidad por trigger | Filas en `quotation_versions`, `booking_terms_snapshots`, `rfq_offers`, `audit_logs`, `commission_records` | `UPDATE` y `DELETE` sobre cada una | Rechazo por `fn_reject_mutation` (triggers `__inmutable`/`__sin_borrado`); prueba parametrizada sobre las 18 tablas protegidas | P0 | DEC-018, SQL triggers |
| TC-INT-012 | Únicos parciales — predicado | Tenants sembrados | Insertar 2ª fila "activa" que viola: `uq_bookings__active_item`, `uq_awards__organization_id_cycle_id`, `uq_rfq_offers__current`, `uq_magic_link_grants__active`, `uq_reviews__organization_id_booking_id`, `uq_memberships__single_owner`, `uq_ownership_transfers__pending`, `uq_booking_change_proposals__pending` | Cada segunda inserción activa → `23505` con el nombre de constraint esperado | P0 | TDD §4.3, ADR-DATA-004 |
| TC-INT-013 | Únicos parciales — fuera de predicado | Booking previo `CANCELADO` del ítem | Crear nueva reserva activa del mismo ítem | Permitido (el único solo aplica a filas vivas); estado final: 1 activa + 1 cancelada | P0 | TDD §10.3 (1) |
| TC-INT-014 | Snapshot de booking inmutable en BD | Booking confirmado | UPDATE sobre `booking_terms_snapshots` | Rechazo por trigger; snapshot con `schemaVersion` intacto | P0 | ADR-012/019 |

### 5.3 Catálogo — flujos transaccionales F1–F11 (TDD §3)

| ID | Flujo | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-INT-015 | F1 ConfirmBooking (happy) | Paquete INSTANT_BOOK, capacidad 2, intervalo de 3 fechas locales | Ejecutar `ConfirmBooking` con envoltorio de contexto de tenant | Booking `CONFIRMADO`; `consumed=1` en cada una de las 3 fechas (global y paquete); snapshot creado; `CommissionRecord` `PENDIENTE`; `BookingConfirmed` en `outbox_events` en la **misma transacción**; fechas de reserva registradas sin `released_at` | P0 | SAD §7.1/7.5, SRS-BOOK-002 |
| TC-INT-016 | F1 sin cupo | Capacidad 2 con consumed 2 en la 2ª fecha del intervalo | Ejecutar `ConfirmBooking` | Rollback completo: sin booking, sin consumo (ni parcial en las fechas 1-2), sin evento; error `CapacityExhausted`→`409 CAPACITY_EXHAUSTED` | P0 | SRS-BOOK-002, SAD §7.5 |
| TC-INT-017 | F1 inventario DEC-006 | Paquete con `independentInventory=true` y otro `false` | Reservar ambos | Independiente consume solo `package_daily_capacity`; compartido consume también la global del proveedor | P0 | DEC-006 |
| TC-INT-018 | F2 Adjudicación completa | Ítem con 3 ofertas RECIBIDA vigentes de 3 solicitudes ENVIADO | `awardRfqOffer` (ganador = oferta 1) | Ganador `ADJUDICADO`+`ADJUDICADA`; solicitudes 2-3 y ofertas `NO_ADJUDICADO`/`NO_ADJUDICADA`; grants `REVOCADO`; `rfq_cycles.closed_at` fijado; booking creado; outbox con `OfferAwarded`+2×`OfferNotAwarded`+`BookingConfirmed`; `Award` insertado con únicos `uq_awards__*` | P0 | SAD §7.2, SRS-RFQ-009 |
| TC-INT-019 | F5 Expiración de SLA | 3 solicitudes: ENVIADO vencida hace 1 min; ENVIADO vigente; RESPONDIDO con SLA vencido | Ejecutar job «Expiración de SLA» (margen `sla_expires_at <= now()-30s`) | Solo la 1ª → `EXPIRADO` + `RfqRequestExpired`; vigente y RESPONDIDO intactos; ítem sigue precedencia DEC-035 si no hay más RFQ abiertas | P0 | SRS-RFQ-004, DEC-035 |
| TC-INT-020 | F6 Liberación de capacidad | Booking multi-fecha con cancelación aceptada (1 fecha ya iniciada sin `released_at`) | Ejecutar `ReleaseBookingCapacity` | Solo fechas no liberadas se restan de `consumed`; registro con `released_at`; comisión → `NO_APLICA`; mismo orden de bloqueo que ConfirmBooking | P0 | SAD §7.5, SRS-BOOK-007 |
| TC-INT-021 | F7 Suspensión de proveedor | Proveedor con RFQ abiertas, oferta RECIBIDA, grants activos, booking futuro CONFIRMADO y booking vigente EN_PROGRESO | `SetProviderSuspension` | Una transacción: RFQ→`CANCELADO`, oferta→`INVALIDADA`, grants revocados, booking futuro→`CANCELACION_EN_REVISION` (origen PLATAFORMA, ventana DEC-036), vigente intacto; outbox `ProviderSuspended`+`RfqRequestCancelled`+`BookingPlacedUnderPlatformReview`; auditoría lista bookings afectados; re-ejecutar = sin cambios (idempotente) | P0 | SAD §7.6, DEC-034 |
| TC-INT-022 | F8 Cierre y comisión | Booking `SERVICIO_REALIZADO` | `recordBookingCompletion` (organizador confirma) | →`COMPLETADO`; `BookingClosed`+`CommissionAccrued`; comisión `DEVENGADA` con % congelado del snapshot; alternativa job «Cierre automático» a 5 días sin incidencia | P0 | SRS-BOOK-008, DEC-002 |
| TC-INT-023 | F9 Congelación de cotización | Cotización BORRADOR con ítems | `requestQuotationPdf` / envío RFQ | Snapshot `GENERADA` inmutable + `QuotationVersionCreated`; PDF posterior usa el snapshot (no datos vivos) | P1 | DEC-016/018, SRS-QUO-012 |
| TC-INT-024 | F10 Cambio de disponibilidad | Reservas activas consumed=2; bloqueo manual | `setProviderAvailability` con `capacity=0` | Filas de capacidad actualizadas sin bajar `consumed`; reservas vigentes intactas; nuevas reservas → sin cupo | P0 | ADR-016, SRS-CAT-009 |
| TC-INT-025 | F11 Edición de evento con RFQ | Evento ENVIADO con ronda abierta y grants activos | `updateEvent` (cambio permitido por DEC-024) | Solicitudes abiertas→`CANCELADO`, ofertas→`INVALIDADA`, grants revocados; sin booking futuro (ese caso lo rechaza la unitaria de edición con compromisos de §4.3) | P0 | SRS-EVT-008, DEC-024 |
| TC-INT-026 | Locking optimista (6 entidades) | Fila de Event/Quotation/ServicePackage/Provider/ProviderAvailability/EventTemplate con `version` lida | UPDATE con `If-Match` de versión vieja (parametrizado) | `UPDATE ... WHERE id=? AND version=?` afecta 0 filas → `409→412 PRECONDITION_FAILED`; con versión vigente → fila actualizada y `version+1` | P0 | TEC-011, ADR-API-005 |

### 5.4 Catálogo — Outbox transaccional y consumidores

| ID | Alcance | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-INT-027 | Atomicidad negocio+evento | Transacción de negocio | Forzar rollback después de insertar `outbox_events` | Ni el cambio de negocio ni el evento quedan; al confirmar, ambos existen (misma transacción) | P0 | ADR-DATA-006, SAD §7.4 |
| TC-INT-028 | Publicador | 5 eventos `PENDIENTE`; 1 con payload inválido (>32 KiB) | Sondeo cada 5 s; fallo simulado del despacho externo (MSW 500) | Publicados →`PUBLICADO` con `published_at`; el fallido: `attempts+1`, `available_at+60s`; tras 10 intentos →`FALLIDO` (alerta); reprocesable a pendiente manualmente | P0 | TDD §5.3, ADR-DATA-006 |
| TC-INT-029 | Idempotencia de consumidor | Evento `BookingConfirmed` ya procesado (fila en `processed_events`) | Reentregar el mismo evento al consumidor de notificaciones | Un solo efecto (1 notificación; `dedupe_key` respetado); segunda entrega no-op transaccional | P0 | TDD §5.3, TEC-004 |
| TC-INT-030 | Reconciliación 1 min | Evento `PENDIENTE` con `available_at` vencido y >10 min de edad | Ejecutar job de reconciliación | Publicado; métrica de rezago expuesta; `FALLIDO` con payload válido vuelve a `PENDIENTE` | P1 | SAD §7.4 |
| TC-INT-031 | Limpieza | Eventos PUBLICADO > 30 días; `processed_events` > 45 días | Job de limpieza (cola `maintenance`, lotes de 1.000) | Eliminación por lotes; `PENDIENTE`/`FALLIDO` nunca borrados; CHECK `payload ≤ 32 KiB` verificado en inserción | P1 | ADR-020, TDD §5.3 |
| TC-INT-032 | Recuperación tras restauración | BD restaurada a T-1h con eventos PUBLICADO < 24 h | Procedimiento post-restauración | PUBLICADO recientes →`PENDIENTE` para reproceso; consumidores idempotentes absorben duplicados | P1 | TDD §5.3, DEC-012 |

### 5.5 Catálogo — idempotencia (`idempotency_keys`)

| ID | Alcance | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-INT-033 | Ciclo completo | Clave nueva | POST con `Idempotency-Key` K (cuerpo B): commit exitoso; repetir K+B | 1ª: fila `EN_PROCESO`→`COMPLETADA` antes de COMMIT con respuesta guardada (hash SHA-256 de B); 2ª: devuelve la respuesta guardada sin nuevo efecto secundario | P0 | SAD §10.6, ADR-DATA-19 |
| TC-INT-034 | Clave reutilizada | K asociada a cuerpo B | POST K con cuerpo B′ ≠ B | Error de dominio → `409 IDEMPOTENCY_KEY_REUSED`; sin efecto | P0 | TEC-003 |
| TC-INT-035 | Fallo pre-commit | Clave en `EN_PROCESO` | Forzar error de negocio y rollback; repetir petición | La clave hizo rollback junto a la transacción; el reintento ejecuta la operación completa | P0 | TDD §5.1 |
| TC-INT-036 | TTL 24 h | K COMPLETADA hace 25 h (UPDATE directo de fecha) | POST K+B de nuevo | Clave vencida no bloquea; se ejecuta nueva operación con nueva fila | P1 | SAD §10.6 |
| TC-INT-037 | Alcances de clave | K bajo principal USER vs MAGIC_LINK; y organización distinta | Reutilizar K cambiando principal/tenant | No colisionan (unicidad `(organization_id, principal_type, principal_id, operation, idempotency_key)` + parciales global); cada alcance opera independiente | P1 | TDD §5.1 |

### 5.6 Catálogo — jobs BullMQ, colas y proyecciones

| ID | Alcance | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-INT-038 | 12 jobs (parametrizado) | Datos sembrados por job con su condición de disparo (tabla de fixtures por job) | Ejecutar cada job con su nombre exacto: «Expiración de SLA», «Inicio de servicio» (hora **local** del evento), «Cancelación sin respuesta» (72 h), «Cierre automático» (5 días), «Recordatorio de evento próximo», «Aviso de calificación» (ventana 30 días), «Borradores inactivos» (83/90 días), «Expiración de invitaciones y transferencias», «Vencimiento de plan» (solo lectura operativa), «Purga por retención» (respeta `legal_holds` y registra en `retention_executions`), «Vencimiento de ofertas» (+`RESPONDIDO`→`NO_ADJUDICADO` por DEC-035), «Plazo de revisión por suspensión» (marca caso; no cambia estado) | Cada job produce exactamente las transiciones/eventos especificados en SAD §8.2 y nada más; índices parciales de soporte usados (evidencia `EXPLAIN`) | P0 | SAD §8.2, TDD §10.3 |
| TC-INT-039 | Job tardío | Solicitud ya en terminal; job encolado con retraso | Ejecutar job sobre estado terminal | No muta estados terminales (idempotente por estado persistido); única excepción DEC-035 sobre RESPONDIDO aplicada solo con SLA vencido y sin oferta vigente | P0 | SAD §8.4 |
| TC-INT-040 | Lote de emails | Ronda de 5 solicitudes; MSW: SendGrid falla solo para el proveedor 3 | Worker despacha el lote | 4 enviados; el 3º → `ERROR_ENVIO` con reintento (backoff, máx 3) sin afectar al resto; fallo de email no revierte negocio | P0 | SRS-RFQ-003, SAD §8.3 |
| TC-INT-041 | Persistencia de colas | Jobs pendientes en Redis | Reiniciar contenedor Redis y worker | Jobs pendientes se recuperan (AVL-005); publicador usa `FOR UPDATE SKIP LOCKED` con contexto de tenant fijado **antes** de bloquear (RLS) | P1 | AVL-005, TDD §5.1 |
| TC-INT-042 | Verificaciones de mantenimiento | Drift simulado: `consumed` del contador ≠ suma de `booking_consumed_dates` activas | Ejecutar verificaciones `maintenance` (REPEATABLE READ) | Detecta y reporta: deriva de capacidad, contadores de plan, referencias huérfanas, incoherencia `tracking_status` vs contratación, rondas sin cerrar, despacho estancado > 10 min | P0 | TDD §5.3 |
| TC-INT-043 | Proyecciones reconstruibles | Eventos históricos de proveedores | Reconstruir `ProviderSearch` y `ProviderReputation` desde eventos | Resultado idéntico al incremental (hash comparado); sin IDs de tenant como etiquetas de alta cardinalidad | P1 | ADR-020, ADR-DATA-018 |
| TC-INT-044 | Aislamiento de exportación | Exportación de comisiones en curso + inserción concurrente | `exportCommissions` con `REPEATABLE READ` | Snapshot consistente: el export no ve la inserción concurrente; sin filas duplicadas | P2 | TDD §5.1 |

### 5.7 Catálogo — adaptadores externos con stubs wire-level (MSW)

| ID | Adaptador | Escenario | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-INT-045 | SendGrid | Envío OK; 500 temporal; 400 permanente | OK → `delivery_attempt` con `provider_message_id`; 500 → reintento backoff; 400 → `FALLIDO` sin reintentos y **sin revertir** el negocio | P0 | SRS-NOT-001/005, TDD §5.6 |
| TC-INT-046 | SendGrid webhook | `receiveSendgridEvents` con evento válido, duplicado y sin registro previo | Firma verificada (detalle de seguridad en TC-SEC); `email_webhook_events` insertado; `dispatch_status` actualizado; duplicado por `sg_event_id` ignorado; `EmailDeliveryStatusChanged` solo para eventos conocidos | P0 | SRS-NOT-006, ADR-API-008 |
| TC-INT-047 | Cloudinary | Firma de subida + registro + purga | `createMediaUploadSignature` emite firma con scope del proveedor; `registerMedia` valida magic bytes/tamaño (éxito y rechazo); purga a 30 días (BD+Cloudinary stub) | P1 | SRS-CAT-002, TDD §5.6 |
| TC-INT-048 | Auth0 (JWKS stub) | Token válido, con firma inválida, issuer/audience erróneos, expirado | Solo el válido autentica; `auth_subject` vinculado a `users`; email tomado del token verificado (TEC-007) | P0 | SRS-AUTH-003, DEC-017 |
| TC-INT-049 | PDF (React-PDF) | Cotización snapshot con 30 ítems y caracteres españoles | Documento generado desde snapshot (DEC-016); job `documents` `PENDIENTE`→`COMPLETADO`; saltos de página y acentos correctos; p95 < 5 s se valida en carga (Sección 11) | P1 | SRS-QUO-011, DEC-016 |

### 5.8 Pruebas de arquitectura y cumplimiento de ADRs (`TC-ARCH`)

Reglas automatizadas con dependency-cruiser + Vitest (`tests/architecture`, ADR-TEST-001); **cada regla se acompaña de un fixture inválido que falla y un válido que pasa; la suite falla si analiza cero archivos.** Hogar de esta categoría dentro de la Sección 5 por decisión DT-08 (misma etapa de CI que integración).

| ID | Regla ADR | Aserción (el build falla si…) | Prio | Trazabilidad |
|---|---|---|---|---|
| TC-ARCH-001 | ADR-ARCH-002 | `domain` importa Express, Prisma, Redis, `pg` o SDK externo | P0 | SAD §4.3 |
| TC-ARCH-002 | ADR-ARCH-007 | `http` contiene lógica de negocio o accede a Prisma directamente (debe llamar a casos de uso) | P0 | SAD §4.3 |
| TC-ARCH-003 | ADR-ARCH-005 | Un módulo accede a tablas internas de otro (repositorio ajeno) | P0 | SAD §4.4 |
| TC-ARCH-004 | ADR-ARCH-003 | Arista de dependencia no listada en la matriz §4.4 o ciclo entre módulos | P0 | SAD §4.4 |
| TC-ARCH-005 | ADR-DATA-006 | `application` invoca adaptador externo (Auth0/SendGrid/Cloudinary/Maps) o Redis directamente en lugar del puerto Outbox | P0 | SAD §7.4 |
| TC-ARCH-006 | ADR-DATA-005 | Llamada externa, encolado BullMQ, escritura Redis o generación de PDF dentro de los límites de una transacción (análisis estático del patrón `withTransaction`) | P0 | TDD §5.1 |
| TC-ARCH-007 | ADR-API-001 | Endpoint HTTP sin caso de uso correspondiente trazable por `operationId` | P1 | SAD §10 |
| TC-ARCH-008 | DEC-022 | Enum de Prisma divergente del catálogo SRS/OpenAPI (generador de comparación) | P1 | DEC-022 |
| TC-ARCH-009 | ADR-GOV-003 | Presencia de `.skip/.only/.todo/xit/xdescribe` o directivas de supresión de cobertura en `tests/**` o `src/**` | P0 | ADR-TEST-006 |
| TC-ARCH-010 | ADR-TEST-006 | Cobertura total por debajo de `main` (job de comparación) | P0 | ADR-TEST-006 |
| TC-ARCH-011 | ADR-DATA-010 | SQL dinámico con concatenación de strings en `$queryRaw` (debe ser template parametrizado) | P0 | ADR-DATA-010 |
| TC-ARCH-012 | ADR-TEST-001 | dependency-cruiser analiza 0 archivos (falla por defecto) o una regla sin sus 2 fixtures (inválido/válido) | P0 | ADR-TEST-001 |

**Criterio de aceptación de la suite:** 100% de los casos contra PostgreSQL/Redis reales; cada rechazo de BD asertado por SQLSTATE; cada flujo F1–F11 con verificación de efecto en ≥ 3 tablas + evento Outbox; `retry:0`.

## Sección 6 — Pruebas de API y Contrato (`TC-API`)

### 6.1 Alcance y método

* **Alcance exacto:** comportamiento HTTP de las 151 operaciones de `ProveeEventos_API_Spec.yaml` (v1.4.0, ~123 paths bajo `/api/v1`): compliance de esquemas de request/response, códigos de estado, formato de errores, cabeceras (`X-Organization-Id`, `Idempotency-Key`, `ETag`/`If-Match`, `X-Correlation-Id`), paginación, webhooks y endpoints públicos.
* **Método:** Supertest contra la app Express montada sin red (DT-02); cada respuesta se valida contra el esquema OpenAPI declarado con `openapi-response-validator` (incluye `allOf` y `unevaluatedProperties:false` de los esquemas `*Fields` de TEC-013). El contrato fuente se mantiene validado con `python3 -I Tools/check_openapi.py` (refs, operationId, 4xx, Idempotency-Key) en CI.
* **Presupuesto:** suite completa ≤ 6 min en CI (PR Required Check).

### 6.2 Catálogo — contrato, errores y health

| ID | Alcance | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-API-001 | Compliance de esquemas | Contrato v1.4.0 cargado | Para cada operación con respuesta declarada (generador parametrizado sobre las 151): payload de ejemplo válido e inválido | 2xx/4xx validan contra esquema (incl. `allOf`, `unevaluatedProperties:false`); un campo extra no declarado en request → `400 VALIDATION_FAILED` | P0 | ADR-API-001/002, UXUI QA-15 |
| TC-API-002 | Matriz ErrorCode→HTTP | — | Provocar cada uno de los 20 `ErrorCode` (tabla normativa abajo) | HTTP exacto y `code` exacto por cada uno: 400 `VALIDATION_FAILED`, `ORGANIZATION_REQUIRED` · 401 `UNAUTHENTICATED` · 403 `FORBIDDEN` · 404 `NOT_FOUND`, `MAGIC_LINK_INVALID` · 409 `CAPACITY_EXHAUSTED`, `AWARD_ALREADY_EXISTS`, `OFFER_NOT_AWARDABLE`, `OFFER_EXPIRED`, `RFQ_NOT_OPEN`, `SLA_EXPIRED`, `INVALID_STATE_TRANSITION`, `IDEMPOTENCY_KEY_REUSED`, `PLAN_LIMIT_REACHED`, `ASSISTED_RESPONSE_MISMATCH` · 412 `PRECONDITION_FAILED` · 429 `RATE_LIMITED` · 503 `DEPENDENCY_UNAVAILABLE` · 500 `INTERNAL_ERROR` | P0 | SAD §10.6, TEC-011 |
| TC-API-003 | Formato `problem+json` | Error cualquiera | Inspeccionar cuerpo de 4xx/5xx | `Content-Type: application/problem+json`; campos `type,title,status,code,correlationId` presentes; `ValidationError` añade `fieldErrors[{field,message}]`; 5xx **sin stack trace** ni detalles internos; `correlationId` del cuerpo = cabecera de respuesta | P0 | SAD §10.6, RFC 9457 |
| TC-API-004 | Health operativos | PG y Redis accesibles; luego PG detenido (fallo inyectado) | `GET /health/live` y `GET /health/ready` | `live` 200 siempre que el proceso viva; `ready` 200 con deps y **503** con PG/Redis caídos (para que el balanceador retire la réplica); ambos sin auth, fuera de `/api/v1`, sin detalles internos | P1 | SAD §10.8 |

### 6.3 Catálogo — autenticación y contexto de tenant

| ID | Alcance | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-API-005 | Autenticación | Llamadas con: sin token; token con firma inválida; expirado; issuer/audience incorrectos; y sin token a las 9 operaciones públicas (catálogo, disponibilidad pública, planes, magic links, webhook) | Los 5 casos inválidos → `401 UNAUTHENTICATED` en operaciones protegidas; las 9 públicas no responden `401 UNAUTHENTICATED` (el webhook sigue exigiendo su firma) | P0 | TEC-007, DEC-017 |
| TC-API-006 | `X-Organization-Id` | Usuario con 2 membresías sin cabecera; con cabecera de organización sin membresía activa; con 1 sola membresía sin cabecera | 2 membresías sin cabecera → `400 ORGANIZATION_REQUIRED`; organización ajena → `403 FORBIDDEN` (no 404, es un contexto inválido); 1 membresía sin cabecera → resuelve implícito | P0 | TEC-006, SRS-AUTH-010 |

### 6.4 Catálogo — `Idempotency-Key`

| ID | Alcance | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-API-008 | Obligatoriedad | POST sin `Idempotency-Key` en una de las 47 operaciones que la exigen (muestreo cubre las 47 por generador); y con clave de longitud 15/129 | `400 VALIDATION_FAILED` en ambos casos | P0 | SAD §10.6, TEC-003 |
| TC-API-009 | Reintento idéntico | POST éxito con clave K; repetir K + mismo cuerpo | Mismo código de éxito y **mismo** identificador de recurso (respuesta guardada); un solo recurso en BD (equivalente API del ciclo completo de la sección 5.5) | P0 | TEC-003 |
| TC-API-010 | Clave reutilizada | Misma K con cuerpo distinto | `409 IDEMPOTENCY_KEY_REUSED` | P0 | TEC-003 |
| TC-API-011 | Exenciones | Llamar sin cabecera a: `createMediaUploadSignature`, `buildWhatsappClickToChat`, `createAssistedResponsePrompt`, `validateAssistedResponse`, `markNotificationRead`, `receiveSendgridEvents`, `getMagicLinkForm` | Todas aceptan sin `Idempotency-Key` (exención documentada en la operación; cualquier otra operación sin cabecera falla) | P1 | TEC-011 |

### 6.5 Catálogo — concurrencia optimista (`ETag`/`If-Match`) y paginación

| ID | Alcance | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-API-012 | `If-Match` requerido | PATCH sin `If-Match` y con `If-Match` desactualizado sobre `updateMyProvider`, `updatePackage`, `setProviderAvailability`, `updateEventTemplate`, `updateEvent`, `updateQuotationSelections` (parametrizado) | Ambos casos → `412 PRECONDITION_FAILED` (comportamiento fijado por el YAML v1.4.0; se aserta contra el contrato) | P0 | TEC-011, ADR-API-005 |
| TC-API-013 | Flujo ETag completo | GET detalle (captura ETag) → PATCH con `If-Match` vigente → PATCH concurrente con ETag viejo | GET expone `ETag`; 1º PATCH 200 y `version+1`; 2º PATCH 412 | P0 | TEC-011 |
| TC-API-014 | Paginación por página | `listEvents`/`listBookings`/`listQuotations` con `page/pageSize`; `pageSize=101` | `PageMeta{page,pageSize,totalItems,totalPages}` presente; `pageSize>100` → 400 | P1 | TEC-012 |
| TC-API-015 | Paginación por cursor | `searchProviders`/`listProviderReviews`/`listNotifications`/`searchAuditLogs` con `cursor/limit`; `limit=51`; recorrer hasta el final | `CursorPageMeta{limit,nextCursor\|null}`; `limit>50` → 400; cursor opaco estable ante inserciones concurrentes (mismo resultado al re-paginar) | P1 | TEC-012 |
| TC-API-016 | Mezcla de modelos | `searchProviders?cursor=…&page=1` | `400 VALIDATION_FAILED` (un solo modelo por operación) | P1 | TEC-012 |

### 6.6 Catálogo — operaciones críticas (códigos por operación)

| ID | Operación | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-API-018 | `createInstantBooking` | Éxito; sin cupo; ítem ya contratado; sin clave de idempotencia | `200` con booking; `409 CAPACITY_EXHAUSTED`; `409 INVALID_STATE_TRANSITION` (última barrera `uq_bookings__active_item`); `400` sin cabecera | P0 | SRS-BOOK-001/004, SAD §7.1 |
| TC-API-019 | `awardRfqOffer` | Éxito; ya adjudicado; oferta no adjudicable; oferta vencida; sin capacidad; `COORDINADOR_RESTRINGIDO` | `200`; `409 AWARD_ALREADY_EXISTS`; `409 OFFER_NOT_AWARDABLE`; `409 OFFER_EXPIRED`; `409 CAPACITY_EXHAUSTED` (sin ganador creado); `403 FORBIDDEN` | P0 | SRS-RFQ-009, SAD §7.2 |
| TC-API-020 | `createRfqCycle` | 5 proveedores + SLA 48; 6 proveedores; SLA 36 | `202` con RfqBatch; `400` por cupo > 5; `400` por SLA fuera de {6,12,24,48} | P0 | SRS-RFQ-001/004 |
| TC-API-021 | `submitMagicLinkResponse` | Token válido; usado; expirado; revocado; desconocido; reintento con misma clave tras fallo de red | Válido → `201` oferta; los 4 estados inválidos y el desconocido → **idéntico** `404 MAGIC_LINK_INVALID` (no se distingue); `Cache-Control: no-store` y `Referrer-Policy: no-referrer` en **todas** las respuestas (incluidos errores y 429); reintento con misma clave no duplica oferta | P0 | SAD §7.3, SRS-MAGIC-003 |
| TC-API-022 | `getMagicLinkForm` | Token ACTIVO; inválido | ACTIVO → snapshot del formulario (no consume el grant); inválido → `404 MAGIC_LINK_INVALID`; cabeceras `no-store`/`no-referrer` | P0 | SRS-MAGIC-002/005 |
| TC-API-023 | `receiveSendgridEvents` | Firma ausente; firma inválida; timestamp fuera de tolerancia; firma válida; ráfaga > umbral | 3 primeros → `401`; válido → aceptado y persistido; ráfaga → `429 RATE_LIMITED` con `Retry-After` | P0 | ADR-API-008, SRS-NOT-006 |
| TC-API-024 | `transitionEventStatus`/`updateEvent` | Transición inválida (`COMPLETADO→EN_PROGRESO`); edición con ETag viejo | `409 INVALID_STATE_TRANSITION`; `412 PRECONDITION_FAILED` | P1 | SRS-EVT-006/008 |
| TC-API-025 | `createReview` | Booking no COMPLETADO; fuera de ventana 30 días; duplicada; reporte con motivo de enum | `409` en los 3 primeros (con `code` correcto); reporte aceptado solo con motivos {OFENSIVO, FALSO, DATOS_PERSONALES, OTRO} | P1 | SRS-REV-001/004/008, DEC-030 |
| TC-API-026 | Registros | `registerOrganization`/`registerProvider` sin email verificado; NIT ya registrado | Rechazo por verificación TEC-007; NIT duplicado → conflicto (invariante de unicidad normalizada) | P1 | TEC-007, SRS-AUTH-001/002 |
| TC-API-027 | Límites de plan | Plan PRUEBA con límites agotados | `createEvent`/`createQuotation`/invitación extra → `409 PLAN_LIMIT_REACHED`; compromisos existentes operan con normalidad; `getPlanUsage` refleja contadores | P0 | SRS-TEN-003/004, DEC-029 |
| TC-API-028 | Admin (BFLA, vista contrato) | Rol `COORDINADOR` y `PROVEEDOR` contra `/admin/*` (muestreo de 30 operaciones) | `403 FORBIDDEN` siempre; solo `ADMIN_PLATAFORMA` accede | P0 | SRS-ADM-*, matriz UXUI §3.2 |
| TC-API-029 | Errores de validación por campo | POST crítico con 3 campos inválidos (`createEvent`, `createPackage`) | `400` + `ValidationError.fieldErrors` con una entrada por campo; no se borra lo escrito (payload eco completo no requerido, se valida contrato) | P1 | SRS-NFR-USA-006 |
| TC-API-030 | Exportaciones | `exportCommissions`/`exportSubscriptions` como AP; como AE | AP → stream/CSV correcto (encabezados y totales coherentes con listCommissions); AE → `403` | P1 | SRS-ADM-008, DEC-033 |

### 6.7 Catálogo — públicos, contacto y contexto de negocio

| ID | Operación | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-API-031 | Catálogo público sin contacto | `listCategories`/`searchProviders`/`getPublicProvider` anónimo | 200 sin teléfono, WhatsApp, email ni identificación fiscal en el payload (escaneo de claves y valores) | P0 | UXUI QA-09, DEC-028, PRIV-005 |
| TC-API-032 | Disponibilidad pública | `getPublicProviderAvailability` anónimo | Solo estados `DISPONIBLE`/`SIN_CAPACIDAD` (nunca `DESCONOCIDA`), ventana de 62 días; `429` bajo ráfaga | P1 | TEC-013, SRS-CAT-009 |
| TC-API-033 | Contacto tras reserva | `getBookingProviderContact` como organizadora de booking `CANCELADO`/`NO_PRESTADO`; como tercero | Partes legítimas → contacto; booking cerrado sin derecho o tercero → `404/403` (gate DEC-028, auditado) | P0 | DEC-028, SRS-CAT-015 |
| TC-API-034 | Click-to-Chat | `buildWhatsappClickToChat` sobre solicitud ENVIADO del tenant; sobre solicitud ajena | URL `wa.me` con texto renderizado determinista de la plantilla; solicitud ajena → `404`; acceso auditado | P1 | SRS-WA-003, DEC-028 |
| TC-API-035 | Alternativas | `listRfqAlternatives` tras rechazo/vencimiento | Alternativas elegibles **sin** datos de las ofertas competidoras | P1 | SRS-RFQ-010, RF-BID-04 |
| TC-API-036 | Bid Tabulation | `getBidTabulation` de ítem con 3 ofertas | Comparación homogénea: precio firme, extras, origen, vigencia normalizados; ofertas `VENCIDA` marcadas no adjudicables; solo miembros del tenant | P0 | SRS-RFQ-008/012 |
| TC-API-037 | Documentos | `requestQuotationPdf` → `getDocument` hasta completar; `getDocument` de otro tenant | Job con estado (`PENDIENTE`→`COMPLETADO`) y URL firmada solo al dueño; documento ajeno → `404` | P1 | SRS-QUO-011 |
| TC-API-038 | Superficie de API | Rutas no documentadas; métodos no declarados | `404` sin filtrar stack/rutas (sin enumeración de superficie); versión única `/api/v1` | P1 | ADR-API-001 |
| TC-API-039 | Correlación | Request con `X-Correlation-Id` propio y sin él | Respuesta eco del ID recibido o nuevo generado; presente en `problem+json` y logs del request de prueba | P1 | SRS-NFR-OBS-001 |
| TC-API-040 | Optimismo punta a punta | Dos PATCH concurrentes de `updateQuotationSelections` con el mismo ETag inicial | Exactamente 1 → 200; el otro → `412`; versión final = inicial+1 | P0 | TEC-011, SRS-QUO-007 |

**Matriz normativa ErrorCode→HTTP (fuente SAD §10.6 / YAML v1.4.0 — especificación parametrizada por el caso de matriz de §6.2):** `VALIDATION_FAILED` 400 · `ORGANIZATION_REQUIRED` 400 · `UNAUTHENTICATED` 401 · `FORBIDDEN` 403 · `NOT_FOUND` 404 · `MAGIC_LINK_INVALID` 404 · `CAPACITY_EXHAUSTED` 409 · `AWARD_ALREADY_EXISTS` 409 · `OFFER_NOT_AWARDABLE` 409 · `OFFER_EXPIRED` 409 · `RFQ_NOT_OPEN` 409 · `SLA_EXPIRED` 409 · `INVALID_STATE_TRANSITION` 409 · `IDEMPOTENCY_KEY_REUSED` 409 · `PLAN_LIMIT_REACHED` 409 · `ASSISTED_RESPONSE_MISMATCH` 409 · `PRECONDITION_FAILED` 412 · `RATE_LIMITED` 429 · `DEPENDENCY_UNAVAILABLE` 503 · `INTERNAL_ERROR` 500.

## Sección 7 — Pruebas End-to-End y Accesibilidad (`TC-E2E`)

### 7.1 Alcance, reglas anti-flakiness y convenciones

* **Alcance exacto:** los **12 escenarios de aceptación de SRS §8** (obligatorios: SRS §14.5 "los escenarios de §8 se convierten en pruebas E2E identificadas por número de sección") + flujos críticos F-01..F-08 de UXUI §3.3 + accesibilidad (WCAG 2.1 AA) + responsive. Cada caso ejecuta en navegador real contra un ambiente efímero con datos del worker.
* **Selectores resilientes (UXUI §11.5):** `data-testid="scr-NNN"` y `scr-NNN-<elemento>`; preferencia `getByRole`/`getByLabel`; prohibidos selectores CSS frágiles y de texto puro.
* **Anti-flakiness:** prohibido `waitForTimeout`/`sleep`; solo auto-waiting y esperas de condición (red, elemento visible, estado de API); `retries: 0` (AS-07); datos aislados por worker con sufijo `-w[N]`; sin dependencia del orden de ejecución.
* **Viewports:** matriz obligatoria 360×640 (móvil, mínimo soportado) y 1280×800 (desktop UXUI QA-02); 768 opcional para el comparador de 3 columnas. **Browsers:** Chromium (siempre); WebKit para SCR-012 (móvil real); Firefox en pipeline de a11y manual (NVDA).
* **Presupuesto:** smoke de 12 escenarios SRS §8 en PR ≤ 10 min (Chromium); suite completa (todos los casos, 2 viewports) ≤ 45 min en post-merge/nightly.

### 7.2 Catálogo — 12 escenarios SRS §8 (identificados por número de sección)

| ID | Escenario SRS | Recorrido y pantallas | Aserciones E2E clave | Prio |
|---|---|---|---|---|
| TC-E2E-001 | §8.1 Registro y aprobación de proveedor | SCR-005→007→008→042 (completitud)→048 enviar→056 decidir | Tras VERIFICADO, proveedor visible en SCR-002; RECHAZADO habilita corrección y reenvío; emails recibidos (stub de bandeja) | P0 |
| TC-E2E-002 | §8.2 Cotización integral con plantilla | SCR-013→015 (wizard 3 pasos)→021 (TOP 3 preseleccionado)→022 (PDF) | Totales iguales en pantalla y PDF; F-02 completada en ≤ 7 clics (contador de interacciones, QA-04) | P0 |
| TC-E2E-003 | §8.3 Reserva Instant Book (última plaza) | SCR-021→023 con dos pestañas simultáneas | 1 pestaña confirma; la otra muestra estado de capacidad agotada (`CAPACITY_EXHAUSTED`); sin doble booking visible; doble click rápido en "Reservar" crea 1 sola reserva (la UI repite la misma `Idempotency-Key`, QA-05) | P0 |
| TC-E2E-004 | §8.4 e-RFQ por email | SCR-024 (5 proveedores + SLA)→correo con `/r#token`→SCR-012→respuesta→SCR-025→adjudicación | Fragmento desaparece tras cargar; formulario móvil operable; oferta reflejada en Bid Tabulation; adjudicación crea contratación visible en SCR-028/052 | P0 |
| TC-E2E-005 | §8.5 Respuesta por WhatsApp asistida | SCR-026 (wa.me)→SCR-027 (pegar respuesta→prompt→JSON→validar loop)→confirmar | JSON inválido muestra error sin perder datos; confirmación humana obligatoria; oferta con origen WHATSAPP_IA_ASISTIDO en SCR-025 | P1 (E2) |
| TC-E2E-006 | §8.6 Calificación post-evento | SCR-029→031 (4 dimensiones + texto 500)→053 (respuesta proveedor 300) | Promedio reflejado en SCR-003; segunda reseña bloqueada en UI | P1 |
| TC-E2E-007 | §8.7 Respuesta tardía al SLA | SCR-012 con enlace expirado | Estado explícito de expiración (no error genérico); sin formulario editable; token invalidado | P0 |
| TC-E2E-008 | §8.8 Cancelación sin respuesta en 72 h | SCR-029 solicitar cancelación→sin respuesta→72 h (reloj avanzado en ambiente) | Estado `CANCELACION_EN_REVISION` visible para ambas partes; capacidad no liberada (calendario SCR-047 sigue ocupado) | P0 |
| TC-E2E-009 | §8.9 Cancelación disputada | SCR-052 disputar→SCR-062 admin resuelve | Resolución de administración refleja estado final en SCR-029/052 y comisión (SCR-063) | P0 |
| TC-E2E-010 | §8.10 Límite de plan a mitad del flujo | SCR-024 o SCR-015 con plan agotado | Mensaje `PLAN_LIMIT_REACHED` en punto exacto; flujo anterior no se pierde (borrador persiste); SCR-038 muestra consumo | P1 |
| TC-E2E-011 | §8.11 Servicio multi-día cruce de medianoche | SCR-021 ítem vie 20:00→sáb 03:00 y variante vie 18:00→dom 14:00 | Calendario SCR-047 muestra "usados/capacidad" correctos por fecha (1 fecha vs 3 fechas); comparador SCR-025 refleja vigencia | P0 |
| TC-E2E-012 | §8.12 Suspensión con contrataciones futuras | SCR-056 suspender→SCR-052 futura en revisión→SCR-030 decidir→SCR-062 sin decisión | Proveedor suspendido (SCR-042/052) conserva solo consulta y acciones de ciclo; RFQ abiertas canceladas; reviewDecisionDueAt visible | P0 |

### 7.3 Catálogo — flujos UXUI complementarios

| ID | Flujo | Recorrido | Aserciones E2E clave | Prio |
|---|---|---|---|---|
| TC-E2E-013 | F-01 Descubrimiento público | SCR-001→002 (filtros en URL compartible)→003→005 con `returnTo`→selección a ítem | Al volver del login regresa al punto de origen; sin contacto visible en SCR-002/003 (QA-09); ordenamiento persiste en URL | P1 |
| TC-E2E-014 | F-03 e-RFQ punta a punta con cierre | Continúa desde la adjudicación: SERVICIO_REALIZADO por proveedor (SCR-052)→confirmación organizador (SCR-029)→calificación (SCR-031) | Journey completo con estados correctos en ambas vistas; comisión visible en SCR-063 como DEVENGADA; trazas correlacionadas (correlationId único por flujo) | P0 |
| TC-E2E-015 | F-08 Alta de empresa e invitación | SCR-006→008→013→036 invitar→correo `/invitacion#token`→SCR-009→010 (multi-empresa)→013 | Invitación con token en fragmento; aceptación activa membresía; OrgSwitcher propone selector con 2+ empresas | P0 |
| TC-E2E-016 | Transferencia de propiedad (E2) | SCR-037 iniciar→autenticación reforzada→destinatario acepta | Único PROPIETARIO garantizado en toda la transición (UI bloquea acciones del antiguo); historial visible | P1 (E2) |
| TC-E2E-017 | Notificaciones y preferencias | SCR-039 marcar leída→040 ajustar preferencias→evento que genera notificación desactivada | Badge/leído persistente; canal desactivado no recibe (bandeja stub); preferencias por categoría respetadas | P1 |
| TC-E2E-018 | Magic Link móvil real | SCR-012 en WebKit viewport 360 | Mobile-first operable; borrador solo en memoria (sin `localStorage`); `beforeunload` advierte; sin recursos de terceros ni analítica; reintento de red reutiliza la misma `Idempotency-Key` con aviso "no se duplicará" | P0 |
| TC-E2E-019 | Responsive global | SCR-002/018/025 a 360 y 1280 | Sin scroll horizontal a 360 (QA-03); tablas→tarjetas < 768; comparador 2 columnas a 360 y 3 a ≥ 768; áreas táctiles ≥ 44 px | P0 |
| TC-E2E-020 | Organización activa | SCR-010/`OrgSwitcher` cambiar de empresa | Tras cambiar: datos solo de la empresa activa (verificación de ausencia de datos de la anterior en toda la app); caché vaciada; ruta actual a `/app` | P0 |

### 7.4 Catálogo — accesibilidad (WCAG 2.1 AA) y estados de UI

| ID | Alcance | Entrada / Acción | Resultado esperado | Prio | Fuente |
|---|---|---|---|---|---|
| TC-E2E-021 | axe-core automatizado | `@axe-core/playwright` sobre SCR-001,002,012,015,021,025,029,050 en 360 y 1280, con estados cargando/vacío/error | **0 violaciones serious/critical** por pantalla/estado (DT-12); violaciones minor reportadas sin bloquear | P0 | UXUI §8.5, QA-02, SRS-NFR-USA-008 |
| TC-E2E-022 | Teclado | Recorrer F-02 solo con teclado; abrir diálogos/drawer; errores de formulario | Foco visible (anillo ≥ 3:1); sin trampas de tab; foco atrapado con Escape y restauración; tras error, foco en `ErrorSummary` con `aria-describedby`; skip-link operativo; atajos solo `/` y `F6` | P0 | UXUI §8.1/8.2 |
| TC-E2E-023 | Estados de UI (QA-01) | Forzar vacío/error/5xx/sin permiso en SCR muestreadas (API simulada) | Estados explícitos de §10.4; banner 5xx muestra `correlationId` copiable; sin pantalla en blanco; `StatusBadge` con valor desconocido → neutral con valor crudo | P1 | UXUI QA-01, CMP-44/45 |
| TC-E2E-024 | RBAC en UI (QA-10) | URL directa de SCR restringida con cada rol de la matriz §3.2 (incl. `COORDINADOR_RESTRINGIDO` con evento ajeno) | `ErrorState forbidden`/404 según mapa; acciones de adjudicación/cancelación ausentes para CR; sin datos filtrados en DOM | P0 | UXUI QA-10, DEC-011 |
| TC-E2E-025 | Percepción y movimiento | `prefers-reduced-motion` activo; par de contraste de foco sobre escenario amarillo | Animaciones reducidas; `focus-ring-stage` cumple contraste (13.64:1 declarado); color nunca único (badges con icono+texto, calendario con patrón); nada parpadea > 3 Hz | P1 | UXUI §8.4, QA-11/12 |
| TC-E2E-026 | Rendimiento percibido | Lighthouse CI sobre SCR-001/002 (móvil 4G emulado) | LCP p75 < 2 s móvil y < 1,5 s desktop (SRS-NFR-PERF-001, QA-13) | P1 | SRS-NFR-PERF-001 |
| TC-E2E-027 | Aviso de sesión | Sesión a 2 minutos de expirar (24 h inactividad simulada) | Aviso visible con "Seguir conectado"; al expirar, `ErrorState expired` con datos intactos tras re-login | P2 | UXUI §8.4, DEC-017 |
| TC-E2E-028 | A11y manual (asistida) | Recorrido con NVDA+Firefox y VoiceOver+iOS de SCR-012,015,021,025,029,050 | Checklist §8.5 sin bloqueos: regiones live, `timer` SLA anunciado, `lang="es-CO"`, un h1, nombres accesibles con texto visible (2.5.3), zoom 200% usable | P0 (release) | UXUI §8.3/8.5 |

**Criterio de aceptación de la suite:** los 12 escenarios SRS §8 pasan en Chromium en cada PR (smoke); suite completa verde en post-merge; cero violaciones serious/critical de axe; cero `waitForTimeout` (verificado por regla ESLint sobre `tests/e2e/**`).

## Sección 8 — Pruebas de Aislamiento Multi-Tenant (`TC-MT`)

### 8.1 Mecanismo bajo prueba (reconciliado de TDD §5.2 y `proveeeventos.sql` migración `20_rls`)

* **Aislamiento primario** en casos de uso/repositorios: `organization_id` obligatorio en toda lectura/escritura empresarial; **defensa en profundidad**: PostgreSQL RLS con `ENABLE`+`FORCE ROW LEVEL SECURITY` en **39 tablas clase (a)**; contexto por `set_config(..., true)` con scope de transacción: `app.organization_id`, `app.provider_id`, `app.user_id`, `app.platform_admin`, `app.magic_token_hash`, `app.invitation_token_hash`.
* **Fail-closed garantizado:** las políticas leen las variables con funciones `STABLE` (`fn_current_organization_id()` y análogas) que convierten vacío en nulo → **sin contexto no hay filas visibles ni escribibles**. Ningún rol de ejecución (`pe_api`, `pe_worker`, `pe_readonly`, `pe_retention`, `pe_migrator`, `pe_owner`) tiene `BYPASSRLS`.
* **Perfiles de política:** RLS-A (tenant puro), RLS-B (dos partes: organización **o** proveedor, con `magic_link_grants` exige además `token_hash` del contexto), RLS-C (plantillas globales/de empresa), RLS-D (membresías/invitaciones con token), RLS-E (reseñas públicas `VISIBLE`), RLS-F (reportes del propio reporter), RLS-G (avisos por usuario/organización), RLS-H (auditoría: solo `ADMIN_PLATAFORMA` lee, nadie edita).
* **Regla de cobertura (DT-10):** los 7 patrones de §8.3 se **generan parametrizados por tabla** desde la clasificación del TDD §4.2; una tabla clase (a) nueva sin su caso generado **rompe la suite** (test de cobertura de la propia clasificación).
* **Configuración CI obligatoria (ADR-TEST-004):** la suite corre con RLS **activa** y rol `pe_api` (no superusuario, no `pe_owner`), dos tenants sembrados A/B con datos espejo (mismos UUID-v5 derivados por tenant, perfiles isomorfos) para detectar confusión de identidad.

### 8.2 Catálogo — canal API (matriz Tenant A vs. Tenant B, usuarios reales con sesión)

| ID | Canal | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-MT-001 | API lectura | Recurso de B (evento, cotización, booking, RFQ, documento) con UUID conocido por A | `GET` por UUID exacto con sesión de A | `404 NOT_FOUND` (nunca 403 que revelaría existencia, nunca el recurso) | P0 | ADR-TEST-004, SRS-TEN-001 |
| TC-MT-002 | API listado | B tiene ≥ 3 recursos del tipo | `GET` listado como A (page y cursor) | 0 filas de B en cualquier página/cursor; metadatos de paginación solo cuentan filas de A | P0 | SRS-TEN-001 |
| TC-MT-003 | API escritura | Recurso de B | `PATCH`/acción de escritura (editar evento, paquete, disponibilidad) desde A | `404`; recurso de B intacto (verificación en BD posterior) | P0 | SRS-TEN-001 |
| TC-MT-004 | API acciones críticas | Ronda/oferta/booking de B | `awardRfqOffer`, `respondBookingCancellation`, `decideSuspensionReview`, `resolveBookingDispute` desde A | `404/403`; sin efecto en BD de B; sin eventos de dominio emitidos | P0 | SRS-TEN-001, SRS-RFQ-009 |
| TC-MT-005 | Cabecera de contexto | Usuario de A con sesión válida | Enviar `X-Organization-Id` de B | `403 FORBIDDEN` (membresía inexistente); sin fuga de datos en el error | P0 | TEC-006 |
| TC-MT-006 | Roles globales | `ADMIN_PLATAFORMA` vs `COORDINADOR` de A | Acceso de admin a datos de A y de B; coordinador a lo mismo | AP ve ambos (con auditoría); CO solo A; `/admin/*` para CO → `403` | P0 | SRS-AUTH-005, matriz UXUI §3.2 |
| TC-MT-007 | Vertical (intra-tenant) | `COORDINADOR_RESTRINGIDO` de A con evento asignado E1 y no asignado E2 de A | Operar/leer E2 | `403/404`; E1 operable; matriz de acciones CR según UXUI §3.2 (sin adjudicar/cancelar) | P0 | SRS-AUTH-011, DEC-011 |
| TC-MT-008 | Vertical proveedor | Proveedores P1 y P2 con contrataciones | P1 consulta bookings/RFQ/portafolio de P2 vía API de proveedor | 0 filas / `404`; P1 solo ve sus propias filas (RLS-B por `provider_id`) | P0 | TDD §5.2 RLS-B |
| TC-MT-009 | No-enumeración | — | Comparar respuestas/tiempos de recurso existente en B vs UUID inexistente | Mismo `404 MAGIC_LINK_INVALID`/`NOT_FOUND` con cuerpo indistinguible (sin detalle interno); tiempo no sistemáticamente distinto | P1 | SAD §7.3/§10.6 |

### 8.3 Catálogo — base de datos (RLS real, generado por tabla, DT-10)

Los 7 patrones siguientes se **parametrizan por cada una de las 39 tablas clase (a)**: organizations, memberships, invitations, ownership_transfers, organization_plans, plan_usage_counters, event_templates, event_template_selections, whatsapp_templates, events, event_categories, event_assignments, bookings, booking_consumed_dates, booking_terms_snapshots, booking_status_history, booking_change_proposals, commission_records, rfq_items, rfq_cycles, rfq_requests, magic_link_grants, rfq_offers, awards, quotations, quotation_items, quotation_item_subtypes, quotation_item_options, quotation_item_tracking_history, quotation_versions, quotation_documents, quick_quotations, quick_quotation_options, assisted_response_drafts, reviews, review_reports, notifications, audit_logs, dispute_resolutions.

| ID | Patrón (× 39 tablas) | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-MT-010 | P1 — SELECT sin contexto (fail-closed) | `pe_api` sin `set_config` de tenant | 0 filas (la BD no filtra nada sin contexto) | P0 | TDD §5.2, ADR-TEST-004 |
| TC-MT-011 | P2 — SELECT cross-tenant | `pe_api` con contexto de A | Solo filas de A; filas de B invisibles | P0 | idem |
| TC-MT-012 | P3 — INSERT sin contexto / cross-tenant | INSERT de fila de B con contexto de A (o sin contexto) | Rechazo por `WITH CHECK` de la política (insert finaliza con 0 filas o violación); nunca queda fila huérfana de B | P0 | idem |
| TC-MT-013 | P4 — Cambio de tenant | UPDATE moviendo `organization_id` de la fila de A hacia B | Rechazo (WITH CHECK + FK compuesta); fila permanece en A | P0 | TDD §5.2 |
| TC-MT-014 | P5 — DELETE/UPDATE sin derecho | DELETE/UPDATE de fila de B sin contexto de B | 0 filas afectadas; datos intactos | P0 | idem |
| TC-MT-015 | P6 — Dos partes (RLS-B) | `pe_api` con `app.provider_id` de P1 | En `bookings`, `rfq_offers`, `magic_link_grants`: P1 ve sus filas de ambos tenants (rol de parte legítimo) y **ninguna** fila de P2; en `magic_link_grants` además exige `token_hash` de contexto | P0 | TDD §5.2 RLS-B |
| TC-MT-016 | P7 — Fuga de pool | Conexión del pool: transacción con contexto de A (set_config true) → COMMIT → nuevo request en la misma conexión física | El contexto NO se hereda: `current_setting` vacío → 0 filas hasta fijar contexto de nuevo | P0 | TDD §5.2 (riesgo pooler) |
| TC-MT-017 | Cobertura de clasificación | Lista de tablas clase (a) del esquema | Test que falla si existe tabla con RLS habilitada sin sus 7 patrones generados, o tabla de negocio sensible sin RLS y sin justificación de clase (b)/(c) registrada | P0 | ADR-TEST-004, TDD §4.2 |
| TC-MT-018 | Plataforma admin | `app.platform_admin='on'` como AP, y como usuario común | AP lee a través de políticas (sin BYPASSRLS); usuario común con la variable falsificada no obtiene nada si no corresponde a su rol de aplicación | P0 | TDD §5.2, SRS-AUTH-005 |
| TC-MT-019 | Roles de servicio | `pe_worker` con contexto de cada tenant; `pe_retention` con purga | `pe_worker` lee todo pero **escribe solo con contexto de tenant** fijado (escritura sin contexto rechazada); `pe_retention` único rol que borra (purga respeta `legal_holds`) | P0 | TDD §5.2 |

### 8.4 Catálogo — canales secundarios (caché, storage, notificaciones, jobs)

| ID | Canal | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-MT-020 | Caché Redis | Entradas de caché de A y B para recursos isomorfos | Leer como A; invalidar como A | Claves con prefijo de tenant: A nunca lee entrada de B; invalidación de A no toca B; sin claves sin tenant para datos de negocio | P0 | TDD §5.2 |
| TC-MT-021 | Storage/medios | Medio de portafolio de proveedor P2 (tenant/partes) y documento PDF de B | Solicitar URL firmada como P1/A; abrir URL firmada de B expirada o de otro scope | URL de P1 solo para P1; URL ajena → `404/403`; firma con scope; nunca bucket global sin tenant en la clave | P0 | SRS-CAT-002, TDD §5.2 |
| TC-MT-022 | Notificaciones | Notificación de usuario de B | `listNotifications` como usuario de A (RLS-G) | Solo avisos propios/ de su organización; in-app de B invisible; emails (bandeja stub) de B no reciben correo de negocio de A | P0 | SRS-NOT-001/002 |
| TC-MT-023 | Jobs y Outbox | Eventos de dominio de A y B pendientes en `outbox_events` | Procesar outbox con worker | Cada evento se procesa con el contexto de su `organization_id` del envelope; efecto de evento de A jamás actualiza filas de B; payload contiene tenant correcto; `processed_events` global no rehusa id entre tenants | P0 | ADR-DATA-006, DDD §8.2 |
| TC-MT-024 | Magic Link cruzado | Grant ACTIVO de solicitud de A; datos de B | Resolver formulario con token de A y solicitar ítems/URLs de B | El token solo da acceso a su solicitud (RLS token_hash); sin datos de B en el snapshot del formulario; respuesta crea oferta solo en A | P0 | SAD §7.3, RLS-B |
| TC-MT-025 | Portal de proveedor | `submitProviderPortalOffer` como P1 | Responder solicitudes: propia ENVIADO; de P2; ya RESPONDIDO | Solo su propia solicitud en estado enviable; slot/proveedor únicos por ciclo; respuesta sobre ya respondida → rechazo (oferta inmutable, revisión aparte) | P0 | SRS-RFQ-006/007, TEC-001 |
| TC-MT-026 | Invitaciones | Token de invitación de B | Aceptar desde SCR-009 con token de B habiendo sesión de A | El token solo activa membresía en B; sin fusión de cuentas ni acceso a A; `invitation_token_hash` RLS-D | P0 | SRS-AUTH-006, RLS-D |
| TC-MT-027 | Contadores de plan | A y B con plan PRUEBA | Agotar límite de A; crear recursos como B | Límite de A no afecta a B (contadores por organización); B sigue creando sin restricción de A | P0 | SRS-TEN-003/004, DEC-029 |
| TC-MT-028 | Reseñas — excepción declarada | Reseña VISIBLE de organización sobre proveedor | Leer como A (ajena), como P (proveedor), anónimo | La reseña `VISIBLE` es pública por diseño (RLS-E) para todos; `OCULTA` solo visible a dueños/moderación; este es el único acceso declarado fuera del tenant y su aserción valida que no se filtre más allá del estado VISIBLE | P1 | RLS-E, SRS-REV-008 |

**Criterio de aceptación de la suite:** 100% de casos en verde en cada PR (AS-09); patrones §8.3 generados (no copiados) por tabla; dos tenants con datos isomorfos en todos los escenarios; ninguna aserción tolera fuga (cualquier fila de B vista por A = fallo duro).

## Sección 9 — Pruebas de Concurrencia en Reservas y Adjudicaciones (`TC-CONC`)

### 9.1 Mecanismo bajo prueba y método obligatorio

* **Mecanismo (SAD §7.2/7.5, TDD §5.1, ADR-DATA-002/003):** `ConfirmBooking` único consume capacidad (global por fecha `provider_daily_capacity` y por paquete `package_daily_capacity`, DEC-006) con orden global de bloqueo: `INSERT … ON CONFLICT DO NOTHING` de filas de capacidad → **fila del proveedor en modo compartido (`FOR SHARE`, DEC-036)** → **`SELECT … FOR UPDATE` de capacidad global por fecha ascendente** → capacidad del paquete; revalida y consume; las restricciones únicas parciales (`uq_bookings__active_item`, `uq_awards__organization_id_cycle_id`) son la última barrera. Aislamiento `READ COMMITTED`; reintentos solo ante `40P01`/`40001` (máx 3, backoff aleatorio, misma `Idempotency-Key`); `CapacityExhausted` nunca se reintenta.
* **Método (ADR-TEST-003, TDD §10.3):** ejecución **realmente concurrente** contra PostgreSQL real: N solicitudes armadas previamente y liberadas juntas con barrera sincronizada (`Promise.all` sobre las conexiones ya establecidas); **N = 20** y **100 repeticiones** por escenario; múltiples conexiones simultáneas (pool ≥ N); `retry: 0` en el harness (los únicos reintentos son los de negocio); sin `sleep` artificiales.
* **Invariantes transversales:** cada escenario termina con las **queries de auditoría post-carrera** (caso de verificación final de esta sección): 0 duplicados, contadores exactos, Outbox exacto, integridad referencial intacta.

### 9.2 Catálogo — escenarios de carrera (todos P0)

| ID | Carrera | Precondiciones | Entrada / Acción concurrente | Resultado esperado (aserción exacta) | Trazabilidad |
|---|---|---|---|---|---|
| TC-CONC-001 | Doble reserva (*double-booking*) | Proveedor capacidad 2, fecha con `consumed=1` (queda 1 plaza); paquete INSTANT_BOOK | N=20 `createInstantBooking` simultáneos sobre la última plaza | **Exactamente 1** éxito (200/201); **N−1** fallos deterministas `409 CAPACITY_EXHAUSTED`; `consumed=2` final; sin bookings huérfanos; 100 repeticiones sin deadlock no manejado | SRS-BOOK-002/003, SAD §16.5 |
| TC-CONC-002 | Doble adjudicación | Ítem con 3 ofertas `RECIBIDA` vigentes de 3 solicitudes; sin ganador | 2 usuarios del mismo organizador (y variante N=10) adjudican **distintas** ofertas del mismo ítem al mismo tiempo | **Exactamente 1** adjudicación confirmada (`OfferAwarded`+booking); el resto `409 AWARD_ALREADY_EXISTS` o `OFFER_NOT_AWARDABLE` (según orden real de bloqueo); solicitudes perdedoras → `NO_ADJUDICADO`; grants `REVOCADO`; `uq_awards__organization_id_cycle_id` nunca violada | SRS-RFQ-009, ADR-DATA-004 |
| TC-CONC-003 | Adjudicación vs. Instant Book | Ítem E_RFQ con oferta vigente + paquete INSTANT_BOOK; ambos sobre el último cupo del proveedor | `awardRfqOffer` y `createInstantBooking` simultáneos | **Exactamente 1** confirmación; el perdedor rechazo limpio (`409 CAPACITY_EXHAUSTED`); sin estado híbrido del ítem (`CONFIRMADO` XOR `ADJUDICADO`) | SRS-RFQ-009 (caso explícito), TEC-009 |
| TC-CONC-004 | Consumo concurrente de Magic Link | Grant ACTIVO con token T | N=20 `submitMagicLinkResponse` con el mismo token T | **Exactamente 1** oferta creada (`MagicLinkConsumed`); N−1 → `404 MAGIC_LINK_INVALID` indistinguible; grant → `CONSUMIDO`; `uq_magic_link_grants__active`/`token_hash` íntegros | SRS-MAGIC-003, SAD §7.3 |
| TC-CONC-005 | Reintentos con misma `Idempotency-Key` | Clave K nueva | N=20 requests idénticos con K al mismo tiempo | **1** efecto secundario en BD y **1** evento en Outbox; N−1 reciben la respuesta guardada; sin errores 500 | TEC-003, ADR-DATA-19 |
| TC-CONC-006 | Suspensión vs. adjudicación/Instant Book | Proveedor con último cupo y adjudicación pendiente | `setProviderSuspension` concurrente con `awardRfqOffer` y con `createInstantBooking` | Cada booking queda **o rechazado** (`403` tras suspensión) **o en `CANCELACION_EN_REVISION`** origen PLATAFORMA; **ningún** `CONFIRMADO` con inicio futuro; serialización garantizada por `FOR SHARE` (ConfirmBooking) vs `FOR UPDATE` (suspensión) de la fila del proveedor; suspensión idempotente | SRS-ADM-013, DEC-034/036, SAD §7.6 |
| TC-CONC-007 | Adjudicación vs. cancelación/expiración/retiro | Oferta A adjudicable; en paralelo el proveedor revisa (→`REEMPLAZADA`), o la solicitud expira (`sla_expira_at` alcanza), o se revoca | Adjudicar A exactamente en el mismo instante de la mutación | Consistencia estricta: **o** A queda `ADJUDICADA` con booking, **o** queda `REEMPLAZADA`/`VENCIDA`/`INVALIDADA` sin booking; nunca híbrido; el perdedor recibe `409 OFFER_NOT_AWARDABLE`/`OFFER_EXPIRED`; sin grant ni grant-revocación huérfanos | SRS-RFQ-007/012, DEC-005/026 |
| TC-CONC-008 | Cancelación vs. respuesta de cancelación | Booking en `CANCELACION_SOLICITADA` | Las 2 partes responden simultáneamente (acepta vs disputa) | **1** transición efectiva (la primera que bloquea); la otra → `409 INVALID_STATE_TRANSITION`; estado final consistente con la acción ganadora; capacidad liberada solo si `CANCELADO` | SRS-BOOK-007, DEC-001 |
| TC-CONC-009 | Expiración de SLA vs. respuesta en el límite | Solicitud ENVIADO con `sla_expira_at = T` | Respuesta del proveedor con `received_at` exactamente en T (job ejecutándose a la vez) | La hora del servidor decide una única vez: `received_at <= sla_expira_at` → `RESPONDIDO`+oferta; si no → `EXPIRADO`; job tardío no muta el resultado terminal; sin doble estado | SRS-RFQ-004, SAD §8.4 |
| TC-CONC-010 | Reenvío concurrente | Solicitud en `ERROR_ENVIO` con `retry_count=0` | 2+ `retryRfqDispatch` simultáneos | **1** reintento efectivo (`retry_count+1`, vuelve a `PENDIENTE_ENVIO`); los demás no-op o `409`; `retry_count` nunca salta 2 en una corrida ni excede 3 | SRS-RFQ-013, DEC-026 |
| TC-CONC-011 | Doble edición optimista | Disponibilidad/paquete con `version` V | 2 `setProviderAvailability`/`updatePackage` simultáneos con `If-Match` V | **1** gana (200, `version+1`); el otro `412 PRECONDITION_FAILED`; `consumed` de fechas nunca corrompido por la edición | TEC-011, SRS-CAT-009 |
| TC-CONC-012 | Doble reseña | Booking `COMPLETADO` sin reseña | 2 `createReview` simultáneos del mismo booking | **1** reseña insertada (`uq_reviews__organization_id_booking_id`); la otra rechazo determinista 409; promedio del proveedor calculado una sola vez coherente | SRS-REV-004 |
| TC-CONC-013 | Reservas multi-fecha solapadas | Capacidad 2 por fecha; fechas 1-4 libres | Booking A (fechas 1-3) vs Booking B (fechas 2-4) simultáneos, con capacidad ya parcialmente consumida en fecha 2 | Consumos por fecha exactos (DEC-025); si B no cabe en la fecha 2 → **rollback completo de B** (sin consumo parcial en 3-4) y `409 CAPACITY_EXHAUSTED`; contadores por fecha consistentes | DEC-025, SRS-BOOK-003 |
| TC-CONC-014 | Transferencia vs. propietario saliente | Transferencia `PENDIENTE` | Aceptar transferencia mientras el propietario saliente ejecuta acciones (invitar, editar evento) | Siempre **un único** `PROPIETARIO` (`uq_memberships__single_owner`); acciones del saliente tras aceptación → `403`; sin membresía huérfana | DEC-008, SRS-AUTH-009 |
| TC-CONC-015 | Mezcla aleatoria sostenida | Dataset con 20 proveedores/fechas/ítems | Mezcla aleatoria de operaciones de escritura durante **10 min** (reservas, adjudicaciones, cancelaciones, edits, jobs SLA) | **0 deadlocks no manejados** (cero errores `40P01` post-reintento); 0 errores 500; todos los invariantes de la tabla de verificación final se mantienen en cada snapshot de 30 s | TDD §10.3 (2), ADR-TEST-003 |

### 9.3 Verificación final — invariantes post-carrera (obligatoria tras cada escenario)

Query de auditoría exacta tras cada corrida (y cada repetición); **cualquier desviación = fallo del escenario**:

| ID | Invariante | Aserción SQL/de dominio | Trazabilidad |
|---|---|---|---|
| TC-CONC-016 | Consistencia de capacidad, unicidad y Outbox | (a) `consumed` de `provider_daily_capacity`/`package_daily_capacity` == count de `booking_consumed_dates` activas por fecha; (b) ≤ 1 award por ciclo/ítem (únicos sin violación); (c) 0 bookings activos por ítem (>1 fila viva); (d) `outbox_events` contiene exactamente los eventos esperados por el escenario (sin duplicados por `eventId`); (e) `commission_records` coherentes con estados de booking (P0); (f) `CHECK` `consumed <= capacity` intacto; (g) FK sin huérfanos | TDD §10.3 (2)/(6), SRS-NFR-PERF-006 |

**Criterio de aceptación de la suite:** 100% de escenarios en verde en cada PR (SAD §16.5 la hace bloqueante); N=20 × 100 repeticiones ejecutadas sin `retry` del harness; mezcla nocturna de 10 min sin `40P01`; evidencia de cada corrida (resultados por request + queries de auditoría) adjunta al reporte de CI.

## Sección 10 — Pruebas de Seguridad (`TC-SEC`)

### 10.1 Cobertura OWASP API Security Top 10 y método

| OWASP | Controles del sistema bajo prueba | Casos |
|---|---|---|
| API1 BOLA | Autorización por tenant y recurso en backend (TEC-005/006) | Matriz completa en Sección 8 (canal API y RLS) |
| API2 Autenticación rota | JWT Auth0 validado por backend (firma/issuer/audience/exp/MFA), sesión BFF | §10.2 — autenticación (3 casos) |
| API3 Autorización a nivel de propiedades | Validación estricta en frontera, campos protegidos | §10.2 — propiedades (2 casos) |
| API4 Consumo ilimitado de recursos | Rate limiting, límites de página/payload | §10.2 — consumo de recursos (2 casos) |
| API5 Autorización a nivel de función | RBAC de 6 roles por operación | §10.2 — matriz RBAC generada (1 caso) |
| API6 Flujos de negocio sin restricción | Límites de plan, invitaciones únicas, magic link de un uso | §10.3 — flujos de negocio (2 casos) |
| API7 SSRF | Sin fetch de URLs de usuario; adaptadores con hosts fijos | §10.3 — SSRF (1 caso) + archivos (1 caso) |
| API8 Configuración incorrecta | Cabeceras de seguridad, CORS, errores sin detalles | §10.4 — misconfiguración (3 casos) |
| API9 Gestión deficiente del inventario | Superficie `/api/v1` única, sin rutas sueltas | §10.4 — superficie (1 caso) |
| API10 Consumo inseguro de APIs | Webhook SendGrid firmado, JSON asistido validado | §10.3 — consumo de APIs externas (2 casos) |

**Método:** pruebas dirigidas vía Supertest/E2E (negativas y de abuso) + análisis automatizado en CI: Semgrep (SAST), `npm audit --audit-level=high` (SCA), gitleaks (secretos) en cada PR; OWASP ZAP baseline nocturno contra `staging-perf`. Umbral de rate limiting: las pruebas usan el umbral **configurado del ambiente de test** (los documentos no fijan umbrales productivos; DT-13) y validan el comportamiento (429 + `Retry-After`), no la cifra.

### 10.2 Catálogo — autenticación, autorización y propiedades

| ID | OWASP | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-SEC-001 | API2 | Endpoint protegido | Tokens manipulados: firma inválida, `alg:none`, `kid` inexistente, payload alterado | `401 UNAUTHENTICATED` en todos; sin distinción de causa filtrable | P0 | DEC-017, SRS-NFR-SEC-001 |
| TC-SEC-002 | API2 | Usuario con MFA habilitado | Token expirado; `max_age` vencido para transferencia de propiedad; email no verificado en registro | `401`; transferencia exige re-autenticación reforzada (SRS-AUTH-012); registro rechaza email sin verificar (TEC-007) | P0 | SRS-AUTH-012, DEC-008 |
| TC-SEC-003 | API2/API4 | Login y recuperación | Fuerza bruta: 10+ fallos/10 min por IP y por cuenta; OTP erróneo repetido | `429 RATE_LIMITED` con `Retry-After`; sin revelar si el usuario existe | P0 | SRS-NFR-SEC-012 |
| TC-SEC-004 | API3 | Sesión de COORDINADOR | Mass assignment: PATCH con campos protegidos (`role`, `tenantId`/organización, `status`, `verificationStatus`) en `updateMyPreferences`/`updateMyProvider`/`updateEvent` | Campo ignorado (se filtra por allowlist del DTO) o `400`; verificación en BD: rol/tenant/estado sin cambio | P0 | ADR-API-002, SRS-NFR-SEC-004 |
| TC-SEC-005 | API3 | Cotización/booking vigente | Manipular precio/moneda/comisión en `createInstantBooking`, `submitMagicLinkResponse`, `proposeBookingChange` | El precio vinculante proviene del snapshot del paquete/oferta; el valor enviado por el cliente nunca altera importes (comparación de BD post-llamada) | P0 | SRS-BOOK-005, DEC-018 |
| TC-SEC-006 | API4 | Endpoints sensibles | Ráfagas sobre: `searchProviders`/`listProviderReviews` (IP), magic links (IP y por hash: 10 fallos/10 min), `createInstantBooking`, `receiveSendgridEvents`, registros | `429` + `Retry-After` en todos; tokens inexistentes no revelan existencia antes del umbral | P0 | SAD §7.3, SRS-NFR-SEC-012 |
| TC-SEC-007 | API4 | — | Payload gigante (> límite), JSON con anidamiento profundo (>100 niveles), arrays enormes en filtros | Rechazo seguro (413/400) sin DoS del proceso; sin consumo desproporcionado de BD (timeouts de BD aplican) | P1 | SAD §10.2 |
| TC-SEC-012 | API2/API5 | Usuario con sesión activa | `setUserSuspension`/`setOrganizationSuspension` sobre el usuario; repetir sus requests con el token vigente | Tras suspensión las operaciones → `403` (sesión/autorización revocada a nivel de backend, no solo UI); reactivación restaura acceso; efecto auditado | P0 | SRS-AUTH-007, SRS-NFR-SEC-005 |
| TC-SEC-011 | API5 | Matriz 6 roles × grupos de operación (admin, proveedor, organizador, público) | Llamar cada operación con cada rol no autorizado (matriz generada de UXUI §3.2 y SAD) | `403 FORBIDDEN` sistemático (BFLA); ningún rol escala horizontalmente a otro rol; result tiebreak: sin accesos de `COORDINADOR` a `/admin/*`, de `PROVEEDOR` a operaciones de organizador | P0 | SRS-AUTH-005, DEC-011 |

### 10.3 Catálogo — inyecciones, archivos, SSRF y flujos de negocio

| ID | OWASP | Precondiciones | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-SEC-015 | API7 | Adaptadores con hosts fijos | URLs de usuario en campos (webhook propio, adjunto, búsqueda) que intenten redirigir fetch del backend (http://169.254.169.254/, file://, DNS rebinding) | El backend nunca fetch-a URLs de usuario; solo firma (Cloudinary) o `wa.me` fijo (WhatsApp); sin conexión saliente en la prueba (captura de red) | P0 | ADR-SEC-007 |
| TC-SEC-016 | API7 | Subida de medios firmada | Cargar: SVG con `<script>`, ejecutable renombrado a `.png`, PDF con payload, filename con `../../`, MIME mentiroso, tamaño > límite, 21ª imagen / 6º video | Validación por **magic bytes** en servidor; rechazo de todo lo anterior; path sanitizado (sin traversal); límites 20 imágenes/5 videos respetados (portfolio) | P0 | SRS-NFR-SEC-010, ADR-SEC-009 |
| TC-SEC-013 | API6 | Plan con límites y invitaciones | Crear rondas masivas; invitar 2 veces al mismo email; re-ejecutar solicitud de titular duplicada | `PLAN_LIMIT_REACHED` (nunca bypass por ráfaga — contador atómico); invitación duplicada rechazada (`uq_invitations__pending`); datos sujetos deduplicados | P0 | DEC-029, TDD §5.1 |
| TC-SEC-014 | API6 | Magic Link ya consumido | Re-usar enlace; pre-fetch de escáner de correo (User-Agent de escáner, GET sin JS) | Enlace consumido nunca re-valida; **la apertura por escáner no consume el token** (el consumo ocurre solo en `POST /magic-links/response`); auditoría del ciclo sin token | P0 | SAD §7.3, TEC-008 |
| TC-SEC-025 | API7 | Medios ya registrados | `reorderMedia`/`deleteMedia` de portafolio ajeno; reutilizar firma de subida expirada; subir el mismo archivo dos veces | Solo el propietario reordena/borra; firma con expiración corta (reuso → rechazo); duplicado por hash gestionado según política de portafolio | P1 | SRS-CAT-002, ADR-SEC-009 |
| TC-SEC-017 | API10 | Webhook SendGrid | Replay de payload válido con firma válida y timestamp viejo; duplicado `sg_event_id`; payload opaco malicioso | Timestamp fuera de tolerancia → `401` (anti-replay); duplicado ignorado; body tratado como opaco y sanitizado (sin interpretación de contenido) | P0 | ADR-API-008, SRS-NOT-006 |
| TC-SEC-018 | API10 | Respuesta asistida | JSON con inyección de esquema ($ref externo), profundidad anómala, campos extra, precio incompatible con ítem | Validación contra esquema estático local (sin resolvers externos); mismatches → `409 ASSISTED_RESPONSE_MISMATCH`; nunca crea oferta sin confirmación humana | P0 | SRS-WA-006/007 |
| TC-SEC-019 | Inyección SQL | searchProviders/searchAuditLogs/listX con filtros y sort | Payloads SQLi en filtros, sort, cursor (`'; DROP TABLE`, `1=1`, `UNION SELECT`) | Sin efecto: resultados solo legítimos; BD intacta; parametrización verificada (el análisis de arquitectura de §5.8 garantiza `$queryRaw` parametrizado) | P0 | SRS-NFR-SEC-004, ADR-DATA-010 |
| TC-SEC-020 | XSS | Perfil/reseña/mensaje con `<script>`, `onerror=`, `javascript:` en descripciones, respuestas y nombres | Persistir y renderizar en SCR-003/053/025 | Payload persistido como dato, renderizado escapado (sin ejecución; verificación por ausencia de handler/nodo script activo); CSP del frontend activa | P0 | SRS-NFR-SEC-004, UXUI |
| TC-SEC-021 | CSRF | Sesión BFF con cookies | Petición cross-site simulada sin token CSRF / con SameSite indebido | Rechazo; cookies `HttpOnly`+`Secure`+`SameSite` asertadas en el set; tokens nunca en `localStorage` | P0 | DEC-017, ADR-SEC-002 |

### 10.4 Catálogo — configuración, PII y pipeline de seguridad

| ID | Categoría | Entrada / Acción | Resultado esperado | Prio | Trazabilidad |
|---|---|---|---|---|---|
| TC-SEC-008 | Misconfig | Inspección de cabeceras en 200/4xx/5xx de rutas muestreadas (incl. magic links) | `Strict-Transport-Security` (TLS 1.2+), `X-Content-Type-Options: nosniff`; en magic links **todas** las respuestas con `Cache-Control: no-store` y `Referrer-Policy: no-referrer` (sin Pragma); CSP del frontend | P0 | SAD §7.3, SRS-NFR-SEC-001 |
| TC-SEC-009 | Misconfig | CORS desde origen malicioso con credenciales | Origen no permitido rechazado; sin `Access-Control-Allow-Credentials` hacia orígenes arbitrarios | P0 | DEC-017 |
| TC-SEC-010 | Misconfig | Provocar 500 (fallo inyectado) y consultar `/health/*` | 5xx `problem+json` sin stack, SQL, rutas internas ni versión de framework; health sin detalles de infraestructura | P0 | SAD §10.8, SRS-NFR-SEC-011 |
| TC-SEC-022 | PII en logs | Ejecutar flujos con tokens/magic links/credenciales y capturar logs de prueba | Ningún log contiene token completo, hash de magic link, contraseña, API key, ni PII innecesaria; correlationId presente; redacción de secretos en telemetría (Sentry stub) | P0 | SRS-NFR-SEC-011, ADR-OBS-002 |
| TC-SEC-023 | PII en errores | Errores de validación y 500 con datos personales en el payload rechazado | `fieldErrors` sin eco completo del valor sensible (máscara); mensaje de error sin PII | P1 | PRIV-003, SAD §10.6 |
| TC-SEC-024 | Privacidad (Ley 1581) | Registro empresa/proveedor; solicitud CONSULTA/CORRECCIÓN/SUPRESIÓN; purga con `legal_hold` | Consentimiento versionado registrado (tipo, versión, fecha); derechos por plazos DEC-037 con evidencia; purga respeta retención; export de datos personales solo al titular | P0 | PRIV-001..008, SRS-ADM-012 |
| TC-SEC-026 | SCA | `npm audit --audit-level=high` + análisis de lockfile en CI | 0 vulnerabilidades críticas/altas; dependencias fijadas por lockfile (ADR-STACK-003); nuevas dependencias con aprobación | P0 | SAD §13.3 |
| TC-SEC-027 | Secretos | gitleaks sobre el repo + revisión de variables | Sin secretos/tokens en código, config versionada o logs; secretos solo por variables de entorno | P0 | SRS-NFR-SEC-007, ADR-SEC-005 |
| TC-SEC-028 | SAST | Semgrep con reglas OWASP + anti-sabotaje en CI | 0 hallazgos críticos/altos; reglas custom (skip/only, assertions triviales) activas (Sección 2.4) | P0 | ADR-GOV-003 |
| TC-SEC-029 | DAST | ZAP baseline nocturno contra `staging-perf` | Sin alertas High/Critical no documentadas; hallazgos abren issue automático | P1 | SRS-NFR-SEC-004 |
| TC-SEC-030 | Cliente | Inspección de bundle y cookies en E2E | Sin tokens/PII en `localStorage`/`sessionStorage`; cookies de sesión HttpOnly/Secure/SameSite; sin recursos de terceros en SCR-012 | P0 | DEC-017, UXUI |
| TC-SEC-031 | API9 | Descubrimiento de superficie | Solo rutas `/api/v1` documentadas responden; versiones antiguas no expuestas; sin endpoints de debug (`/debug`, `/actuator` análogos) | P1 | ADR-API-001 |

**Criterio de aceptación de la suite:** la matriz RBAC generada de §10.2 cubre 6 roles sin huecos; 0 hallazgos críticos/altos en SAST/SCA en PR; DAST nocturno sin High; cualquier hallazgo abre issue con correlationId de la prueba.

## Sección 11 — Pruebas de Carga y Resiliencia (`TC-LOAD`)

### 11.1 Herramienta, objetivos y endpoints bajo prueba

* **Herramienta:** **k6** (DT-05), scripts en `tests/load/`; los **thresholds k6 son el criterio de fallo automático** del script (si un threshold se supera, k6 termina con código distinto de 0 y el job de CI/nightly falla).
* **Objetivos numéricos (derivados de SRS-NFR-PERF-001..006, RNF-05 y SLO de SAD §12.2):** búsqueda p95 < 1 s; cotización p95 < 3 s; reserva/adjudicación p95 < 2 s; PDF p95 < 5 s; 500 usuarios simultáneos con tasa de error < 1% en 30 min; retraso de Outbox (commit→publicado) p99 < 1 min; primer despacho de email 95% < 5 min; **integridad prevalece sobre latencia**: cero sobreventas y cero adjudicaciones dobles siempre (SRS-NFR-PERF-006).
* **Endpoints críticos bajo prueba:** `searchProviders` (público), `getPublicProvider`, `createQuickQuotation`, `createQuotation`, `getQuotation`, `createRfqCycle`, `submitMagicLinkResponse`, `createInstantBooking`, `awardRfqOffer`, `listEvents`/`listBookings`, `requestQuotationPdf`.
* **Mezcla de tráfico objetivo (baseline):** ~80% lecturas / ~20% escrituras — 40% búsqueda catálogo, 15% detalle público, 10% cotizaciones (cálculo/lectura), 10% listas del tenant, 8% escrituras RFQ/ofertas, 5% reservas/adjudicaciones, 5% documentos, 7% otros (notificaciones, reseñas).
* **Entorno:** `staging-perf` con dataset de referencia (§3.4); BD restaurada a snapshot conocido antes de cada perfil; observación de `pg_stat_activity` (pool), profundidad/edad de colas BullMQ y RSS de procesos API/worker.

### 11.2 Catálogo — perfiles (todos ejecutan con thresholds como criterio Pass/Fail)

| ID | Perfil | Carga (DT-06) | Duración | Criterios de fallo (thresholds k6) | Prio | Trazabilidad |
|---|---|---|---|---|---|---|
| TC-LOAD-001 | Smoke Load | 5 VU constantes sobre los endpoints críticos (mezcla abreviada) | 2 min | `http_req_failed` < 1%; p95 global < 2 s; checks de estado 100%; 0 sobreventas (auditoría post-run) | P1 (post-merge) | SRS §7.1 |
| TC-LOAD-002 | Baseline / Average | 50 VU constantes con la mezcla objetivo §11.1; OpenAPI-compliant | 20 min | p95 `searchProviders` < 1 s; p95 cotización < 3 s; p95 reserva/adjudicación < 2 s; error < 1%; pool PG < 80%; edad de colas estable | P0 (nightly) | SRS-NFR-PERF-003/002/006, SAD §12.2 |
| TC-LOAD-003 | Spike / Peak | Rampa 50→**500 VU** en 2 min, meseta 5 min, bajada 2 min (cierre masivo de cotizaciones/apertura de convocatoria con ráfaga de reservas) | ~10 min | Mismos umbrales de latencia del perfil Baseline durante la meseta; error < 1%; **0 sobreventas y 0 adjudicaciones dobles** verificadas por auditoría post-run (la integridad nunca degrada) | P0 (pre-release) | RNF-05, SRS-NFR-PERF-005/006 |
| TC-LOAD-004 | Stress | Escalonado 100→200→…→700 VU (140% del objetivo), 5 min por escalón, hasta degradación sostenida | ~40 min | Documentar punto de quiebre (VU/RPS donde error ≥ 1% o p95 > objetivo); antes del quiebre: sin 5xx sistemáticos, sin deadlocks; `503 DEPENDENCY_UNAVAILABLE` ordenado (no colapso) aceptable solo post-quiebre | P1 (pre-release) | TDD §10.3 (6) |
| TC-LOAD-005 | Soak / Endurance | 120 VU (~24% del pico) con mezcla objetivo | 2 h | RSS de API y worker sin crecimiento sostenido (±10% tras descarte de warm-up); edad/profundidad de colas sin crecimiento; pool estable; error < 1%; sin fugas de conexiones (`pg_stat_activity` estable) | P0 (pre-release; semanal) | SRS-NFR-PERF-005, AVL-005 |
| TC-LOAD-006 | Outbox y notificaciones bajo carga | Rampa de eventos de negocio (adjudicaciones/reservas) que generan ≥ 5.000 eventos en la ventana | 20 min | Outbox: commit→`PUBLICADO` p99 < 1 min; primer despacho de email 95% < 5 min (SendGrid stub sandbox); `PENDIENTE` nunca > 10 min sin alerta; consumidores idempotentes (0 duplicados en bandeja stub) | P0 (pre-release) | SAD §12.2, SRS-NOT-004 |
| TC-LOAD-007 | Sobrecosto de RLS | Mismas consultas de búsqueda/lista con y sin contexto de tenant (`set_config`) sobre dataset ×3 | medición puntual | Sobrecosto de RLS < 10% en latencia media por consulta (evidencia comparada) | P1 (pre-release) | TDD §10.3 (6) |
| TC-LOAD-008 | Evidencia de consultas | `EXPLAIN (ANALYZE, BUFFERS)` de las consultas puntuales críticas con volumen ×3 | medición puntual | `searchProviders` (3 filtros, página 20) < 1 s; cotización de 15 ítems con 3 candidatos/ítem < 3 s; listas del tenant < 200 ms; planes de ejecución sin seq scans inesperados; evidencia adjunta al reporte | P0 (pre-release) | TDD §10.3 (6), SRS-NFR-PERF-002/003 |

### 11.3 Reglas de ejecución y degradación

1. La **integridad prima sobre la latencia** (SRS-NFR-PERF-006): si bajo carga se detecta una sola sobreventa o adjudicación doble, el perfil **falla** aunque todos los thresholds de latencia pasen.
2. Degradación esperada y ordenada: bajo sobrecarga el sistema responde `429` en flujos públicos y `503 DEPENDENCY_UNAVAILABLE` con `Retry-After` en dependencias caídas (SAD §10.6); un colapso con 5xx masivos = fallo del perfil.
3. Cada corrida produce reporte con: p50/p95/p99 por endpoint, RPS real, tasa de error, pool de BD, colas, RSS; comparado contra la corrida anterior (regresión de rendimiento visible).
4. La suite de concurrencia (Sección 9) es la autoridad de integridad; la carga nunca reemplaza a la concurrencia, la complementa a escala.

## Sección 12 — Criterios de Aceptación y Quality Gates

### 12.1 Criterios de aceptación funcionales por módulo (Given/When/Then)

Formato verificable para los flujos principales del PRD/SRS (uno por módulo; los casos `TC-*` de las Secciones 4–11 son su desagregación).

**M-01 identity-access (SRS-AUTH-001/003/006)**
```gherkin
Given una persona autenticada en Auth0 sin membresía
When completa el registro de empresa con NIT sintético y email verificado
Then se crea Organization ACTIVO tras verificación, con Membership PROPIETARIO única
And la invitación de un coordinador por email produce enlace /invitacion#token de un solo uso
```

**M-02 organizations (SRS-TEN-001/003, TEC-006)**
```gherkin
Given un usuario con membresías activas en 2 empresas
When llama a una operación de tenant sin X-Organization-Id
Then recibe 400 ORGANIZATION_REQUIRED
And con cabecera válida solo ve recursos de esa organización (0 filas de la otra)
```

**M-03 provider-catalog (SRS-CAT-001/006/009)**
```gherkin
Given un proveedor VERIFICADO y ACTIVO con paquete E_RFQ y capacidad global 2
When publica el paquete y define su calendario de disponibilidad
Then el paquete es elegible en cotización y búsqueda pública sin exponer contacto
And el calendario refleja "usados/capacidad" por fecha local
```

**M-04 taxonomy-templates (SRS-CAT-003/004, SRS-EVT-002)**
```gherkin
Given el catálogo de 21 categorías CAT-01..21 sembrado
When el administrador crea un subtipo coherente y una plantilla global de evento
Then la plantilla es usable por cualquier organización sin alterar el original
And un código de categoría retirado nunca se reutiliza
```

**M-05 event-management (SRS-EVT-001/005/009)**
```gherkin
Given un evento BORRADOR creado desde plantilla con zona America/Bogota
When la organización lo cotiza, clona y finalmente cancela sin contrataciones en EN_PROGRESO
Then el clon no arrastra compromisos y la cancelación revoca RFQ abiertas e invalida ofertas y Magic Links
```

**M-06 quotation (SRS-QUO-006/008/012, DEC-004/027/032)**
```gherkin
Given 15 ítems con precio base y por persona y proveedores TOP 3 por categoría
When la organización genera la cotización integral y su PDF
Then subtotal, comisión referencial 3% y total son idénticos en pantalla, PDF y snapshot
And el ranking es explicable (40/30/20/10) y el snapshot queda inmutable
```

**M-07 availability-booking (SRS-BOOK-002/003/006/008, TEC-009)**
```gherkin
Given la última plaza del proveedor para una fecha local
When dos usuarios intentan reservar simultáneamente con Idempotency-Key distinta
Then exactamente 1 reserva CONFIRMADO existe y la otra recibe 409 CAPACITY_EXHAUSTED
And al completarse el servicio la comisión devenga y al cancelarse se libera la capacidad
```

**M-08 rfq-offers (SRS-RFQ-001/004/009, TEC-008)**
```gherkin
Given un ítem E_RFQ con ronda de 5 proveedores y SLA 48h
When los proveedores responden por Magic Link y el organizador adjudica la mejor oferta vigente
Then exactamente 1 oferta queda ADJUDICADA con booking creado y capacidad consumida en la misma transacción
And las demás solicitudes quedan NO_ADJUDICADO con aviso de cortesía sin datos de competencia
```

**M-09 assisted-response (SRS-WA-006/007/008)**
```gherkin
Given una respuesta de WhatsApp pegada en el asistente
When el JSON validado es confirmado por un humano
Then se crea la oferta con origen WHATSAPP_IA_ASISTIDO trazable
And un JSON inválido o ítem distinto es rechazado sin crear oferta
```

**M-10 messaging-notifications (SRS-NOT-001/004/005/006)**
```gherkin
Given un evento de dominio publicado vía Outbox
When el worker despacha el email transaccional
Then el primer despacho ocurre en el 95% de los casos en menos de 5 minutos
And un fallo de SendGrid reintenta con backoff sin revertir el negocio y actualiza estado por webhook firmado
```

**M-11 reviews (SRS-REV-001/003/004/006)**
```gherkin
Given un booking COMPLETADO dentro de la ventana de 30 días
When la organización califica las 4 dimensiones y el proveedor responde
Then el promedio del proveedor se recalcula como media exacta de 4 dimensiones
And una segunda reseña para el mismo booking es rechazada y la respuesta no altera puntajes
```

**M-12 administration-audit (SRS-ADM-001/005/010/013, DEC-034/036)**
```gherkin
Given un proveedor con contratación futura CONFIRMADO
When la plataforma lo suspende con motivo
Then la contratación futura pasa a CANCELACION_EN_REVISION origen PLATAFORMA con ventana min(72h, inicio del servicio)
And las RFQ abiertas se cancelan, los Magic Links se revocan y todo queda auditado sin tocar la capacidad
```

### 12.2 Quality Gates (tabla binaria Pass/Fail)

| Gate | Etapa | Criterio objetivo (binario) | Bloqueante |
|---|---|---|---|
| G-01 Lint + tipos | PR | `eslint` + `tsc --noEmit` sin errores | Sí |
| G-02 Unitarias + cobertura | PR | `TC-UNIT` 100% pass; cobertura `domain` ≥ 90% líneas/ramas, `application` ≥ 80%, global ≥ 80%/75% y **no descendente** vs `main` | Sí |
| G-03 Arquitectura | PR | 12 reglas `TC-ARCH` pass; dependency-cruiser analizó > 0 archivos; `adr-guard` pass | Sí |
| G-04 API/contrato | PR | `TC-API` 100% pass (incl. matriz de 20 ErrorCode y 47 operaciones con idempotencia muestreadas por generador) | Sí |
| G-05 Integración | PR | `TC-INT` 100% pass contra PostgreSQL 15 y 16 reales | Sí |
| G-06 Multi-tenant | PR | `TC-MT` **100% pass** (0 fallos, 0 saltos) | Sí |
| G-07 Concurrencia | PR | `TC-CONC` **100% pass** (N=20 × 100 repeticiones; 0 deadlocks no manejados; invariantes post-carrera verdes) | Sí |
| G-08 Seguridad estática | PR | Semgrep 0 críticos/altos; `npm audit` 0 críticos/altos; gitleaks 0 secretos | Sí |
| G-09 E2E smoke | PR | 12 escenarios SRS §8 en Chromium: 100% pass | Sí |
| G-10 Anti-sabotaje | PR | AS-01..AS-10 verdes (0 skips, cobertura no descendente, sin diffs de configs protegidas, nº de `TC-*` no decrece) | Sí |
| G-11 E2E completa + a11y | Merge | Suite completa (2 viewports × Chromium/WebKit) 100%; axe: 0 violaciones serious/critical | Sí |
| G-12 Carga smoke | Merge | Perfil Smoke Load (Sección 11.2) pass en `staging-perf` | Sí |
| G-13 Migraciones | Merge | Migración desde cero + compatibilidad N-1 verificadas en ambiente efímero | Sí |
| G-14 Carga completa | Release | Perfiles Baseline, Spike, Soak, Outbox, sobrecosto RLS y evidencia de consultas pass; perfil Stress con punto de quiebre documentado ≥ 500 VU efectivos | Sí |
| G-15 Accesibilidad humana | Release | Checklist §8.5 NVDA+Firefox y VoiceOver+iOS sin bloqueos en SCR-012/015/021/025/029/050 | Sí |
| G-16 DAST | Release | ZAP nocturno sin High/Critical abiertos | Sí |
| G-17 Respaldo/restauración | Release | Restauración PITR probada en el periodo (RPO ≤ 1 h, RTO ≤ 4 h); procedimiento post-restauración de Outbox ejecutado | Sí |
| G-18 UAT | Release | Los 12 escenarios SRS §8 validados con negocio; criterios globales SRS §11 (ítems 8, 18, 19, 20) firmados | Sí |
| G-19 Observabilidad | Release | Métricas/alertas de SAD §12 activas (5xx > 2%, cola > 5 min, SLA p99 > 2 min, Outbox > 10 min) y `/health/ready` 503 con dependencia caída demostrado | Sí |

**DoD de PR (resumen):** G-01..G-10 en verde + issue/`SRS-*` referenciado en la descripción + no reducción de casos de prueba. **DoD de Release:** G-11..G-19 en verde sobre el commit candidato.

## Sección 13 — Matriz de Trazabilidad Completa

**Notación:** en esta matriz los casos se citan con su numeración abreviada sin el prefijo `TC-` (p. ej. `UNIT-001..054` = los 54 casos de unitarias numerados de uno a cincuenta y cuatro con ese prefijo), para mantener los IDs oficiales únicos en el documento. Etapas CI: PR = PR Required Check; MERGE = post-merge a `main`; REL = pre-release; NOC = nightly.

### 13.1 Áreas funcionales del SRS → casos → etapa

| Requisito / Área (fuente) | Módulo(s) | Casos (abreviados) | Suite(s) | Etapa |
|---|---|---|---|---|
| SRS-AUTH-001..012 | identity-access, organizations | UNIT-004..008 · API-005/006 · SEC-001..003/011/012 · E2E-015/024 | UNIT, API, SEC, E2E | PR |
| SRS-TEN-001..005 | organizations | UNIT-004..007 · API-027 · MT-001..028 (matriz completa) | MT, API | PR |
| SRS-CAT-001..015 | provider-catalog | UNIT-009..013 · INT-047 · API-031/032 · E2E-001/013 · SEC-016/025 | UNIT, INT, API, E2E, SEC | PR |
| SRS-EVT-001..011 | event-management | UNIT-014..018 · INT-025/026 · API-024 · E2E-002 | UNIT, INT, API, E2E | PR |
| SRS-QUO-001..014 | quotation | UNIT-019..030 · INT-023/026/049 · API-013/029/037/040 · E2E-002/011 | UNIT, INT, API, E2E | PR |
| SRS-BOOK-001..010 | availability-booking | UNIT-031..040 · INT-015..017/020/022 · API-018 · CONC-001/003/005/008/013 · E2E-003/008/009/014 | UNIT, INT, API, CONC, E2E | PR |
| SRS-RFQ-001..013 | rfq-offers | UNIT-041..045/054 · INT-018/019/040 · API-019/020/035/036 · CONC-002/007/009/010 · E2E-004/014 | UNIT, INT, API, CONC, E2E | PR |
| SRS-MAGIC-001..006 | rfq-offers | UNIT-046/047 · API-021/022 · CONC-004 · SEC-006/014 · E2E-007/018 | UNIT, API, CONC, SEC, E2E | PR |
| SRS-WA-001..009 | assisted-response, rfq-offers | UNIT-030/048/049 · API-034 · SEC-018 · E2E-005 | UNIT, API, SEC, E2E | PR |
| SRS-TRK-001..004 | quotation | UNIT-027..029 · INT-042 | UNIT, INT | PR |
| SRS-REV-001..008 | reviews | UNIT-050 · API-025 · CONC-012 · E2E-006 | UNIT, API, CONC, E2E | PR |
| SRS-ADM-001..013 | administration-audit | UNIT-051..053 · INT-021/038 · API-028/030 · MT-018/019 · E2E-009/012 · SEC-024 | UNIT, INT, API, MT, E2E, SEC | PR |
| SRS-NOT-001..006 | messaging-notifications | INT-027..032/040/045/046 · API-023 · LOAD-006 · SEC-017 | INT, API, LOAD, SEC | PR/NOC |

### 13.2 Requisitos no funcionales (SRS-NFR-*) → casos → etapa

| NFR (fuente) | Casos (abreviados) | Suite(s) | Etapa |
|---|---|---|---|
| PERF-001 (LCP) | E2E-026 | E2E | MERGE |
| PERF-002 (cotización < 3 s) | LOAD-002/008 | LOAD | NOC/REL |
| PERF-003 (búsqueda < 1 s) | LOAD-002/008 | LOAD | NOC/REL |
| PERF-004 (PDF < 5 s) | INT-049 + medición p95 en LOAD-002 | INT, LOAD | NOC |
| PERF-005 (500 usuarios, error < 1%) | LOAD-003/005 | LOAD | REL |
| PERF-006 (0 sobreventas; reserva < 2 s) | CONC-001..016 + LOAD-003 | CONC, LOAD | PR/REL |
| SEC-001..012 (seguridad) | SEC-001..031 (completo) | SEC | PR/NOC |
| PRIV-001..008 (Ley 1581) | UNIT-053 · SEC-022..024 · MT-028 (excepción declarada) | UNIT, SEC, MT | PR |
| AVL-001..005 (disponibilidad) | INT-041 · LOAD-005 · G-17 (restauración) | INT, LOAD, Gate | REL |
| SCAL-001 (stateless, 2 réplicas) | Suite E2E completa (E2E-001..028) ejecutada sobre topología 2 réplicas API + 2 workers en pre-release | E2E | REL |
| SCAL-002 (reglas solo backend) | API-018/019/027 con llamadas directas sin frontend + MT/API negativas | API, MT | PR |
| SCAL-003 (adaptadores con dobles) | INT-045..049 (suite sin red externa) | INT | PR |
| SCAL-004 (migraciones versionadas) | INT-001/002 | INT | PR |
| SCAL-005 (contratos documentados) | ARCH-007/008 + validadores del paquete (check_openapi/check_package en CI) | ARCH, CI | PR |
| SCAL-006 (taxonomía administrable) | UNIT-013 · INT-038 (sin despliegue) | UNIT, INT | PR |
| USA-001..008 (usabilidad/a11y) | E2E-019..023/025/027 | E2E | PR/MERGE |
| COMP-001..003 (navegadores) | E2E-019 (matriz Chromium/WebKit/Firefox; 360 px) | E2E | MERGE |
| OBS-001..006 (observabilidad) | API-039 · SEC-022 · LOAD-006 · G-19 | API, SEC, LOAD, Gate | PR/REL |

### 13.3 Riesgos críticos → suites que los cubren → etapa

| Riesgo | Suites responsables | Etapa |
|---|---|---|
| Fuga multi-tenant (R-RLS) | MT-001..028 (100% bloqueante) + SEC-011 + MT dentro de API negativas | PR |
| Carrera reservas/adjudicaciones (R-CONC) | CONC-001..016 (100% bloqueante) + INT-015..020 | PR |
| Duplicación de efectos (R-IDEM) | INT-033..037 + API-008..010 + CONC-005 | PR |
| Efectos externos fuera de transacción (R-OUTBOX) | INT-027..032 + ARCH-005/006 + LOAD-006 | PR/NOC |
| Credenciales Magic Link (R-MAGIC) | UNIT-046/047 + API-021/022 + SEC-006/014 + CONC-004 + E2E-007/018 | PR |
| OWASP (R-SEC) | SEC-001..031 + ZAP nocturno + matriz RBAC generada | PR/NOC |
| Rendimiento (R-PERF) | LOAD-001..008 + E2E-026 + SLO de G-19 | MERGE/NOC/REL |

### 13.4 Módulos SAD §4.1 → cobertura por nivel

| Módulo | UNIT | INT | API | CONC/MT | E2E | SEC |
|---|---|---|---|---|---|---|
| identity-access | UNIT-004..008 | INT-048 | API-005/006 | MT-026 | E2E-015 | SEC-001..003/012 |
| organizations | UNIT-004..008 | INT-010 | API-006/027 | MT-001..009/026/027 | E2E-015/020/024 | SEC-004/011 |
| provider-catalog | UNIT-009..013 | INT-024/047 | API-031/032/012 | MT-021 | E2E-001/013/019 | SEC-016/025 |
| taxonomy-templates | UNIT-013 | INT-026 | API-012 | MT-011..017 | — (admin) | SEC-019 |
| event-management | UNIT-014..018 | INT-025/026 | API-024/012/040 | MT-001..005 | E2E-002 | SEC-004 |
| quotation | UNIT-019..030 | INT-015..017/023/026/049 | API-037/040/013 | CONC-013/014 | E2E-002/011 | SEC-005 |
| availability-booking | UNIT-031..040 | INT-015..017/020/022 | API-018 | CONC-001/003/005/006/008/013 + MT-008 | E2E-003/008/009/014 | SEC-005/006 |
| rfq-offers | UNIT-041..047/054 | INT-018/019/038 | API-019/020/021/022/035/036 | CONC-002/004/007/009/010 + MT-024/025 | E2E-004/007/014/018 | SEC-014/017 |
| assisted-response | UNIT-048/049 | — | API-034 | — | E2E-005 | SEC-018 |
| messaging-notifications | UNIT-030 | INT-027..032/040/045/046 | API-023/011 | MT-022/023 | E2E-017 | SEC-017/022 |
| reviews | UNIT-050 | — | API-025 | CONC-012 + MT-028 | E2E-006 | SEC-020 |
| administration-audit | UNIT-051..053 | INT-021/038/044 | API-028/030 | MT-018/019 | E2E-009/012 | SEC-024/029 |

**Criterio de completitud de la matriz:** toda fila de `Trazabilidad.md` (13 áreas SRS) tiene al menos una suite; los 46 NFR están en §13.2; los 7 riesgos del mapa en §13.3; los 12 módulos en §13.4; todo caso `TC-*` del documento pertenece a exactamente una etapa CI de las tablas de §2.3.

## Sección 14 — Registro de Decisiones Autónomas de QA (`DT-nn`)

Decisiones tomadas de forma autónoma por este documento por no estar fijadas en las fuentes (el resto de la estrategia proviene directamente de ADR-TEST-001..006, SAD §16, TDD §10.3, DDD §19, SRS §14 y UXUI §11.5).

| ID | Decisión | Justificación técnica |
|---|---|---|
| DT-01 | Umbrales de cobertura global (≥ 80% líneas / ≥ 75% ramas) y `shared/` (≥ 85%) además de los mínimos por capa de ADR-TEST-006 (domain ≥ 90, application ≥ 80) | ADR-TEST-006 fija por capa pero no global; se elige un gate global conservador + regla "no descendente" para evitar erosión progresiva |
| DT-02 | Supertest como cliente HTTP y `openapi-response-validator` cargando el YAML del repo para validar respuestas contra el contrato | Las fuentes fijan el contrato (OpenAPI primero, ADR-API-001) pero no las librerías de prueba; validar en runtime contra el artefacto real evita duplicar esquemas |
| DT-03 | Testcontainers-js orquesta PostgreSQL (`postgres:15` y `postgres:16`, matriz) y `redis:7`; BD siempre por migraciones reales y roles `pe_*` | ADR-TEST-002 exige PostgreSQL 15/16 y Redis reales desechables; la versión de Redis y el mecanismo de orquestación no estaban fijados |
| DT-04 | MSW como tecnología de stubs wire-level para Auth0 (JWKS), SendGrid y Cloudinary | ADR-ARCH-006/ADR-TEST-002 exigen "dobles de puertos sin red externa" sin fijar tecnología; MSW intercepta a nivel HTTP sin tocar la pila de dominio |
| DT-05 | k6 para los 4+ perfiles de carga y OWASP ZAP baseline como DAST nocturno | Ningún documento fija herramienta de carga/DAST; k6 permite thresholds como criterio de fallo automático nativo (exigido por el enfoque determinista) |
| DT-06 | Cifras exactas de los perfiles: Smoke 5 VU/2 min; Baseline 50 VU/20 min; Spike 500 VU (rampa 2 min, meseta 5); Stress hasta 700 VU escalonado; Soak 120 VU/2 h; mezcla 80/20 | Derivadas de SRS-NFR-PERF-005 (500 simultáneos) y SLO de SAD §12.2; 50 VU baseline ≈ 10% del pico por regla práctica 10:1; Soak al 24% del pico para detectar fugas sin saturar |
| DT-07 | Presupuestos CI: local ≤ 3 min; PR ≤ 25 min (jobs paralelos); post-merge ≤ 60 min; nightly ≤ 3 h | Ninguna fuente fija presupuestos; elegidos para mantener feedback de agente < 30 min sin sacrificar la banda de integración real |
| DT-08 | El catálogo `TC-ARCH` vive como subsección de la Sección 5 | La estructura de 15 secciones de este documento no contempla una sección propia para arquitectura; ADR-TEST-001 las ejecuta en la misma etapa de Vitest que la integración |
| DT-09 | El chequeo anti-placeholder (`grep` de los tokens de marca) se ejecuta con exclusión de valores de enum entre backticks y de esta misma fila de definición | DEC-022 exige enums en MAYÚSCULAS; el estado de outbox/invitaciones colisiona con la palabra de marca en mayúsculas; la exclusión solo aplica a literales citados del dominio, no a prosa sin cita |
| DT-10 | Los 7 patrones de aislamiento de §8.3 se generan parametrizados por cada tabla clase (a) desde la clasificación del TDD §4.2, con test guardián de cobertura | ADR-TEST-004/TDD §10.3 exigen el barrido por tabla; generarlos evita 273 casos escritos a mano y garantiza que una tabla nueva sin patrones rompa el build |
| DT-11 | IDs de fixtures deterministas por UUIDv5 con namespace fijo por tenant A/B | El determinismo de datos (requisito del prompt) requiere IDs reproducibles; UUIDv5 evita colisiones sin secuencias frágiles |
| DT-12 | @axe-core/playwright con umbral 0 violaciones serious/critical en vistas 360×640 y 1280×800 | UXUI §8.5/QA-02 fija criterio y vistas; la librería no estaba fijada; el umbral es el del propio requisito WCAG 2.1 AA |
| DT-13 | El rate limiting se prueba contra el umbral configurado del ambiente de test (429 + `Retry-After`), no contra cifras productivas | El contrato declara el comportamiento (429) pero ninguna fuente fija umbrales productivos; acoplar la prueba a una cifra concreta haría el suite frágil |
| DT-14 | La matriz de trazabilidad (Sección 13) cita casos con notación abreviada sin el prefijo `TC-` | Mantiene la unicidad literal de los IDs oficiales (verificación global #2) sin sacrificar trazabilidad |
| DT-15 | Relojes: fake timers solo en unitarias; en integración se fijan `sla_expira_at`/`available_at`/fechas de estado por UPDATE directo | ADR-DATA-012 fija reloj UTC compartido; en pruebas deterministas el tiempo se fija en datos, nunca se espera al reloj real |
| DT-16 | La suite de concurrencia corre bloqueante en **todos** los PR (no solo cuando tocan módulos críticos) | ADR-TEST-003 la exige para PRs de capacidad/ofertas/idempotencia/bloqueos; se generaliza porque el costo (≈15 min paralelo) es menor que el riesgo de un PR "inocente" que rompa invariantes |
| DT-17 | SCAL-001 se verifica ejecutando la suite E2E completa sobre una topología de 2 réplicas API + 2 workers en pre-release | El requisito existe pero no definía mecanismo; usar la propia suite E2E como criterio evita un suite paralelo redundante |

## Sección 15 — Guía de Handoff para Agentes Implementadores de Pruebas

### 15.1 Estructura de carpetas (alineada con SAD §4.2 y ADR-TEST-001/002)

```
backend/
└── src/
    ├── prisma/migrations/                  # migraciones reales (00..11); `20_rls` en prisma/rls/
    ├── ...                                 # código (12 módulos por SAD §4.2)
    └── tests/
        ├── factories/                      # builders de §3.2 (seed* y build*)
        ├── fixtures/                       # datasets compartidos versionados (21 categorías, festivos CO, snapshots de ejemplo)
        ├── support/                        # arnés de Testcontainers
        ├── unit/                           # TC-UNIT (Vitest; sin BD/red)
        ├── integration/                    # TC-INT (PostgreSQL/Redis reales por Testcontainers)
        ├── multi-tenant/                   # TC-MT (patrones P1..P7 generados por tabla + canales API/secundarios)
        ├── concurrency/                    # TC-CONC (barrera sincronizada, N=20 × 100)
        ├── contract/                       # TC-API (Supertest + validador OpenAPI)
        ├── architecture/                   # TC-ARCH (dependency-cruiser + reglas; fixtures inválidos/válidos)
        ├── security/                       # TC-SEC (dirigidas) + reglas Semgrep propias
        ├── infra/                          # comprobaciones sobre el stack Compose levantado (fuera de CI de integración)
        ├── e2e/                            # TC-E2E (Playwright; specs por sección SRS §8: section-8-1.spec.ts …)
        └── load/                           # TC-LOAD (scripts k6 con thresholds; protegidos por CODEOWNERS)
```

**Convención de rutas (ADR §2.5; CICD `DISC-11`):** en todo este documento, `tests/<carpeta>` significa `backend/src/tests/<carpeta>`.

### 15.2 Dependencias npm a instalar (devDependencies del paquete de pruebas)

`vitest`, `@vitest/coverage-v8`, `dependency-cruiser`, `supertest`, `openapi-response-validator` (+ `yaml` para cargar el contrato), `@testcontainers/postgresql`, `@testcontainers/redis`, `msw`, `@playwright/test`, `@axe-core/playwright`, `semgrep` (CLI externa invocada por script), `gitleaks` (CLI externa), `esbuild`/`tsx` según runner de k6; k6 se instala como binario externo (no es paquete npm). Versiones: fijar por lockfile (ADR-STACK-003); sin sustituir el stack aprobado (ADR-STACK-001).

### 15.3 Scripts de `package.json`

Los nombres `test:*` son los de este documento. `verify:adrs` es **literal** el de `ADR §6.1` y no se redefine aquí. `test:sec` ejecuta solo las pruebas Vitest, sin red; Semgrep, `npm audit` y gitleaks corren en los jobs de CICD §7 (`DISC-12`). La guarda es `Tools/adr-guard/cli.ts`.

```json
{
  "scripts": {
    "test:unit": "vitest run --config backend/vitest.config.ts backend/src/tests/unit --coverage.enabled --allowOnly=false --passWithNoTests=false --retry=0",
    "test:int": "vitest run --config backend/vitest.config.ts backend/src/tests/integration --allowOnly=false --passWithNoTests=false --retry=0",
    "test:api": "vitest run --config backend/vitest.config.ts backend/src/tests/contract --allowOnly=false --passWithNoTests=false --retry=0",
    "test:mt": "vitest run --config backend/vitest.config.ts backend/src/tests/multi-tenant --allowOnly=false --passWithNoTests=false --retry=0",
    "test:conc": "vitest run --config backend/vitest.config.ts backend/src/tests/concurrency --allowOnly=false --passWithNoTests=false --retry=0",
    "test:sec": "vitest run --config backend/vitest.config.ts backend/src/tests/security --allowOnly=false --passWithNoTests=false --retry=0",
    "test:arch": "vitest run --config backend/vitest.config.ts backend/src/tests/architecture --allowOnly=false --passWithNoTests=false --retry=0",
    "test:infra": "vitest run --config backend/vitest.config.ts backend/src/tests/infra --allowOnly=false --passWithNoTests=false --retry=0",
    "test:e2e": "playwright test",
    "test:e2e:smoke": "playwright test backend/src/tests/e2e/srs-section-8 --project=chromium",
    "test:load": "k6 run backend/src/tests/load/smoke.js && k6 run backend/src/tests/load/baseline.js",
    "test:load:full": "k6 run backend/src/tests/load/baseline.js && k6 run backend/src/tests/load/spike.js && k6 run backend/src/tests/load/stress.js && k6 run backend/src/tests/load/soak.js"
  }
}
```

### 15.4 Reglas para los workflows de GitHub Actions (implementación en `Plan0002_Test_Harness_Setup.md`)

Los nombres de job y de checks obligatorios son los de `ProveeEventos_CICD.md` §7 (que conserva los del ADR y da la correspondencia con los *gates*); los de la lista siguiente describen el alcance de cada *gate*.

1. **PR pipeline** (jobs paralelos): `lint-types` (G-01) · `unit` (G-02) · `arch` (G-03) · `api` (G-04) · `integration` (G-05, matriz PG15/PG16, servicios Testcontainers en runner) · `multi-tenant` (G-06) · `concurrency` (G-07) · `security-static` (G-08) · `e2e-smoke` (G-09) · `anti-sabotaje` (G-10, compara nº de IDs `TC-*` con `main` y aplica CODEOWNERS). Un PR no se mergea con ningún job rojo; `retry:0` global.
2. **Post-merge**: build reproducible → migraciones desde cero en ambiente efímero → suite E2E completa + axe (G-11) → carga smoke (G-12) → verificación N-1 (G-13).
3. **Nightly (schedule)**: ZAP baseline (G-16 parcial), mezcla de concurrencia 10 min (CONC-015), Baseline de carga, re-escaneo de dependencias; fallo → issue automático con salida de thresholds k6.
4. **Pre-release**: workflow manual/etiquetado con G-14..G-19, incl. topología de 2 réplicas para SCAL-001 (DT-17) y restauración PITR.
5. **Secretos y entornos**: credenciales de test solo por variables de entorno cifradas; ningún job con credenciales productivas; `concurrency` e `integration` fijan `DATABASE_URL` con rol `pe_api`/`pe_worker` de la BD efímera.
6. **Caché**: Playwright browsers y contenedores pre-descargados para mantener los presupuestos de DT-07.
7. Todo job imprime, como artefacto, el resumen de conteos por categoría (formato de la cabecera de este documento) para que la comparación anti-sabotaje (AS-08) sea determinista.

### 15.5 Checklist de aceptación para el agente implementador de cada suite

- [ ] Cada caso `TC-CAT-NNN` de este documento tiene ≥ 1 `it()`/`test()` con nombre que comienza por el ID (trazabilidad directa).
- [ ] Prohibiciones activas: sin `.skip/.only/.todo`, sin `retry`, sin `waitForTimeout` en E2E, sin mocks prohibidos (ADR-TEST-002), sin directivas de cobertura.
- [ ] Las precondiciones usan exclusivamente los builders de `tests/factories/` (§3.2); ningún caso siembra SQL ad-hoc fuera de factories excepto la fijación de tiempos (DT-15).
- [ ] Las aserciones son exactas (valor/código/SQLSTATE), nunca "no lanza" genérico.
- [ ] El caso queda registrado en el reporte de conteo por categoría y la cobertura no desciende.
