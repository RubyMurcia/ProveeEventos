# ProveeEventos — Reporte de Auditoría Cruzada Pre-Vuelo

## Cabecera y Dictamen Final

| Campo | Valor |
|---|---|
| Fecha | 2026-11-25 |
| Documentos auditados | 17 (Sección 1) |
| Hallazgos detectados | 41 (31 corregidos y 10 residuales) |
| Correcciones aplicadas en disco | 31 (`FIX-01`..`FIX-31`) en 5 documentos y sus partes |
| Riesgos residuales bloqueantes para Bootstrap Día 0 y materialización | 0 |
| Condiciones antes de activar el Ruleset e integrar PR sin intervención humana | 1 (`RR-01`) |
| **Dictamen** | **`GO`** para el Bootstrap Día 0 y la materialización de los 101 Issues |

**Alcance del dictamen:** no certifica que el MVP esté completo (`RR-04`) ni que los Issues de Etapa 2 estén revisados en detalle (`RR-05`). No existe código: nada se ha compilado ni ejecutado.

---

## Sección 1 — Inventario de Documentos Auditados

| Archivo | Rol | Estado previo | Modificado |
|---|---|---|---|
| `ProveeEventos_PRD.md` | Producto | Sin deriva detectada en lo comprobado | No |
| `ProveeEventos_SRS.md` | Requisitos | Sin deriva detectada en lo comprobado | No |
| `ProveeEventos_SAD.md` | Arquitectura | Sin deriva detectada en lo comprobado | No |
| `ProveeEventos_DDD.md` | Dominio | Sin deriva detectada en lo comprobado | No |
| `ProveeEventos_TDD.md` | Modelo físico | Con deriva | Sí |
| `ProveeEventos_API_Spec.yaml` | Contrato | Sin deriva detectada en lo comprobado | No |
| `ProveeEventos_ADRs.md` | Normativa | Con deriva | Sí |
| `ProveeEventos_UXUI.md` | Interfaz | Sin deriva detectada en lo comprobado | No |
| `ProveeEventos_TESTs.md` | Pruebas | Con deriva | Sí |
| `ProveeEventos_CICD.md` | Operación | Con deriva | Sí |
| `ProveeEventos_ImplBacklog.md` | Backlog | Con deriva | Sí |
| `proveeeventos.prisma` | Esquema | Sin deriva detectada en lo comprobado | No |
| `proveeeventos.sql` | Anexo SQL | Sin deriva detectada en lo comprobado | No |
| `Decisiones.md` | Decisiones | Sin deriva detectada en lo comprobado | No |
| `Trazabilidad.md` | Matriz | Sin deriva detectada en lo comprobado | No |
| `Glosario.md` | Glosario | Sin deriva detectada en lo comprobado | No |
| `CLAUDE.md` | Guía | Desactualizado (RR-09), no editado | No |

También se editaron las partes `Plans/Plan0001_CICDs_work/partes/{07_ci,12_decisiones_handoff}.md` y `Plans/Plan0005_work/tdd/00_00_control_inventario.md`. No se cambiaron números de versión ni historiales: este reporte es el registro de los cambios. La concatenación de las partes del TDD ya difería del TDD antes de esta auditoría.

---

## Sección 2 — Resumen de las 8 Matrices de Auditoría

| # | Auditoría | Estado | Evidencia |
|---|---|---|---|
| 1 | Inventario y salud | PASS CON CORRECCIONES | Sin marcadores sin resolver (`PENDIENTE` es valor de enum); 22 enlaces sin roturas; FIX-01, 27 |
| 2 | Datos, contratos y dominio | PASS CON CORRECCIONES | 55 enums Prisma, contrato y UI alineados; TDD y Prisma: 72 tablas sin diferencias de columnas ni nulabilidad; 39 tablas con RLS; FIX-25, 28 |
| 3 | UI, API y datos | PASS CON CORRECCIONES | Sin operaciones ni rutas inexistentes; 283 campos sin discrepancia real; roles acordes a SRS-AUTH-009. Las rutas erróneas estaban en el backlog (FIX-08) |
| 4 | ADRs, CI/CD y pruebas | PASS CON CORRECCIONES | `verify:adrs` en CI y DoD; exclusiones de Etapa 1 intactas; FIX-04, 20–22, 31 |
| 5 | Backlog y concurrencia | PASS CON CORRECCIONES | Sección 4 |
| 6 | Entorno y servicios | PASS CON CORRECCIONES | Catálogo de 89 variables coherente; Mailpit presente; FIX-23, 24, 26 |
| 7 | Correcciones quirúrgicas | PASS | `check_package.py` y `check_openapi.py` con salida 0; YAML y JSON incrustados revisados parsean; sin tablas irregulares ni bloques desbalanceados |
| 8 | Reporte | PASS | Este documento |

---

## Sección 3 — Registro de Correcciones Aplicadas

| ID | Severidad | Categoría | Documentos involucrados | Inconsistencia detectada | Regla de precedencia | Cambio en disco |
|---|---|---|---|---|---|---|
| FIX-01 | Baja | Referencias | TDD, ADRs, parte TDD | Referencia a `Reviews/Review_V4.md`, inexistente (TDD:11; ADRs inventario y H-04) | Existencia en disco | Se cambió a `Reviews/ReviewTDD_V4.md` |
| FIX-02 | Crítica | Backlog/YAML | ImplBacklog | Metadatos de `ISS-CODE-019` ilegibles (`: ` sin comillas) | Esquema §3.2 | Valor entrecomillado; 101/101 parsean |
| FIX-03 | Crítica | Estados | ImplBacklog | 99 Issues con `depends_on` nacían `status:ready` | Backlog §3.1 | `status:backlog`; solo `ISS-CODE-001` queda `ready` (005 `needs-human`) |
| FIX-04 | Crítica | Bootstrap/CI | ImplBacklog, CICD §7.6 | Activar el Ruleset tras `ISS-CODE-005` bloqueaba todo PR: suites `conc`, `sec`, *e2e smoke* y carga vacías con `passWithNoTests: false` | ADR-GOV-007, ADR-TEST-006 | Activación cuando los 5 checks pasen en `main`; hasta entonces integra una persona; pruebas base en TEST-004/006/009; `TC-MT` a `multi-tenant/`; hitos M0/M1 |
| FIX-05 | Crítica | Dominio | ImplBacklog | `ISS-CODE-019` cerraba la contratación sin `SERVICIO_REALIZADO` ni UI de proveedor | SRS-BOOK-008/009 | Dos pasos (`MARCAR_REALIZADO`, `CONFIRMAR`), `SCR-051/052`, dependencia de 011 |
| FIX-06 | Crítica | Seguridad/flujo | ImplBacklog | Magic Link sin derivación: el worker no podía construir el enlace | ADR-SEC-004 R1/R2 | Derivación HMAC en 016/017 y ruta `shared/security/magic-link`; consumidor del despacho |
| FIX-07 | Crítica | Huecos Etapa 1 | ImplBacklog | Sin dueño del esqueleto web ni registro de rutas de módulos | SAD §4.2, CICD §5 | `ISS-CODE-006` crea el esqueleto y carga módulos por convención |
| FIX-08 | Alta | UI/rutas | ImplBacklog | `(app)/x` no produce `/app/x`; faltaban `/api/auth`, `middleware`, `/cuenta/estado`, selector, ofertas, contrataciones, plantillas | Rutas UXUI §4 | `allowed_paths` alineados en ambas etapas |
| FIX-09 | Alta | Módulos E1 | ImplBacklog | 012, 016 y 019 contradecían la propiedad de módulos (verificación, ronda, comisión, Bid Tabulation, seguimiento) | SAD §4.1/§4.4, TDD | Rutas y alcance corregidos (`quotation/rfq-launch`, `provider-catalog/verification`, etc.) |
| FIX-10 | Alta | Módulos E2 | ImplBacklog | 025, 034, 037, 039, 040, 045 y 051 sin ruta al módulo escritor | SAD §4.1/§4.4 | Subcarpetas añadidas y nota de propiedad; prohibida de 051 ajustada |
| FIX-11 | Alta | Seeds | ImplBacklog | `ISS-CODE-023` consumía datos que creaba 024, posterior | DAG | Datos demo en `ISS-CODE-012`; 024 amplía |
| FIX-12 | Alta | Datos | ImplBacklog | El registro no asignaba plan; la primera ronda no podía validar cupo | TDD `registerOrganization`, F3 | `ISS-CODE-008` asigna `PRUEBA` y siembra planes |
| FIX-13 | Alta | Archivos base | ImplBacklog | Sin dueño: `playwright.config.ts`, esqueleto ESLint, `instrumentation.ts`, arnés, cliente BD, factories, `unit/shared`, dependencias npm, `include` de Vitest | CICD §13, ADR §6.1 | Asignados en `ISS-CODE-001/003/004/006` y `ISS-TEST-004/006/008` |
| FIX-14 | Alta | Criterios imposibles | ImplBacklog | 002, 012, 015, TEST-002 y TEST-015 exigían piezas posteriores | `depends_on` | Criterios acotados; TEST-002 (Wave-1) y TEST-015 (Wave-3) con dependencia |
| FIX-15 | Media | Arranque | ImplBacklog | `verify:*`/builds exigidos antes de existir | DoD | Regla «no aplicable» en Wave-0/1 |
| FIX-16 | Alta | Pruebas | ImplBacklog | Suites que usan el stack dentro de `integration/` (fallarían en CI) | CICD §7 | Movidas a `tests/infra/` (`test:infra`); Mailpit en `infra/email` |
| FIX-17 | Alta | Colisión | ImplBacklog | Wave-0: `ISS-TEST-001` y `ISS-TEST-003` compartían `unit/config` | Prompt Aud. 5 | Ruta de TEST-001 acotada |
| FIX-18 | Alta | DAG | ImplBacklog | `ISS-CODE-040` (Wave-8) dependía de 036 (Wave-9) | DAG | 040 y su par a Wave-10; diagrama y tablas |
| FIX-19 | Media | DAG/metadatos | ImplBacklog | `blocks` no era inverso de `depends_on`; faltaban 002→004 y 011→019; regla de olas contradictoria | §3.2/§5 | `blocks` regenerado (sin el par), diagramas, matriz §8, regla y M5 |
| FIX-20 | Alta | Rutas de prueba | ImplBacklog | `TC-API` en `tests/api/` | ADR §2.5, DISC-11 | `tests/contract/` |
| FIX-21 | Alta | Scripts | TESTs §15 | Rutas, `test:sec`, `verify:adrs` y guarda contradecían ADR/CICD | ADR §2.5/§6.1, DISC-11/12 | §15.1, §15.3 y nota en §15.4 |
| FIX-22 | Media | Scripts | CICD §13.2, ImplBacklog | `test:arch` ausente; `test:infra` sin definir | TESTs §15.3 | Añadidos |
| FIX-23 | Media | Entorno | CICD §13.4 | Sin contrato de URLs e identidades E2E | CICD §3.3/§5.6 | Nueva §13.4 sin variables nuevas |
| FIX-24 | Media | Entorno | ImplBacklog | Esquema parcial de CICD §3.4 sin instrucción de completarlo | CICD §3.2 | `ISS-CODE-003` lo completa |
| FIX-25 | Media | Cifras | TESTs, ImplBacklog | 93 modelos/48 enums (72/55), 93 CHECK (91), 8 públicas (9), 6 exenciones (7) | Prisma, SQL, OpenAPI, ADR-API-004 | Corregidas |
| FIX-26 | Media | Docker | ImplBacklog | 17 servicios citados | CICD §5.4 | 18 |
| FIX-27 | Media | Trazabilidad | ImplBacklog | Referencias con `?`/`(no)` y casos de Etapa 2 en Etapa 1 | TESTs | Retirados o corregidos |
| FIX-28 | Media | Contrato | ImplBacklog | Etapa 1 usaba 3 operaciones de 1.4.0 no aprobado | Decisiones TEC-013 | Condicionadas («pendiente»); E1 no depende de ellas |
| FIX-29 | Media | Contrato/ADR | ImplBacklog | `cloneEvent` para crear desde plantilla; `verify:arch` descrito como dependency-cruiser | OpenAPI, ADR §6.1 | `createEvent` con `templateId`; criterio corregido |
| FIX-30 | Baja | Pantallas | ImplBacklog | `SCR-005`, `SCR-024` y `SCR-048` sin Issue | UXUI | Asignadas a 007, 015 y 011 |
| FIX-31 | Baja | Versiones | TESTs, ImplBacklog | UXUI citado como 1.0 | UXUI 1.1 | Actualizado |

---

## Sección 4 — Concurrencia y Flujo End-to-End de Etapa 1

| Comprobación | Resultado (script sobre los metadatos) |
|---|---|
| Solapamientos de `allowed_paths` en la misma ola entre Issues sin relación de dependencia | 0 |
| Solapamientos entre `allowed_paths` y `forbidden_paths` de un mismo Issue | 0 |
| DAG | Sin ciclos, sin referencias inexistentes, sin dependencias hacia olas posteriores |
| Paridad `ISS-CODE` ↔ `ISS-TEST` | 49/49 simétricos; 026, 048 y 050 son excepciones justificadas en el backlog |
| Roles | Todos los usados están en la tabla maestra (`QA-Domain-Agent` definido y sin uso) |

Una ola puede contener cadenas de dependencias; la disjunción se exige entre Issues no relacionados. Entre olas distintas, dos Issues sin dependencia pueden compartir rutas: el agente debe comprobarlo al reclamar (§4.2 del backlog).

| Recorrido | Cadena de Issues | Estado |
|---|---|---|
| A. Cotización rápida → correo en Mailpit → formulario por enlace → cierre | 002, 004, 006–008, 010–019 (datos demo en 012); *smoke* en 023 | Trazado completo en el papel |
| B. Plantilla → grupo de proveedores → adjudicación → cierre | A + 020–022; *smoke* en 023 | Trazado completo en el papel |

Todos son ancestros de `ISS-CODE-023`. Quedan fuera de Etapa 1 los jobs «Inicio de servicio» y «Cierre automático»: el cierre usa las acciones del proveedor y de la organizadora.

---

## Sección 5 — Riesgos Residuales y Notas para Día 0

| ID | Tipo | Riesgo | Acción y momento |
|---|---|---|---|
| RR-01 | Condición | Plan y visibilidad de GitHub, proveedor del `ai-reviewer`, aprobadores y repositorio sin crear (`INFRA-P-14/15`; `ReviewsCICD_V1` R-01..R-04) | Decidir antes de M1; sin ello una persona integra todos los PR |
| RR-02 | Decisión | `TEC-013` (contrato 1.4.0) sin aprobar; el CI y los Issues usan ese archivo | Aprobar o rechazar antes de implementar la API |
| RR-03 | Diseño | `quick_quotation_options` no guarda campos que el contrato devuelve (`ReviewsUXUI_V1` R-05) | Antes de `ISS-CODE-014`: componer al leer o crear migración con aprobación |
| RR-04 | Cobertura MVP | Sin Issue que los cite: SRS-AUTH-004/008, TEN-001/002/005, CAT-002/005/006/007, EVT-005/007/008; `SCR-001, 004, 011, 016, 017, 022, 035, 044, 045, 046, 054, 058, 059`; unas 35 operaciones (paquetes, medios, categorías, entre otras); jobs de recordatorio, calificación, borradores y purga, además de los dos de cierre. Algunos pueden estar cubiertos sin cita | Añadir Issues con IDs nuevos antes de M5; paquetes y portafolio primero | **Resuelto** el 2026-11-25: `Plans/Plan0006_BacklogGaps.md` añade `EP-23` con `ISS-CODE/TEST-053..061` y parchea `source_refs`; el backlog v1.1 cita las 151 operaciones, los 180 requisitos, las 65 pantallas, los 12 jobs de SAD §8.2 y los 244 casos de prueba (`check_package.py` 12) |
| RR-05 | Limitación | Etapa 2 verificada solo con scripts (grafo, rutas, YAML), no leída Issue por Issue | Revisarla antes de promover sus Issues a `ready` |
| RR-06 | Gates | G-09 (12 escenarios), G-12 y G-14..G-19 no alcanzables en Etapa 1 | Aceptar el alcance parcial |
| RR-07 | CI/CD | Siguen abiertos `ReviewsCICD_V1` R-10 (cobertura sin línea base) y R-13..R-18; las secuencias nuevas de arranque no se han ejecutado | Resolver durante `ISS-CODE-005` |
| RR-08 | ADRs | Citan el contrato 1.3.0 y enmiendas pendientes (DISC-03/06/07) | Cambio documental conforme a ADR-GOV-001 |
| RR-09 | Mantenimiento | `CLAUDE.md` y `check_package.py` no cubren TDD, ADRs, UXUI, TESTs, CICD ni backlog; nombres `Plan0002/0003/0004` reutilizados | Actualizar y renombrar antes de crear esos planes | **Resuelto** el 2026-11-25: `CLAUDE.md` actualizado, `Tools/check_package.py` con 12 chequeos y `Plans/INDICE.md` fija la numeración de planes (`DB-18`); no se renombraron archivos para no romper citas |
| RR-10 | Producto/Legal | Contradicción de consulta del plan (G-24), reglas D-44/46/50 y validaciones legales pendientes | Producto y Legal antes de datos reales |

**Orden sugerido para el Día 0:** crear el repositorio → materializar Issues con las etiquetas del YAML → integrar `ISS-CODE-001..005` por una persona → completar la línea base (§4.8) → activar el Ruleset.
