# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Naturaleza del repositorio

Este repositorio contiene el paquete de documentación de diseño de ProveeEventos (plataforma para que empresas organizadoras de eventos cotizen y contraten proveedores en Colombia) y, desde el Día 0 (2026-11-25), el **esqueleto de plataforma** del código (`backend/`, `frontend/`, Docker, linters y pruebas), sin lógica de negocio. Es un repositorio git.

**Para trabajar con código, lee primero `AGENTS.md`** (mapa de carpetas, comandos y reglas). El estado del arranque y lo pendiente están en `ProveeEventos_Day0_Report.md`. Los documentos se editan en español.

Carpetas auxiliares:
- `Reviews/`: revisiones del paquete; `Review_V1.md` originó `Plans/Plan0001.md`, `Review_V2.md` originó `Plans/Plan0003.md` y `Review_V3.md` originó `Plans/Plan0004.md`. Lo que no se adopta de una revisión se justifica en una sección al final de la propia revisión (Review V3 §9).
- `Plans/`: planes reanudables con checklist. Al reanudar un plan, se lee su sección 0 y su checklist; solo el orquestador marca las tareas. **Antes de crear o reanudar un plan, se consulta `Plans/INDICE.md`**: un número de plan identifica una ejecución, no un tema, y los números antiguos no se reutilizan (decisión `DB-18`).
- `ProveeEventos_ImplBacklog.md`: plan de desarrollo y backlog de implementación (23 épicas, 41 historias, 119 Issues `ISS-CODE`/`ISS-TEST` con paridad obligatoria, olas `Wave-0..13`, plan de release MVP en 2 etapas). Es el entregable de `Plans/Plan0001_ImplBacklog.md`; su auditoría cruzada es `ProveeEventos_CrossAudit_Report.md` (riesgos `RR-01..RR-09`).
- `Tools/check_openapi.py`: validador del contrato OpenAPI.
- `Tools/check_package.py`: validador de coherencia del paquete, con 12 chequeos (marcas de estado de decisiones, matriz PRD↔SRS en ambas direcciones, trazabilidad de operationIds, requisitos, eventos y entregas, IDs de decisión definidos, jobs de SAD §8.2, versiones declaradas y, sobre el backlog, estructura y paridad CODE↔TEST, `source_refs`/`depends_on` resueltos y cobertura del contrato y de los jobs). Su docstring lista las limitaciones aceptadas.
- `Trazabilidad.md`: matriz SRS-ID → contexto DDD → operationId → eventos → entrega.
- `Glosario.md`: glosario consolidado ES ↔ EN.

## Jerarquía de documentos

Cuando dos documentos se contradigan, prevalece en este orden (según `ProveeEventos_SAD.md` §1.2):

1. `ProveeEventos_PRD.md` — visión, alcance, stack de referencia, modelo de datos, fases.
2. `ProveeEventos_SRS.md` — requisitos funcionales y no funcionales con IDs estables `SRS-<AREA>-NNN`.
3. `ProveeEventos_SAD.md` — decisiones de arquitectura, módulos, consistencia, despliegue.
4. `ProveeEventos_DDD.md` — lenguaje ubicuo, bounded contexts, agregados, invariantes, eventos de dominio.
5. `ProveeEventos_API_Spec.yaml` — contrato HTTP (OpenAPI 3.1.0, versión 1.4.0, prefijo `/api/v1`, ~123 paths).
6. `Decisiones.md` — registro de decisiones de producto y técnicas: `DEC-001..037` y `TEC-001..012` aprobadas (las de §4b, con fecha 23-11-2026). `TEC-013` (contrato 1.4.0) está pendiente de aprobación.

Para cambiar un comportamiento, actualiza primero el SRS; luego el SAD/DDD y el YAML; y registra la decisión en `Decisiones.md` si implica una elección. Las decisiones aprobadas están integradas en PRD, SRS, SAD, DDD y API Spec con su justificación. **Regla de marca para decisiones futuras:** una decisión nueva se registra en `Decisiones.md` como propuesta, con su fila "Pendiente de aprobación" en §7 (o, si es un ADR, con "**Estado:** … pendiente de aprobación" en SAD §17). Toda línea de los documentos que la cite debe contener la palabra "pendiente" ("(propuesta, pendiente de aprobación — DEC-0xx)" o la forma corta "DEC-0xx, pendiente"). `Tools/check_package.py` (chequeo 1) obtiene el conjunto de pendientes de esos registros. Exige la marca mientras la decisión está pendiente y señala las marcas sobrantes cuando ya está aprobada. Al aprobarla, se cambia su estado en el registro y se retiran sus marcas. Si se rechaza, hay que revertir las secciones que la citan (búscalas con `grep -n "DEC-0xx" *.md *.yaml`). Los `SRS-DEC-xxx` de SRS §13 son locales del SRS y no equivalen a los `DEC-xxx` de `Decisiones.md`.

Si algo no está en las fuentes, el SAD lo marca como **"Propuesta SAD"**. Una decisión nueva se presenta como propuesta pendiente de aprobación, nunca como hecho.

## Convenciones de los documentos

- Redacción en español; nombres de código de dominio y eventos de dominio en inglés (`Organization`, `Booking`, `RfqRequest`, `Offer`, `Award`, `BookingClosed`…) según DDD §3.6.
- Enums (DEC-022): estados, roles y valores de negocio en español, en MAYÚSCULAS y sin tildes (`CONFIRMADO`, `CANCELACION_EN_REVISION`, `RETENIDA`, `PROPIETARIO`, `COORDINADOR_RESTRINGIDO`, `AMBOS`). Se conservan los códigos técnicos de modalidad, canal y origen (`INSTANT_BOOK`, `E_RFQ`, `EMAIL_FORM`, `WHATSAPP_IA_ASISTIDO`) y los códigos de error de la API (`CAPACITY_EXHAUSTED`…). Vocabulario único de roles: `PROPIETARIO`, `ADMIN_EMPRESA`, `COORDINADOR`, `COORDINADOR_RESTRINGIDO` (membresía) y `PROVEEDOR`, `ADMIN_PLATAFORMA` (globales).
- Palabras normativas en SRS: MUST/DEBE, SHOULD/DEBERÍA, MAY/PUEDE.
- Los IDs son estables: no los renumeres; si un elemento se retira, márcalo, no lo reutilices. Espacios de IDs:
  - `SRS-<AREA>-NNN` (requisitos funcionales) y `SRS-NFR-<AREA>-NNN` (no funcionales, incluido `SRS-NFR-SCAL-*`), en el SRS;
  - `SRS-DEC-NNN`: aclaraciones locales del SRS §13, no equivalen a `DEC-*`;
  - `DEC-NNN` (producto) y `TEC-NNN` (técnicas), en `Decisiones.md`;
  - `ADR-NNN`, en SAD §17: ADR-001..022 aprobados (ADR-016..022, el 23-11-2026);
  - `RF-*` y `RNF-*`, en el PRD; RF-COT-04 y RF-INT-04 son Fase 3.
- Reglas de datos fijadas en la sección "Convenciones" del SRS y en el contrato OpenAPI: UUID opacos, timestamps ISO 8601 en UTC, importes como decimal exacto (nunca float binario), moneda COP.
- Todos los documentos (PRD, SRS, SAD, DDD y Decisiones) llevan una tabla **Historial de versiones**; actualízala cuando cambies su contenido. Versiones vigentes: PRD 2.4, SRS 1.3, SAD 1.4, DDD 1.4, API 1.4.0, Decisiones 1.6.

## Arquitectura objetivo (planeada, no implementada)

- **Estilo:** monolito modular en Node.js 20+ con Express, más un proceso **worker** separado (BullMQ sobre Redis) que reutiliza los mismos módulos. No se propone microservicios.
- **Unidades desplegables:** Web (Next.js 14+, App Router, Tailwind + shadcn/ui), API (REST stateless), Worker, PostgreSQL 15+ (con Prisma), Redis (colas y caché no autoritativa).
- **Externos detrás de adaptadores:** Auth0 (identidad; los roles, tenant y permisos los resuelve ProveeEventos), SendGrid (email), Cloudinary (medios), WhatsApp Click-to-Chat (`wa.me`, sin confirmación de entrega), Google Maps (opcional), PDF (React-PDF por defecto; Puppeteer solo si el prototipo lo exige, DEC-016).
- **Módulos backend** (SAD §4.1, TEC-010): 12 módulos, uno por Bounded Context del DDD: identity-access, organizations, provider-catalog, taxonomy-templates, event-management, quotation (incluye el seguimiento por ítem), availability-booking (incluye `ConfirmBooking` y el registro de comisiones), rfq-offers, assisted-response, messaging-notifications, reviews, administration-audit.
- **Capas por módulo:** `domain` (sin Express, Prisma, Redis ni SDKs) → `application` (casos de uso, define su transacción) → `infrastructure` (implementa interfaces del dominio) → `http` (DTO y mapeo de errores, sin reglas de negocio). Un módulo no lee tablas internas de otro; usa interfaces de aplicación o eventos. No hay dependencias circulares. La matriz de dependencias permitidas está en SAD §4.4.
- **Carpeta `shared/`:** solo conceptos transversales estables (IDs, Money, errores base, reloj, correlation ID, puerto de auditoría). No debe convertirse en un cajón de entidades de negocio.
- **Navegador → BFF → API:** el navegador no llama a la API con token; el servidor Next.js mantiene la sesión y envía el token y `X-Organization-Id` (organización activa, TEC-006).

### Reglas de consistencia (las que atraviesan varios documentos)

- **PostgreSQL es la única autoridad** de capacidad, reservas, adjudicaciones y comisiones. Redis nunca decide una reserva.
- **`ConfirmBooking` único** (SAD §7.5, TEC-009): Instant Book y adjudicación e-RFQ consumen capacidad con el mismo caso de uso. Asegura las filas de capacidad (`INSERT … ON CONFLICT`), bloquea en orden fijo —fila del proveedor en modo compartido (`FOR SHARE`, DEC-036) y después, con `SELECT … FOR UPDATE`, capacidad global por fecha ascendente → paquete—, revalida y consume. Capacidad global de 2 por fecha más capacidad por paquete (DEC-006), en cada fecha local que toca el servicio (DEC-025). Sin capacidad responde `409 CAPACITY_EXHAUSTED`. Idempotencia con `Idempotency-Key`. Sin llamadas externas dentro de la transacción.
- **Adjudicación e-RFQ** (SAD §7.2): restricción única en base de datos para un solo ganador, más consumo de capacidad en la misma transacción. El frontend no es mecanismo de exclusión.
- **Magic Link** (SAD §7.3, TEC-008): solo se guarda hash del token; el enlace es `/r#<token>` y el token viaja en el cuerpo de `POST /magic-links/form|response`, nunca en la ruta; consumo y creación de oferta en una misma transacción; el token nunca va a logs ni a `Referer`.
- **Transactional Outbox** (SAD §7.4): los efectos externos (emails, notificaciones) se insertan en la misma transacción de negocio y los procesa el worker. Los consumidores deben ser idempotentes.
- **Colas BullMQ** (SAD §8.2): `outbox`, `email`, `rfq-sla`, `notifications`, `documents`, `scheduler` (transiciones temporales y recordatorios), `maintenance`. El reloj de SLA es `sla_expira_at` en PostgreSQL; un job tardío no debe alterar solicitudes ya terminales.
- **Contrato API** (SAD §10.6–§10.8): errores `problem+json` con `ErrorCode` y su tabla HTTP, `ETag`/`If-Match`, exenciones de `Idempotency-Key` (TEC-011) y un solo modelo de paginación por operación: página o cursor (TEC-012).
- **Suspensión de proveedor:** las contrataciones futuras pasan a revisión, no se cancelan automáticamente (SRS-ADM-013; DEC-034). Todos los efectos se aplican en una sola transacción, que bloquea la fila del proveedor con `FOR UPDATE` (SAD §7.6; DEC-036). La organizadora decide dentro de una ventana (lo primero entre 72 h y el inicio del servicio) y el proveedor suspendido conserva solo la consulta y las acciones de ciclo de sus contrataciones vigentes.
- **Cierre de rondas e-RFQ** (DEC-035): una solicitud respondida sin oferta vigente y con SLA vencido pasa a `NO_ADJUDICADO`; el destino del ítem sigue la precedencia de SRS §9.3.
- **Multi-tenant:** aislamiento por tenant en cada acceso; autorización siempre en backend; los datos históricos se conservan como snapshots (DEC-018).
- **Ciclos de estado** de Provider Verification (y cuenta, DEC-031), RFQ, Event, Booking (DEC-023), Item Tracking, Quotation y Offer están en DDD §15 y SRS §9 (§9.6 y §9.7 para cotización y oferta). Las RFQ no se reabren: se crea una nueva ronda (DEC-026).

## Decisiones y versiones

Las decisiones DEC-001..018 y TEC-001..005 de `Decisiones.md` están aprobadas (se adoptó la propuesta recomendada) e integradas en los demás documentos. Las DEC-019..034, TEC-006..012 y ADR-016..022 se aprobaron el 23 de noviembre de 2026 y están aplicadas en todos los documentos; `Decisiones.md` §6 conserva de qué hito depende cada una. DEC-035 (cierre de rondas e-RFQ), DEC-036 (operación de la revisión por suspensión) y DEC-037 (plazos de solicitudes de titulares) se aprobaron con fecha 23-11-2026 y están aplicadas. La única decisión pendiente es TEC-013 (contrato 1.4.0). Los plazos legales (incluidos los de DEC-037), fiscales y contables siguen requiriendo validación profesional en Colombia. El PRD vigente es la **v2.4** (`ProveeEventos_PRD.md`), consolidado en v2.2 (DEC-019); las referencias históricas a "PRD v2.2" apuntan a ese mismo archivo.

## Qué puede necesitar una sesión futura

- Verificar que un ID citado existe antes de referenciarlo, por ejemplo con `grep -n "SRS-BOOK-003" *.md`.
- Revisar que los cambios en el YAML y en el DDD/SAD sigan siendo coherentes con el SRS y actualizar `Trazabilidad.md`.
- `Plans/Plan0001.md` (Review V1), `Plans/Plan0003.md` (Review V2) y `Plans/Plan0004.md` (Review V3) están completos. El siguiente trabajo planificado es `Plans/Plan0002.md` (modelo de datos, UX, notificaciones, pruebas, amenazas, operación y backlog); sus tareas P00 y P10 (decisiones) están completas y sigue P01. `Plans/Plan0006_BacklogGaps.md` cierra los riesgos `RR-04` y `RR-09` de la auditoría del backlog; `Plans/INDICE.md` dice qué número corresponde a qué plan y qué números quedan reservados.
- El código sigue la estructura de SAD §4.2 y las reglas de capas de SAD §4.3 (verificadas por `npm run verify:adrs`), no una organización por tipo técnico (`controllers/`, `services/`).
- Validar el contrato OpenAPI con `python3 -I Tools/check_openapi.py ProveeEventos_API_Spec.yaml` (refs, operationId, respuestas 4xx, Idempotency-Key).
- Validar la coherencia del paquete con `python3 -I Tools/check_package.py` (exit 0 esperado) después de cualquier cambio en SRS, SAD, YAML, DDD, `Trazabilidad.md` o `ProveeEventos_ImplBacklog.md`; un requisito u operación nuevos necesitan su fila en `Trazabilidad.md` y en la matriz del SRS §12; un job nuevo de SAD §8.2, su anotación "(job: <nombre exacto>)"; y un cambio de versión, actualizar todas las referencias a la versión vigente.
