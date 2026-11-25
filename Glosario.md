# ProveeEventos — Glosario consolidado

Este glosario unifica los glosarios de PRD §18, SRS §15, SAD §22 y DDD §22 con el lenguaje ubicuo de DDD §3. Los nombres de código siguen DDD §3.6 y los valores de enums siguen DEC-022. Cuando un término aparece en varias fuentes se fusiona en una fila y se citan todas, separadas por punto y coma. El símbolo `—` indica que el término no tiene nombre de código asignado. Las entradas que citan DEC-* o TEC-* remiten a decisiones aprobadas en `Decisiones.md`.

| Término (ES) | Nombre en código (EN) | Definición | Fuente |
|---|---|---|---|
| Adjudicación | `Award` | Decisión de seleccionar una oferta como ganadora para un ítem; un solo ganador por ítem. | DDD §3.4 |
| Administrador de empresa | `ADMIN_EMPRESA` | Usuario que administra la empresa y sus coordinadores según permisos vigentes. | DDD §3.1; DEC-022 |
| Administrador de plataforma | `ADMIN_PLATAFORMA` | Actor con permisos operativos de plataforma: moderación, verificación y administración de taxonomía. | DDD §3.1; DEC-022 |
| Aggregate | — | Cluster de objetos que protege invariantes transaccionales. | DDD §22 |
| Aggregate Root | — | Única entrada para modificar un agregado. | DDD §22 |
| Anti-Corruption Layer | — | Adaptador que protege el modelo propio de conceptos externos. | DDD §22 |
| Archivado | `archivedAt` | Marca de borrado lógico de borradores sin actividad durante 90 días; no es un estado del ciclo del evento. | SRS (SRS-EVT-007); PRD (RN-06) |
| Auditoría | — | Registro inmutable o protegido de una acción sensible con actor, recurso, instante y contexto. | DDD §3.5 |
| B2B | — | Business to Business; relación comercial entre empresas o profesionales. | PRD §18; SRS §15 |
| Bid Tabulation | — | Comparación normalizada de las ofertas recibidas para un ítem e-RFQ. | SRS §15; SAD §22; DDD §3.3 |
| Bounded Context | — | Límite explícito dentro del cual un modelo tiene un significado consistente. | DDD §22 |
| Capacidad diaria | — | Número máximo de eventos que el proveedor puede atender en una fecha (valor predeterminado del MVP: dos). | DDD §3.2; DEC-006 |
| Catálogo visible | — | Conjunto de proveedores activos y verificados que pueden aparecer en búsqueda. | DDD §3.2 |
| Categoría | — | Nivel superior de clasificación de servicios, administrado por la plataforma. | SRS §15; DDD §3.2 |
| Ciclo e-RFQ / ronda | `RfqCycle` | Conjunto lógico de solicitudes paralelas para un mismo ítem y ronda de comparación. | DDD §3.4 |
| Comando de confirmación de contratación | `ConfirmBookingCommand` | Comando del caso de uso único `ConfirmBooking` que usan la adjudicación e-RFQ y el Instant Book para consumir capacidad y crear la contratación (TEC-009). Contexto: BC-07 Availability & Booking. | SAD §7.5; DDD §11.1 |
| Comisión retenida | `RETENIDA` | Estado de comisión que aplica cuando hay una incidencia: la comisión queda retenida y no se devenga hasta su resolución. | PRD §9.2 (estados de comisión); DEC-002; DEC-023 |
| Confirmación de compromiso | `ConfirmBooking` | Caso de uso único que confirma una contratación por Instant Book o por adjudicación dentro de la misma transacción. | TEC-009 |
| Context Map | — | Mapa de relaciones e integración entre Bounded Contexts. | DDD §22 |
| Contratación | `Booking` | Registro del compromiso comercial confirmado, ya sea por Instant Book o por adjudicación e-RFQ. | DDD §3.4 |
| Coordinador | `COORDINADOR` | Usuario miembro que opera eventos, cotizaciones, solicitudes y seguimiento dentro de una empresa. | DDD §3.1; DEC-022 |
| Coordinador restringido | `COORDINADOR_RESTRINGIDO` | Coordinador limitado a los eventos asignados; no adjudica ni cancela contrataciones. | DDD §3.1; DEC-022 |
| COP | — | Peso colombiano; moneda oficial de Colombia y moneda del sistema. | PRD §18; SRS §15; SAD §22 |
| Cotización | `Quotation` | Propuesta de costos y selección de servicios para un evento, con versión y estado. | DDD §3.3 |
| Cotización integral | — | Cotización completa del evento con todos los proveedores seleccionados por categoría. | PRD §18 |
| Cotización rápida | — | Comparación de proveedores dentro de una sola categoría de servicio. | PRD §18 |
| CQRS | — | Separación de modelos de lectura y escritura. | DDD §22 |
| DDD | — | Domain-Driven Design. | DDD §22 |
| Disponibilidad | — | Capacidad declarada o bloqueada de un proveedor para una fecha. | DDD §3.2 |
| Domain Event | — | Hecho de negocio que ya ocurrió. | DDD §22 |
| Domain Service | — | Regla de dominio que no pertenece naturalmente a una entidad. | DDD §22 |
| e-RFQ / e-RFP | `E_RFQ` | Modalidad de contratación basada en solicitud electrónica de cotización o propuesta enviada a varios proveedores. | SRS §15; DDD §3.2 |
| Empresa organizadora | `Organization` | Empresa que se dedica profesionalmente a organizar eventos y contrata proveedores; constituye el tenant de sus datos organizacionales. | PRD §18; SRS §15; DDD §3.1 |
| Entity | — | Objeto con identidad propia. | DDD §22 |
| Entrega E1 / E2 | — | Etiqueta de entrega del MVP: E1 es el piloto (núcleo e-RFQ); E2 agrupa Instant Book, capacidad por paquete, asistente WhatsApp, verificación de nivel 3 y transferencia de propiedad. | DEC-021; SRS (etiqueta Entrega) |
| Estado de cotización | `QuotationStatus` | Estado de la cotización integral: `BORRADOR` (en edición), `GENERADA` (snapshot/PDF generado), `ENVIADA` (al menos un ítem con RFQ o contratación), `CERRADA` (evento completado o cancelado; solo lectura). Contexto: BC-06 Quotation. | SRS §9.6; DDD §15.6 |
| Estado de oferta | `OfferStatus` | Estado de una revisión de oferta: `RECIBIDA` (vigente y adjudicable), `REEMPLAZADA`, `ADJUDICADA`, `NO_ADJUDICADA`, `INVALIDADA`, `VENCIDA`. Solo `RECIBIDA` es adjudicable. Contexto: BC-08 RFQ & Offers. | SRS §9.7; DDD §15.7 |
| Evento | `Event` | Contexto de compra propiedad de una empresa, con fecha, ubicación, asistentes, presupuesto y estado. | DDD §3.3 |
| Idempotencia | — | Propiedad por la que repetir una operación no crea efectos duplicados. | SRS §15; SAD §22 |
| Incidencia de servicio | `INCIDENCIA` | Reporte del organizador de un problema durante el servicio contratado; la reserva pasa a este estado. | PRD §9.2 (estados de reserva); DDD §8.1; DEC-023 |
| Instant Book | `INSTANT_BOOK` | Reserva inmediata de un paquete con tarifa vinculante y disponibilidad validada. | SRS §15; DDD §3.2 |
| Invariant | — | Regla que debe mantenerse siempre válida. | DDD §22 |
| Ítem de cotización | `QuotationItem` | Necesidad concreta de servicio dentro de una cotización; puede estar estimada, seleccionada, enviada, confirmada o completada. | DDD §3.3 |
| Magic Link | `TokenMagicLink` | Enlace seguro, de capacidad limitada, de un solo uso y con expiración, que permite responder una solicitud específica sin iniciar sesión. | SRS §15; SAD §22; DDD §3.4 |
| Membresía | `Membership` | Relación entre un usuario y una empresa, con un rol y un estado dentro de esa empresa. | DDD §3.1 |
| Membresía activada | `MembershipActivated` | Evento de dominio emitido cuando el invitado acepta la invitación y la membresía pasa de `INVITADO` a `ACTIVO`. Contexto: BC-02 Organizations & Tenancy. | DDD §5.3; DDD §8.1 |
| Modalidad de contratación | `INSTANT_BOOK`, `E_RFQ` | Forma en que puede contratarse un paquete de servicio. | DDD §3.2; DEC-022 |
| Monolito modular | — | Aplicación desplegable única con módulos internos de límites explícitos. | SAD §22 |
| Motor de cotización | — | Componente del sistema que filtra, rankea y presenta proveedores automáticamente. | PRD §18 |
| MRR | — | Monthly Recurring Revenue; ingreso mensual recurrente por suscripciones. | PRD §18 |
| MVP | — | Minimum Viable Product; producto mínimo viable, primera fase operativa. | PRD §18; SRS §15; SAD §22 |
| No adjudicada | — | Oferta o solicitud que no fue seleccionada para la contratación. | DDD §3.4 |
| NPS | — | Net Promoter Score; métrica de satisfacción y lealtad del cliente. | PRD §18 |
| Oferta | `Offer` | Respuesta comercial estructurada de un proveedor a una solicitud e-RFQ; sus revisiones son inmutables y trazables. | DDD §3.4; DEC-005 |
| Elección en revisión por suspensión | `SuspensionReviewDecision` | Respuesta de la organizadora (`MANTENER` o `CANCELAR`) ante una contratación en revisión de origen `PLATAFORMA`. Contexto: BC-07 Availability & Booking. | SRS-ADM-013; DEC-034 |
| Organización activa | `TenantContext` | Organización seleccionada en la sesión BFF y validada mediante la cabecera X-Organization-Id; define el tenant de cada caso de uso. | TEC-006; DDD §4.3 (BC-02 Organizations & Tenancy) |
| Origen de respuesta | — | Canal por el que se registró una oferta: formulario Magic Link o respuesta WhatsApp asistida. | DDD §3.4 |
| Origen de revisión | `ReviewOrigin` | Causa por la que una contratación está en `CANCELACION_EN_REVISION`: `CONTRAPARTE` (disputa o falta de respuesta) o `PLATAFORMA` (suspensión del proveedor). Contexto: BC-07 Availability & Booking. | SRS-BOOK-009; DDD §15.4 |
| Outbox | — | Registro transaccional de eventos pendientes de publicación, insertado en la misma transacción de negocio (Transactional Outbox). | SAD §22; DDD §22 |
| Paginación por cursor | `CursorPageMeta` | Metadatos de paginación con `limit` y `nextCursor` opaco, usados en el catálogo público (búsqueda y reseñas, máx. 50), notificaciones y auditoría (TEC-012). Contexto: API. | SAD §10.7 |
| Paquete de servicio | `ServicePackage` | Oferta comercial publicada por un proveedor, con precio, alcance, exclusiones y modalidad. | DDD §3.2 |
| Perfil de proveedor | — | Información comercial, descriptiva, geográfica y operativa del proveedor. | DDD §3.2 |
| Plan de prueba | `PRUEBA` | Plan de 90 días de una organización; sus límites bloquean la creación de nuevos recursos, nunca los compromisos existentes. | DEC-029; PRD (plan) |
| Plantilla de evento | — | Configuración reutilizable de un tipo de evento y sus categorías sugeridas. | PRD §18; DDD §3.3 |
| Portafolio | — | Evidencias multimedia asociadas al perfil del proveedor. | DDD §3.2 |
| PRD | — | Product Requirements Document. | SAD §22 |
| Presupuesto referencial | — | Límite o estimación usada para señalar excesos; no constituye un cobro ni una autorización de pago. | DDD §3.3 |
| Propietario | `PROPIETARIO` | Único propietario principal de la empresa; nombra administradores y puede transferir la propiedad. | DDD §3.1; DEC-008; DEC-022 |
| Proveedor | `Provider` | Persona o negocio que ofrece servicios para eventos, incluidos los profesionales independientes o microempresas (freelance); su identidad es global. | PRD §18; SRS §15; DDD §3.1 |
| Proveedor elegible | — | Proveedor que cumple los filtros de estado, verificación, categoría/subtipo, cobertura, capacidad y demás criterios aplicables. | DDD §3.2 |
| RBAC | — | Control de acceso basado en roles. | SAD §22 |
| Read Model | — | Proyección optimizada para consulta. | DDD §22 |
| Registro de comisión | `CommissionRecord` | Agregado que lleva el devengo, la retención y la reversión auditada de la comisión por contratación. | DDD §4.8 (BC-07); DEC-023; TEC-010 |
| Repository | — | Abstracción para recuperar y persistir agregados. | DDD §22 |
| Reseña B2B | `Review` | Evaluación de un proveedor realizada por una empresa después de una contratación completada; el PRD la denomina Calificación B2B. | PRD §18; DDD §3.5 |
| Reserva | `Booking` | Compromiso confirmado entre una empresa y un proveedor para un servicio y una fecha. | DDD §3.4 |
| Respuesta asistida | — | Texto o contenido recibido fuera de la plataforma, estructurado por una persona con ayuda del asistente y confirmado manualmente. | DDD §3.5 |
| Retención legal | `LegalHold` (`legal_hold`) | Bloqueo con motivo sobre un recurso que impide su archivado, anonimización o eliminación mientras esté activo. Contexto: BC-12 Administration & Audit. | SRS-ADM-012; DEC-003 |
| RFQ | — | Request for Quotation; solicitud de cotización. | SAD §22 |
| RPO | — | Pérdida máxima de datos temporal aceptable tras una interrupción. | SRS §15; SAD §22 |
| RTO | — | Tiempo objetivo máximo para recuperar el servicio tras una interrupción. | SRS §15; SAD §22 |
| SaaS | — | Software as a Service; modelo de distribución de software basado en suscripción. | PRD §18 |
| SAD | — | Software Architecture Document. | SAD §22 |
| Seguimiento de ítem | — | Estado operativo del servicio contratado durante el ciclo del evento. | DDD §3.5 |
| SLA | — | Plazo límite de respuesta de una solicitud e-RFQ. | SRS §15; DDD §3.4 |
| Snapshot | — | Copia inmutable de los datos comerciales relevantes en un momento transaccional. | SRS §15; SAD §22; DDD §3.3 |
| Solicitud de titular | `DataSubjectRequest` | Solicitud de un usuario para consultar, corregir o suprimir sus datos personales (Ley 1581), con estado `RECIBIDA`, `EN_TRAMITE`, `RESUELTA` o `RECHAZADA`, responsable, fecha límite y resultado. Contexto: BC-12 Administration & Audit. | SRS-ADM-012; SRS-NFR-PRIV-002 |
| Solicitud e-RFQ | `RfqRequest` | Invitación individual enviada a un proveedor para que cotice un ítem de evento. | DDD §3.4 |
| SRS | — | Software Requirements Specification. | SAD §22 |
| Subdomain | — | Área de problema dentro del negocio. | DDD §22 |
| Subtipo | — | Especialización dentro de una categoría. | SRS §15; DDD §3.2 |
| Tenant | — | Espacio de datos aislado de una empresa; el proveedor no pertenece exclusivamente a un tenant. | SRS §15; SAD §22; DDD §3.1 |
| Ubiquitous Language | — | Lenguaje compartido por negocio y equipo técnico. | DDD §22 |
| Value Object | — | Objeto inmutable definido por sus valores. | DDD §22 |
| WhatsApp Click-to-Chat | — | Apertura de una conversación mediante wa.me con destinatario y texto prellenados; no acredita envío, entrega ni lectura. | SRS §15; DDD §3.5 |
| Worker | — | Proceso que ejecuta tareas asíncronas. | SAD §22 |
