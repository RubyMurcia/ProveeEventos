# ProveeEventos — Software Requirements Specification (SRS)

**Archivo:** `ProveeEventos_SRS.md`  
**Versión:** 1.3  
**Fecha:** 24 de noviembre de 2026  
**Documento de origen:** `ProveeEventos_PRD.md` v2.4  
**Estado:** Especificación funcional y técnica de comportamiento para el MVP (Fase 1), con requisitos posteriores identificados por fase.

## Historial de versiones

| Versión | Fecha | Descripción |
|---|---|---|
| 1.0 | 20-11-2026 | Primera especificación derivada del PRD v2.2 |
| 1.0 (rev.) | 23-11-2026 | Se incorporan las decisiones aprobadas DEC-001..018 y TEC-001..005 (§13.1) |
| 1.1 | 23-11-2026 | Plan0001 (Review V1): estados de contratación y comisión (BOOK-009/010), capacidad en la adjudicación, ofertas vencidas y revocación de RFQ (RFQ-012/013), eventos con compromisos y fechas de capacidad (EVT-008..010), roles únicos, organización activa, asignación de eventos y autenticación reforzada (AUTH-010..012), planes (TEN-004), contacto del proveedor (CAT-015), redondeo (QUO-013), reseñas (REV-008), estado de entrega de email (NOT-006), administración de cobro, planes y disputas (ADM-008..010), IDs para requisitos no funcionales de privacidad, usabilidad, compatibilidad y observabilidad, y RN-21..25. Aplica DEC-019..033 y TEC-006..011, propuestas pendientes de aprobación |
| 1.2 | 24-11-2026 | Plan0003 (Review V2): grafo completo del ítem (§9.3) y nuevas máquinas de cotización (§9.6) y oferta (§9.7); `ERROR_ENVIO → CANCELADO`; requisitos nuevos TEN-005, EVT-011, QUO-014, ADM-011..013 (suspensión con contrataciones futuras, DEC-034, pendiente); entidades de titular y retención legal (§4.1); `NUMERIC(14,2)` en §4.3; entregas por párrafo en BOOK-002/009 y WhatsApp en E2; NFR medibles, `SRS-NFR-SCAL-001..006` y escenarios nuevos en §8; matriz §12 corregida |
| 1.2 (rev.) | 24-11-2026 | Aprobación de DEC-019..034, TEC-006..012 y ADR-016..022 (23-11-2026): se retiran las marcas de pendiente; sin cambios de comportamiento |
| 1.3 | 24-11-2026 | Plan0004 (Review V3): transiciones de revisión por suspensión y origen de la revisión (BOOK-009, §9.5, ADM-013); decisión de la organizadora y acciones del proveedor suspendido (DEC-036, pendiente); destino del ítem en todo cierre de ronda, cancelación del evento y cierre de solicitudes respondidas (DEC-035, pendiente); plazos provisionales de solicitudes de titulares (DEC-037, pendiente); SRS-EVT-006/007 y matiz E2 de administración en la matriz §12; documento de origen y criterio de cierre actualizados |
| 1.3 (rev.) | 24-11-2026 | Aprobación de DEC-035..037 (fecha de registro 23-11-2026): se retiran las marcas de pendiente; la excepción del proveedor suspendido se referencia desde SRS-AUTH-005 y SRS-AUTH-007; referencias al PRD v2.4; sin cambios de comportamiento |

---

## Control del documento

| Campo | Valor |
|---|---|
| Producto | ProveeEventos |
| Tipo de sistema | Plataforma web B2B multiempresa |
| Mercado inicial | Ciudades principales de Colombia |
| Idioma inicial | Español (Colombia) |
| Moneda | COP |
| Fuente normativa del producto | PRD v2.4 |
| Audiencia | Producto, UX/UI, desarrollo, QA, operaciones |
| Propietario funcional | ProveeEventos |
| Decisiones de producto | Incorporadas desde `Decisiones.md`: DEC-001 a DEC-037 y TEC-001 a TEC-012, todas aprobadas; ver sección 13 |

### Convenciones

- **MUST / DEBE:** requisito obligatorio y verificable.
- **SHOULD / DEBERÍA:** comportamiento recomendado; cualquier excepción debe documentarse.
- **MAY / PUEDE:** capacidad opcional.
- **MVP:** Fase 1, salvo indicación contraria.
- Los identificadores `SRS-*` son estables y se usarán para trazabilidad, pruebas y decisiones técnicas.
- Los tiempos de respuesta se medirán desde el servidor, salvo que se indique explícitamente otra cosa.
- Los importes se almacenarán como valores decimales exactos, nunca como punto flotante binario.

---

# 1. Introducción

## 1.1 Propósito

Este documento especifica el comportamiento funcional, las reglas, los datos, las interfaces y los atributos de calidad que debe cumplir ProveeEventos. Traduce los objetivos y requerimientos del PRD v2.4 a condiciones implementables y comprobables.

El SRS es la referencia para:
1. diseñar la arquitectura detallada;
2. definir contratos API y esquema persistente;
3. implementar frontend, backend e integraciones;
4. preparar casos de prueba y criterios de aceptación;
5. controlar cambios de alcance y mantener trazabilidad.

## 1.2 Alcance del sistema

ProveeEventos es una plataforma web B2B para que empresas organizadoras de eventos descubran, comparen, coticen, reserven y den seguimiento a proveedores freelance.

El MVP incorpora:
- cuentas de empresas, coordinadores, proveedores y administradores;
- catálogo de proveedores con categorías y subtipos;
- paquetes con modalidad `INSTANT_BOOK` o `E_RFQ`;
- búsqueda y filtros;
- disponibilidad y reservas;
- cotización rápida e integral;
- plantillas y clonación de eventos;
- solicitudes e-RFQ paralelas con SLA;
- formulario de respuesta mediante Magic Link por email;
- plantillas modificables de WhatsApp y Click-to-Chat;
- asistente manual para estructurar respuestas recibidas por WhatsApp;
- Bid Tabulation;
- seguimiento de eventos y notificaciones;
- exportación PDF;
- calificaciones B2B;
- administración del catálogo y moderación.

## 1.3 Fuera del alcance del MVP

Los siguientes elementos quedan expresamente fuera de la entrega MVP, aunque el diseño debe evitar bloquear su incorporación:

| Fase | Capacidades |
|---|---|
| Fase 2 | WhatsApp Business Cloud API, webhooks, IA automatizada con API oficial, notas de voz, chat interno, Kanban, Google Calendar, push notifications, analítica avanzada |
| Fase 3 | Cotizador inverso, Semáforo de Precio Justo, sinergia geográfica avanzada, comparación lado a lado, versiones automáticas, pagos MercadoPago/PayU, perfiles destacados y badge premium |
| Fase 4 | Aplicación móvil nativa, API pública, contratos digitales, multi-idioma y expansión internacional |

Una capacidad futura no se considerará disponible en MVP por el solo hecho de que exista un campo o una abstracción técnica para ella.

**Limitación del MVP:** cada proveedor tiene un único usuario. Los equipos de proveedor con varios usuarios se consideran para la Fase 2.

**Entregas del MVP:** el MVP se divide en E1 (piloto) y E2 (DEC-021); cada requisito indica su entrega.

## 1.4 Referencias

- ProveeEventos PRD v2.4 (`ProveeEventos_PRD.md`), secciones 1–18 y anexos A–D.
- OWASP ASVS y OWASP Cheat Sheet Series para controles de seguridad web.
- RFC 6749 / OpenID Connect Core para autenticación delegada, cuando aplique.
- RFC 7519 para conceptos de tokens; los Magic Links de este producto se tratarán como credenciales de capacidad de un solo uso, no como sesiones generales.
- ISO 8601 para fechas y tiempos; almacenamiento temporal en UTC y presentación según la zona horaria IANA del evento (DEC-007).
- Ley 1581 de 2012 y normas reglamentarias colombianas aplicables a protección de datos personales.
- Reglas y documentación vigentes de Meta WhatsApp Business Platform para la fase de integración oficial.

## 1.5 Supuestos de operación

1. El mercado inicial opera en Colombia y usa COP.
2. Cada empresa organizadora constituye un espacio de datos aislado (*tenant*).
3. Un proveedor puede ofrecer servicios a múltiples empresas.
4. Un evento pertenece a una sola empresa organizadora.
5. Una solicitud e-RFQ corresponde a un proveedor y a un ítem de cotización; cada proveedor invitado recibe una solicitud independiente.
6. La plataforma no procesa pagos ni anticipos en MVP. Una reserva confirmada representa una contratación/compromiso registrado en la plataforma, no un cobro procesado.
7. El canal Email + Magic Link es el canal automatizado de respuesta estructurada del MVP.
8. `wa.me` abre una conversación prellenada en el cliente de WhatsApp del usuario; no envía el mensaje por sí mismo ni entrega respuestas entrantes al backend.
9. Las respuestas recibidas por WhatsApp en MVP se capturan manualmente por el organizador y se estructuran mediante el asistente de IA asistida.
10. Los administradores de plataforma son personal interno autorizado de ProveeEventos.

---

# 2. Descripción general

## 2.1 Contexto del producto

El sistema se compone de:
- aplicación web responsive;
- API backend;
- motor de catálogo, cotización, reserva y e-RFQ;
- persistencia relacional;
- caché y procesamiento asíncrono;
- proveedor externo de autenticación;
- servicio de correo transaccional;
- almacenamiento multimedia;
- enlaces Click-to-Chat para WhatsApp;
- generador PDF;
- interfaz asistida para importar respuestas estructuradas.

## 2.2 Clases de usuario y permisos

Vocabulario único de roles (DEC-022). Los cuatro primeros son roles de **membresía** en una empresa; los dos últimos son roles **globales**.

| Rol | Tipo | Descripción | Capacidades principales |
|---|---|---|---|
| `PROPIETARIO` | Membresía (uno por empresa) | Propietario principal de la empresa | Todo lo de `ADMIN_EMPRESA`, más nombrar/revocar administradores y transferir la propiedad |
| `ADMIN_EMPRESA` | Membresía | Administrador operativo de una empresa organizadora | Gestionar empresa, miembros, plan, eventos, cotizaciones, plantillas, reseñas y configuración |
| `COORDINADOR` | Membresía | Miembro operativo de una empresa | Gestionar eventos, cotizaciones, e-RFQ, adjudicaciones, contrataciones y seguimiento de su empresa |
| `COORDINADOR_RESTRINGIDO` | Membresía | Miembro limitado a eventos asignados | Operar solo los eventos asignados (SRS-AUTH-011); no adjudica ni cancela contrataciones |
| `PROVEEDOR` | Global | Profesional o negocio que ofrece servicios | Gestionar perfil, paquetes, disponibilidad, responder e-RFQ, consultar reservas y responder reseñas |
| `ADMIN_PLATAFORMA` | Global | Operador interno | Verificar/suspender proveedores y cuentas, administrar taxonomía, plantillas globales y planes, moderar, resolver disputas y consultar métricas |

**Regla de aislamiento:** un usuario de empresa solo puede consultar o modificar recursos pertenecientes a su empresa. Un proveedor solo puede gestionar sus propios recursos. `ADMIN_PLATAFORMA` opera con permisos administrativos auditados.

## 2.3 Entorno de ejecución

El PRD define como stack de referencia:
- Frontend: Next.js 14+ / React, Tailwind CSS y shadcn/ui.
- Backend: Node.js 20+ y Express.
- Persistencia: PostgreSQL 15+ y Prisma.
- Caché/colas: Redis y BullMQ.
- Autenticación: Auth0.
- Multimedia: Cloudinary.
- Email: SendGrid.
- WhatsApp MVP: Click-to-Chat (`wa.me`).
- PDF: React-PDF por defecto; Puppeteer solo si el prototipo demuestra que el diseño exige fidelidad HTML/CSS (DEC-016).
- Hosting: Vercel y Railway como candidato de MVP, sujeto a la prueba de aceptación técnica y a la región aprobada (DEC-013, DEC-014).
- Observabilidad: Sentry y Vercel Analytics.

Este SRS define requisitos de comportamiento; las decisiones de despliegue y componentes concretos se detallarán en el SAD.

## 2.4 Restricciones de negocio

- El catálogo contiene 21 categorías principales y subtipos administrables.
- Un proveedor puede pertenecer como máximo a cinco categorías principales.
- Se pueden seleccionar entre uno y cinco proveedores para un e-RFQ; el valor predeterminado de selección será TOP 3.
- El SLA seleccionable será 6, 12, 24 o 48 horas.
- Un proveedor no puede superar dos eventos confirmados en una misma fecha.
- Los paquetes Instant Book tienen tarifa vinculante, salvo cambio de alcance aceptado por ambas partes.
- Solo una empresa con contratación completada puede calificar al proveedor.
- Los precios se muestran indicando explícitamente si incluyen impuestos, si no aplican o si el proveedor debe confirmarlos, según la configuración fiscal por proveedor/servicio (DEC-010).
- Los borradores inactivos se archivan después de 90 días, con aviso siete días antes (DEC-003).

---

# 3. Requisitos funcionales

## 3.1 Identidad, registro y acceso

### SRS-AUTH-001 — Registro de empresa

**Entrega:** E1

El sistema DEBE permitir registrar una empresa con:
- razón/nombre comercial;
- NIT;
- nombre del contacto;
- email;
- teléfono;
- ciudad;
- credenciales gestionadas por el proveedor de identidad.

El registro DEBE realizarse con una identidad Auth0 ya autenticada (el usuario completa primero el signup en Auth0, con protección anti-bot) que aún no tenga membresía. El email de la cuenta se toma del token validado, no del formulario, y debe estar verificado para activarla (TEC-007). Quien registra la empresa queda como `PROPIETARIO`.

**Validaciones:**
- email con formato válido y único en el proveedor de identidad;
- NIT normalizado y único para la entidad empresa;
- campos obligatorios no vacíos;
- aceptación de términos y política de privacidad antes de activar la cuenta;
- si el NIT ya está registrado por otra cuenta, se rechaza y se ofrece un canal de disputa: soporte verifica la titularidad y, si procede, reasigna con auditoría.

**Resultado:** se crea una cuenta de usuario asociada a una empresa en estado pendiente de verificación de email. El acceso a funcionalidades protegidas queda bloqueado hasta verificar el correo.

### SRS-AUTH-002 — Registro de proveedor

**Entrega:** E1

El sistema DEBE permitir registrar proveedor con nombre/nombre comercial, tipo de proveedor (persona natural o empresa), identificación fiscal opcional en el registro (obligatoria para el nivel 2 de verificación), categoría principal inicial, teléfono, ciudad, aceptación de términos y de la política de tratamiento de datos (con versión del aviso y fecha/hora) y credenciales. Como en SRS-AUTH-001, el registro exige una identidad Auth0 autenticada y el email se toma del token (TEC-007).

El proveedor inicia en estado `PENDIENTE`. La verificación de email y la aprobación administrativa son controles diferentes: verificar el correo no implica aprobación para aparecer en el catálogo. La aprobación sigue la verificación por niveles de SRS-ADM-001 (DEC-009).

### SRS-AUTH-003 — Inicio y cierre de sesión

**Entrega:** E1

El sistema DEBE delegar autenticación en Auth0 (o proveedor compatible aprobado), y asociar el identificador externo (`auth0_id`) con el usuario interno.

El backend DEBE validar la firma, emisor, audiencia, expiración y demás claims requeridos del token. No debe confiar en el rol enviado por el navegador.

La sesión web DEBE gestionarse en servidor (patrón BFF) con cookies `HttpOnly`, `Secure` en producción y `SameSite` apropiado, con protección CSRF en operaciones mutables. Los tokens de acceso NO DEBEN exponerse al JavaScript del navegador ni guardarse en `localStorage` (DEC-017). Roles y tenant se resuelven siempre en backend desde la base de datos.

### SRS-AUTH-004 — Recuperación de acceso

**Entrega:** E1

El usuario DEBE poder iniciar recuperación por email. El enlace de restablecimiento tendrá vigencia de 24 horas, será de un solo uso y será gestionado por el proveedor de identidad.

### SRS-AUTH-005 — Autorización basada en roles y tenant

**Entrega:** E1

Toda operación protegida DEBE validar:
1. identidad autenticada;
2. rol requerido;
3. pertenencia del recurso al tenant correspondiente;
4. estado activo/no suspendido de la cuenta, con la única excepción del proveedor suspendido sobre sus contrataciones vigentes (SRS-AUTH-007, DEC-036).

Las comprobaciones se realizarán en backend, no únicamente ocultando controles en la interfaz. El tenant se resuelve desde la membresía autenticada y los casos de uso exigen `organizationId`; PostgreSQL Row Level Security se evaluará como defensa adicional, nunca como sustituto de la autorización (TEC-005).

### SRS-AUTH-006 — Invitación de coordinadores

**Entrega:** E1

`ADMIN_EMPRESA` DEBE poder invitar múltiples coordinadores dentro del límite del plan contratado. La invitación tendrá token de un solo uso, expiración configurable y asociación inequívoca a una empresa. El invitado deberá aceptar y completar su cuenta; al aceptar, la membresía pasa de invitada a activa.

`PROPIETARIO` y `ADMIN_EMPRESA` DEBEN poder listar los miembros de la empresa con su rol y estado, y las invitaciones pendientes, vencidas o revocadas.

### SRS-AUTH-007 — Suspensión y reactivación

**Entrega:** E1

Un administrador autorizado podrá suspender una cuenta. Una cuenta suspendida no podrá iniciar operaciones protegidas, crear reservas, responder solicitudes ni aparecer como proveedor disponible, salvo la excepción del párrafo siguiente. La suspensión no borrará el historial transaccional. El efecto sobre las contrataciones futuras de un proveedor suspendido se define en SRS-ADM-013.

**Excepción para contrataciones vigentes (DEC-036):** un proveedor con cuenta suspendida conserva únicamente la consulta de sus contrataciones vigentes y las acciones de ciclo sobre las que sigan en curso: marcar el servicio realizado (SRS-BOOK-008) y responder una cancelación (SRS-BOOK-007). Toda otra operación permanece bloqueada.

### SRS-AUTH-008 — Perfil y preferencias de usuario

**Entrega:** E1

El sistema permitirá consultar y actualizar datos de contacto y preferencias de notificación autorizadas. Los cambios sensibles deberán quedar auditados.

### SRS-AUTH-009 — Roles internos de empresa, administradores y propiedad

**Entrega:** E1 (transferencia de propiedad: E2, DEC-021)

Cada empresa tendrá cuatro roles de membresía con permisos predefinidos (DEC-008, DEC-011; valores según DEC-022, que sustituyen a los nombres en inglés usados antes):

- `PROPIETARIO`: único propietario principal; nombra y revoca administradores y puede transferir la propiedad.
- `ADMIN_EMPRESA`: uno o más administradores operativos; administran empresa, miembros, plan y todas las operaciones.
- `COORDINADOR`: crea y gestiona eventos, cotizaciones, e-RFQ, adjudicaciones, reservas y seguimiento.
- `COORDINADOR_RESTRINGIDO`: limitado a los eventos asignados (SRS-AUTH-011), sin facultad de adjudicar ni cancelar contrataciones.

| Acción | `PROPIETARIO` | `ADMIN_EMPRESA` | `COORDINADOR` | `COORDINADOR_RESTRINGIDO` |
|---|:-:|:-:|:-:|:-:|
| Editar datos de empresa y consultar plan | Sí | Sí | No | No |
| Invitar, suspender y cambiar rol de miembros | Sí | Sí (excepto `PROPIETARIO`) | No | No |
| Nombrar o revocar `ADMIN_EMPRESA` | Sí | No | No | No |
| Transferir la propiedad | Sí | No | No | No |
| Crear y editar eventos, cotizaciones y plantillas | Sí | Sí | Sí | Solo eventos asignados (sin plantillas) |
| Enviar e-RFQ y revisar Bid Tabulation | Sí | Sí | Sí | Solo eventos asignados |
| Adjudicar, reservar Instant Book y cancelar contrataciones | Sí | Sí | Sí | No |
| Confirmar cierre de servicio y calificar | Sí | Sí | Sí | Solo eventos asignados |
| Asignar eventos a coordinadores restringidos | Sí | Sí | No | No |

Reglas:
1. Una empresa puede tener varios administradores, pero exactamente un propietario principal.
2. La transferencia de propiedad exige confirmación del propietario actual y aceptación del nuevo propietario, con autenticación reforzada.
3. Un administrador no puede eliminarse a sí mismo si la empresa quedaría sin propietario válido.
4. Si el propietario pierde acceso o deja la empresa, se aplica un procedimiento de recuperación con soporte y verificación.
5. No existe editor visual de permisos por acción en el MVP; la limitación de acceso usa perfiles fijos y asignación por evento. La autorización por evento DEBE cubrirse con pruebas negativas entre coordinadores.
6. Todo cambio de rol o propiedad queda registrado con actor, fecha y estado anterior/nuevo.

### SRS-AUTH-010 — Organización activa

**Entrega:** E1

Un usuario PUEDE tener membresías en varias empresas. Cada petición sobre recursos empresariales DEBE ejecutarse en el contexto de una sola organización activa: el BFF guarda la organización elegida en la sesión y la envía como `X-Organization-Id`; la API valida que el usuario tenga una membresía activa en ella. Sin cabecera, si el usuario tiene una sola membresía se usa esa; si tiene varias, la API responde `400` con código `ORGANIZATION_REQUIRED`. El identificador recibido nunca es por sí solo prueba de autorización (TEC-006).

### SRS-AUTH-011 — Asignación de eventos a coordinador restringido

**Entrega:** E1

`PROPIETARIO` y `ADMIN_EMPRESA` DEBEN poder asignar y retirar eventos a un `COORDINADOR_RESTRINGIDO`. El coordinador restringido solo puede consultar y operar los eventos asignados, sus cotizaciones, solicitudes y seguimiento; no adjudica, no reserva Instant Book ni cancela contrataciones. Las asignaciones quedan auditadas y DEBEN cubrirse con pruebas negativas (acceso a un evento no asignado → no encontrado).

### SRS-AUTH-012 — Autenticación reforzada

**Entrega:** E1

1. MFA obligatorio para `ADMIN_PLATAFORMA` y `PROPIETARIO`, y recomendado para `ADMIN_EMPRESA`.
2. La transferencia de propiedad, los cambios de rol y la suspensión de miembros exigen una autenticación reciente (`max_age` ≤ 5 minutos).
3. El registro público (signup en Auth0) DEBE tener protección anti-bot.
4. Se aplican los límites de SRS-NFR-SEC-012 a login, recuperación y registro.

## 3.2 Empresas y multi-tenancy

### SRS-TEN-001 — Aislamiento de datos

**Entrega:** E1

Los eventos, cotizaciones, plantillas privadas, coordinadores, notificaciones y preferencias de una empresa DEBEN quedar aislados de otras empresas.

### SRS-TEN-002 — Propiedad del evento

**Entrega:** E1

Cada evento DEBE tener una empresa propietaria y, opcionalmente, un coordinador responsable perteneciente a esa misma empresa.

### SRS-TEN-003 — Límites del plan

**Entrega:** E1

El sistema DEBE validar límites de eventos activos, cotizaciones/e-RFQs mensuales, coordinadores y plantillas personalizadas según el plan. Si el plan o su estado no están configurados para una cuenta, no se debe inventar una cuota: se aplicará una política operativa definida en configuración.

**Nota de alcance:** el PRD describe precios y límites comerciales, pero no especifica proveedor de facturación ni pasarela para suscripciones. El cobro recurrente automatizado no es requisito del MVP; la aplicación debe poder registrar el plan asignado.

### SRS-TEN-004 — Planes, prueba y exceso de límites

**Entrega:** E1

Los planes DEBEN ser datos configurables con vigencia (código, precio, límites y fechas): `PRUEBA` (90 días con límites del plan Pro), `BASICO`, `PRO` y `ENTERPRISE` (DEC-029). Reglas:
1. Al alcanzar un límite (eventos activos, cotizaciones/e-RFQ mensuales, coordinadores, plantillas), el sistema rechaza crear el recurso nuevo con el código `PLAN_LIMIT_REACHED` e indica el límite.
2. Nunca se bloquean operaciones sobre compromisos existentes (responder cancelaciones, confirmar cierres, consultar ofertas, adjudicar RFQ ya enviadas).
3. Con el plan vencido, la cuenta queda en solo lectura para operaciones nuevas y puede seguir gestionando sus contrataciones y solicitudes existentes.
4. `ADMIN_PLATAFORMA` asigna y cambia los planes (SRS-ADM-009); la empresa consulta su plan y su consumo.

### SRS-TEN-005 — Datos de la empresa activa

**Entrega:** E1

Cualquier miembro DEBE poder consultar los datos de la empresa activa (TEC-006): nombre comercial, razón social, NIT, ciudad, datos de contacto, datos fiscales básicos, plan vigente y consumo. Solo `PROPIETARIO` y `ADMIN_EMPRESA` PUEDEN modificarlos. El NIT normalizado no se cambia desde la aplicación: su corrección es una solicitud a `ADMIN_PLATAFORMA`, auditada. Los cambios no alteran los snapshots ya emitidos (cotizaciones, contrataciones).

## 3.3 Perfil y catálogo de proveedores

### SRS-CAT-001 — Alta y edición de perfil

**Entrega:** E1

El proveedor podrá gestionar:
- nombre comercial;
- descripción;
- categorías y subtipos;
- zona de cobertura;
- ciudad;
- teléfono y WhatsApp;
- canal preferido;
- capacidad máxima;
- galería multimedia;
- paquetes de servicio.

Los cambios de perfil no deben modificar retroactivamente ofertas ya enviadas ni reservas confirmadas.

### SRS-CAT-002 — Validación de portafolio

**Entrega:** E1

El sistema permitirá hasta 20 imágenes y cinco videos por proveedor. Cada archivo deberá cumplir límites configurables de tipo MIME, tamaño y duración. Se rechazará contenido no admitido y se almacenará en Cloudinary.

### SRS-CAT-003 — Categorías y subtipos

**Entrega:** E1

El sistema DEBE mantener taxonomía jerárquica de dos niveles:
- CAT-01 Venue / Lugar del evento
- CAT-02 Catering / Banquetes
- CAT-03 Fotografía
- CAT-04 Video / Filmación
- CAT-05 DJ / Música en vivo
- CAT-06 Decoración / Ambientación
- CAT-07 Floristería
- CAT-08 Iluminación
- CAT-09 Sonido / Audiovisuales
- CAT-10 Mobiliario / Alquiler
- CAT-11 Transporte
- CAT-12 Tortas y Postres
- CAT-13 Animación / Entretenimiento
- CAT-14 Invitaciones / Papelería
- CAT-15 Coreografía
- CAT-16 Maestro de ceremonias
- CAT-17 Bar, Coctelería y Bebidas
- CAT-18 Personal y Staffing
- CAT-19 Infraestructura, Carpas y Energía
- CAT-20 Regalos, Recordatorios y Merchandising
- CAT-21 Otros

Los subtipos iniciales serán los definidos en el Anexo B del PRD v2.4 (DEC-020). El administrador podrá crear, editar, activar y desactivar elementos.

### SRS-CAT-004 — Integridad de taxonomía

**Entrega:** E1

Cada subtipo pertenecerá a una sola categoría. Un paquete deberá estar asociado a una categoría y a un subtipo activo de esa categoría. La desactivación de un subtipo no eliminará registros históricos ni alterará ofertas existentes.

### SRS-CAT-005 — Límite de categorías del proveedor

**Entrega:** E1

Un proveedor podrá asociarse como máximo a cinco categorías principales y a múltiples subtipos válidos dentro de cada categoría.

### SRS-CAT-006 — Paquetes de servicio

**Entrega:** E1

El proveedor podrá crear paquetes con:
- nombre;
- categoría y subtipo;
- descripción;
- precio base;
- precio por persona (opcional);
- inclusiones;
- exclusiones;
- modalidad de contratación;
- estado activo/inactivo.

Un paquete no podrá publicarse si carece de precio base válido o clasificación consistente.

### SRS-CAT-007 — Modalidad de contratación

**Entrega:** E1

Cada paquete tendrá exactamente una modalidad:
- `INSTANT_BOOK`: precio vinculante y reserva inmediata, sujeto a disponibilidad y capacidad;
- `E_RFQ`: requiere solicitud y oferta firme del proveedor.

La modalidad no se inferirá únicamente de la categoría. La configuración del paquete es la fuente de verdad.

### SRS-CAT-008 — Canal preferido

**Entrega:** E1

El proveedor podrá elegir `EMAIL_FORM`, `WHATSAPP` o `AMBOS`. El valor por defecto será `EMAIL_FORM`.

Para `AMBOS`, el comportamiento MVP será enviar el formulario estructurado por email y habilitar además el enlace Click-to-Chat de WhatsApp para el organizador. No se considerará que WhatsApp recibió automáticamente el mensaje.

### SRS-CAT-009 — Disponibilidad

**Entrega:** E1

El proveedor podrá marcar fechas como ocupadas. La disponibilidad se consultará al buscar, cotizar y reservar. La información mostrada en resultados es indicativa; la operación de reserva deberá volver a validar y consumir la capacidad de forma atómica en PostgreSQL. El modelo de capacidad es de dos niveles (SRS-BOOK-003, DEC-006): capacidad global del proveedor por fecha (predeterminada: 2) y capacidad específica por paquete como excepción explícita.

### SRS-CAT-010 — Visibilidad de catálogo

**Entrega:** E1

Solo proveedores con estado de verificación `VERIFICADO`, estado de cuenta `ACTIVO` y perfil publicable podrán aparecer en búsquedas públicas del catálogo. Proveedores `PENDIENTE` o `RECHAZADO`, o con cuenta `SUSPENDIDO`, no serán elegibles. Verificación y suspensión son dimensiones independientes (DEC-031).

### SRS-CAT-011 — Búsqueda y filtros

**Entrega:** E1

El sistema permitirá combinar:
- categoría;
- uno o varios subtipos;
- modalidad;
- rango de precio;
- calificación mínima;
- zona geográfica;
- fecha;
- capacidad mínima.

Los filtros deberán combinarse mediante lógica AND entre dimensiones y OR entre múltiples valores de una misma dimensión, salvo que el usuario seleccione expresamente otro comportamiento.

### SRS-CAT-012 — Resultados

**Entrega:** E1

Cada resultado mostrará foto principal, nombre comercial, categorías/subtipos, precio desde, promedio de calificación, número de reseñas y modalidad. Los resultados podrán paginarse.

### SRS-CAT-013 — Ordenamiento

**Entrega:** E1

Se soportará:
- precio ascendente;
- precio descendente;
- calificación descendente;
- relación calidad-precio;
- más recientes.

Los criterios de desempate deberán ser deterministas (por ejemplo, fecha de actualización y un identificador estable).

### SRS-CAT-014 — Capacidad y precio estimado

**Entrega:** E1

El sistema calculará el precio estimado del paquete usando el precio base y, cuando aplique, el precio por persona multiplicado por el número de asistentes. El cálculo deberá indicar claramente si es estimado o vinculante.

### SRS-CAT-015 — Revelación de datos de contacto

**Entrega:** E1

El teléfono, WhatsApp y email directos del proveedor NO DEBEN mostrarse en el perfil público ni en los resultados de búsqueda. Se revelan a una empresa solo (DEC-028):
1. dentro del enlace `wa.me` generado para una solicitud e-RFQ enviada a ese proveedor por esa empresa (SRS-WA-003), con registro en auditoría;
2. tras una contratación confirmada (Instant Book o adjudicación) con esa empresa.

## 3.4 Eventos y plantillas

### SRS-EVT-001 — Crear evento

**Entrega:** E1

Un usuario autorizado podrá crear un evento con:
- nombre;
- tipo/plantilla opcional;
- fecha y hora local de inicio y fin, introducidas por el usuario sin offset (un intervalo para eventos de varios días o que crucen medianoche); el sistema deriva los instantes UTC a partir de la zona IANA;
- zona horaria IANA del evento (p. ej. `America/Bogota`), derivada de la ciudad y confirmada explícitamente por el usuario;
- número de invitados;
- ubicación;
- presupuesto estimado opcional;
- coordinador responsable opcional.

La fecha del evento no podrá ser anterior a la fecha local actual de su zona horaria, salvo que se permita expresamente para registrar eventos históricos por una función administrativa.

Tratamiento temporal (DEC-007): el sistema guarda la zona IANA, los instantes `startsAtUtc`/`endsAtUtc` y la fecha/hora local introducida por el usuario. La disponibilidad diaria se calcula según la fecha local del evento; los SLA y timestamps técnicos usan UTC y la interfaz muestra la hora local. No se usan offsets fijos (`UTC-5`) como sustituto de una zona IANA, y se validan fechas ambiguas o inexistentes por cambio de horario.

### SRS-EVT-002 — Plantillas predefinidas

**Entrega:** E1

El sistema incluirá seis plantillas iniciales:
- Boda Clásica;
- Quinceañera;
- Evento Empresarial;
- Baby Shower;
- Grado;
- Fiesta Temática.

Cada plantilla tendrá las categorías y subtipos recomendados definidos en el Anexo C del PRD v2.4.

### SRS-EVT-003 — Modificar plantilla antes de cotizar

**Entrega:** E1

El usuario podrá agregar o quitar categorías y subtipos antes de generar la cotización. La modificación de una plantilla predefinida no alterará la plantilla global original.

### SRS-EVT-004 — Plantillas personalizadas

**Entrega:** E1

La empresa podrá crear, editar, duplicar y desactivar plantillas privadas. Cada plantilla tendrá nombre y conjunto de categorías/subtipos.

### SRS-EVT-005 — Clonar evento

**Entrega:** E1

El usuario podrá clonar un evento anterior. Se copiarán configuración, categorías/subtipos, notas y referencias de proveedores/paquetes como sugerencias. No se copiarán reservas, ofertas firmes, tokens, calificaciones ni estados transaccionales.

Al clonar, el sistema deberá:
1. exigir nueva fecha;
2. permitir modificar invitados y ubicación;
3. volver a consultar disponibilidad;
4. recalcular estimaciones con precios vigentes;
5. crear nuevos identificadores y un nuevo ciclo transaccional.

### SRS-EVT-006 — Estados del evento

**Entrega:** E1

Estados permitidos:
- `BORRADOR`;
- `COTIZADO`;
- `ENVIADO`;
- `EN_PROGRESO`;
- `COMPLETADO`;
- `CANCELADO`.

El sistema solo permitirá las transiciones definidas en la sección 9.4, que es la regla normativa: el evento pasa a `EN_PROGRESO` por un job al llegar su fecha/hora local de inicio si tiene al menos una contratación activa, y a `COMPLETADO` cuando todas sus contrataciones son terminales y al menos una está `COMPLETADO`. El coordinador no fuerza estas transiciones manualmente.

### SRS-EVT-007 — Borradores inactivos

**Entrega:** E1

Los eventos en estado `BORRADOR` sin actividad durante 90 días, junto con sus cotizaciones en borrador, serán archivados (borrado lógico). "Archivado" es una marca (`archivedAt`), no un estado del ciclo del evento. Se enviará aviso siete días antes y se permitirá reactivarlos si no hay conflicto. La purga física posterior se ejecuta mediante jobs auditados conforme a la política de retención por categoría de dato (DEC-003): solicitudes e-RFQ y ofertas, reservas y snapshots comerciales y auditoría se conservan según el plazo legal/comercial aplicable y no se eliminan por simple cierre de cuenta; archivos temporales y respuestas de WhatsApp pegadas se eliminan o anonimizan 90 días después de cerrar el caso salvo disputa; se soporta `legal_hold` y se registra cada solicitud, ejecución y resultado de eliminación. Los plazos definitivos se validan con asesoría legal colombiana (Ley 1581 de 2012).

### SRS-EVT-008 — Edición de evento con compromisos

**Entrega:** E1

Cuando un evento tenga contrataciones no terminales o solicitudes e-RFQ abiertas, la edición DEBE respetar estas reglas (DEC-024):

1. **Fecha, zona horaria u horario:** no se pueden cambiar mientras existan contrataciones no terminales. El usuario debe cancelar los compromisos afectados según SRS-BOOK-007 o clonar el evento (SRS-EVT-005).
2. **Invitados o ubicación con contrataciones:** el cambio no altera precios congelados. Si afecta un precio por persona o el alcance acordado, se registra una modificación propuesta que la contraparte debe aceptar (SRS-BOOK-005).
3. **Solicitudes e-RFQ abiertas:** cambiar fecha, ubicación o invitados revoca las solicitudes abiertas (`CANCELADO`, SRS-RFQ-013), invalida sus Magic Links, marca las ofertas no adjudicadas como `INVALIDADA` y notifica a los proveedores. El organizador puede lanzar una nueva ronda.
4. Toda edición queda auditada con los valores anteriores y nuevos.

### SRS-EVT-009 — Cancelación de evento con compromisos

**Entrega:** E1

El evento solo PUEDE cancelarse si ninguna de sus contrataciones está en `EN_PROGRESO` o en un estado posterior (SRS-BOOK-009). Al cancelarlo (DEC-024):

1. el evento pasa a `CANCELADO` de inmediato;
2. las solicitudes e-RFQ abiertas pasan a `CANCELADO` y sus Magic Links se invalidan;
3. cada contratación `CONFIRMADO` pasa a `CANCELACION_SOLICITADA` con el motivo indicado y sigue su propio ciclo (SRS-BOOK-007); la capacidad se libera por contratación;
4. se notifica a cada proveedor afectado.

### SRS-EVT-010 — Fechas de capacidad del servicio

**Entrega:** E1

El intervalo del servicio de una contratación es, por defecto, el intervalo del evento. Una contratación consume capacidad (SRS-BOOK-003) en **cada fecha local**, en la zona IANA del evento, que toque ese intervalo. Excepción: si el servicio cruza medianoche y termina a las 06:00 locales o antes del día siguiente, consume solo la fecha de inicio (DEC-025).

Ejemplos:
- viernes 20:00 → sábado 03:00: consume el viernes;
- viernes 18:00 → domingo 14:00: consume viernes, sábado y domingo.

### SRS-EVT-011 — Listado de eventos

**Entrega:** E1

Los miembros DEBEN poder listar los eventos de la empresa activa con filtros por estado, rango de fechas, coordinador responsable y texto, y la opción de incluir archivados (`archivedAt`). El `COORDINADOR_RESTRINGIDO` solo ve los eventos que tiene asignados (SRS-AUTH-011). El listado es paginado y ordenado por fecha de inicio.

## 3.5 Motor de cotización

### SRS-QUO-001 — Cotización rápida

**Entrega:** E1

El usuario podrá seleccionar categoría, subtipo opcional, fecha, invitados, ubicación y presupuesto máximo opcional. El sistema devuelve una tabla comparativa de hasta 20 opciones elegibles (SRS-QUO-002/003) ordenadas por ranking (SRS-QUO-004). La cotización rápida PUEDE guardarse, marcarse como favorita (SRS-QUO-010) y usarse para añadir un proveedor a un evento; no requiere crear un evento previo.

### SRS-QUO-002 — Elegibilidad de proveedores

**Entrega:** E1

El motor solo incluirá proveedores verificados y activos cuyos paquetes:
- coincidan con categoría y subtipo solicitados;
- cubran la ubicación;
- satisfagan capacidad;
- no estén marcados como no disponibles en la fecha;
- estén activos;
- cumplan los filtros seleccionados.

La disponibilidad consultada durante búsqueda no constituye bloqueo.

### SRS-QUO-003 — Comparación normalizada

**Entrega:** E1

La tabla comparativa mostrará hasta 20 resultados, incluyendo proveedor, subtipo, paquete, modalidad, precio unitario, precio total estimado, calificación e inclusiones/exclusiones.

Las ofertas de subtipos diferentes no deberán presentarse como equivalentes en el Bid Tabulation. El usuario podrá comparar subtipos distintos en el catálogo, pero el sistema deberá etiquetarlos claramente.

### SRS-QUO-004 — Ranking

**Entrega:** E1

El orden predeterminado será relación calidad-precio, según la regla RN-04 del PRD, mediante un ranking explicable, versionado y configurable (DEC-004). Primero se aplican los filtros de elegibilidad (proveedor activo y verificado, cobertura, categoría/subtipo, condiciones mínimas); una buena puntuación nunca compensa incumplir un filtro obligatorio. La puntuación inicial pondera:

| Componente | Peso inicial | Descripción |
|---|---|---|
| Calidad ajustada | 40 % | Promedio bayesiano de reseñas verificadas, con contracción hacia el promedio de la categoría cuando hay pocas reseñas |
| Precio relativo | 30 % | Posición del precio total estimado frente a proveedores comparables del mismo subtipo y alcance |
| Proximidad/cobertura | 20 % | Adecuación a la zona de servicio; no premia cercanía si el proveedor no cubre la ubicación |
| Relevancia operativa | 10 % | Coincidencia de categoría/subtipo, modalidad, disponibilidad indicativa y completitud del perfil |

Reglas: sin ubicación precisa, el peso de proximidad se redistribuye proporcionalmente; sin reseñas suficientes se usa el prior de la categoría y se indica la poca evidencia; el precio más bajo no equivale a mejor proveedor; el desempate es determinista (calidad ajustada, luego precio, luego antigüedad de publicación o ID estable); se guardan `ranking_version` y los componentes calculados para reproducir el orden; la interfaz muestra explicaciones simples ("mejor coincidencia", "mejor valor", "mejor calificación con reseñas verificadas") y no el score interno. Los pesos 40/30/20/10 son una hipótesis inicial que se calibrará con datos del piloto. Si faltan datos suficientes, se aplica el criterio de respaldo determinista y no se fabrica una puntuación.

### SRS-QUO-005 — Presupuesto referencial

**Entrega:** E1

En MVP, el presupuesto máximo no excluirá necesariamente proveedores cuyo precio lo exceda. Esos resultados deberán marcarse visualmente como superiores al presupuesto.

### SRS-QUO-006 — Cotización integral

**Entrega:** E1

A partir de plantilla o evento, el motor generará hasta TOP 3 opciones elegibles por categoría/subtipo. Si existen menos de tres, mostrará las disponibles y explicará que no hay más resultados; no generará proveedores ficticios.

### SRS-QUO-007 — Selección y sustitución

**Entrega:** E1

El usuario podrá seleccionar una opción por categoría para el cálculo preliminar y sustituirla sin perder el resto de la selección. Los cambios recalcularán subtotal y total.

### SRS-QUO-008 — Totales

**Entrega:** E1

La cotización deberá mostrar:
- precio estimado por ítem;
- subtotal;
- comisión de plataforma cuando corresponda y esté configurada;
- total estimado.

**Comisión (DEC-027):** la paga la empresa organizadora; su base es el precio acordado del servicio, incluidos los extras aceptados, antes de impuestos; el porcentaje inicial es 3 %, versionado y congelado en el snapshot. Cada paquete DEBE declarar su tratamiento de impuestos (`INCLUIDO`, `NO_APLICA` o `POR_CONFIRMAR`, con tasa opcional y vigencia desde/hasta).

No se aplicará comisión a una oferta simplemente recibida o no adjudicada. La comisión se registrará cuando se cumpla la condición de contratación cerrada definida en SRS-BOOK-008. En MVP, dado que no hay pagos integrados, el cierre se registrará como evento de negocio y no como liquidación financiera.

Separación fiscal (DEC-010): el modelo y la interfaz distinguen (1) el precio total declarado por el proveedor, (2) el tratamiento de impuestos configurado explícitamente por proveedor/operación con vigencia desde/hasta (no se asume IVA universal), (3) la comisión de plataforma, como regla comercial independiente, versionada y congelada en el snapshot de contratación, y (4) el precio mostrado al organizador, indicando si incluye impuestos, si no aplican o si el proveedor debe confirmarlos. El MVP registra el desglose informativo pero no emite factura tributaria ni recauda pagos; la plataforma no sustituye la factura del proveedor.

### SRS-QUO-009 — Guardar borrador

**Entrega:** E1

El usuario podrá guardar cotización como borrador y reanudarla posteriormente, sujeto al aislamiento multiempresa.

### SRS-QUO-010 — Favoritos

**Entrega:** E1

El usuario podrá marcar una cotización rápida como favorita y consultarla posteriormente.

### SRS-QUO-011 — PDF

**Entrega:** E1

El usuario podrá generar PDF profesional con identidad visual de la empresa, información del evento, fecha de generación, proveedores, servicios, desglose, impuestos/precios incluidos y total estimado. El PDF deberá indicar que constituye una cotización estimativa cuando aún no existan ofertas firmes/adjudicación.

### SRS-QUO-012 — Versionado

**Entrega:** E1

MVP almacenará revisiones de cotización cuando se produzcan cambios relevantes, al menos mediante una instantánea inmutable al enviar e-RFQ o generar PDF. Las versiones automáticas Económica/Estándar/Premium quedan para Fase 3.

### SRS-QUO-013 — Redondeo de importes

**Entrega:** E1

Los importes se calculan internamente con precisión decimal `NUMERIC(14,2)`. Cada línea (precio por persona × invitados, extras, comisión, impuestos informativos) se redondea *half-up* al peso entero al presentarse y al congelarse en el snapshot; subtotales, comisión y total se calculan sobre las líneas ya redondeadas. Los importes en COP se presentan sin centavos (DEC-032). El mismo cálculo DEBE producir el mismo resultado en pantalla, PDF y snapshot.

### SRS-QUO-014 — Listado de cotizaciones

**Entrega:** E1

Los miembros DEBEN poder listar las cotizaciones de la empresa activa filtradas por evento y estado (sección 9.6), con su versión vigente, total y fecha de la última generación. Aplican las mismas restricciones de visibilidad del `COORDINADOR_RESTRINGIDO` que en SRS-EVT-011.

## 3.6 Instant Book y control de capacidad

### SRS-BOOK-001 — Condiciones de reserva

**Entrega:** E2 (DEC-021)

La acción Instant Book estará disponible únicamente si:
- el paquete está activo y en modalidad `INSTANT_BOOK`;
- el proveedor está verificado y activo;
- la fecha está disponible;
- la capacidad diaria no ha sido alcanzada;
- el usuario tiene permiso sobre el evento;
- el paquete y su precio siguen vigentes.

### SRS-BOOK-002 — Reserva atómica

**Entrega:** E1 para la regla transaccional aplicada a la adjudicación; E2 para la reserva Instant Book (DEC-021)

**Regla transaccional común (E1):** al confirmar una contratación, el backend deberá volver a validar disponibilidad y capacidad dentro de una transacción atómica. La contratación y el incremento de ocupación deben confirmarse conjuntamente o revertirse conjuntamente.

Esta regla aplica primero a la contratación creada por una adjudicación e-RFQ (SRS-RFQ-009, E1) y, desde E2, a la reserva Instant Book; ambas usan el mismo mecanismo de confirmación (TEC-009).

La aplicación deberá impedir que dos solicitudes concurrentes reserven la última plaza/cupo disponible. Se utilizarán restricciones de base de datos, bloqueo transaccional o mecanismo equivalente; una validación previa en frontend no es suficiente.

### SRS-BOOK-003 — Límite de eventos por fecha

**Entrega:** E1 para la capacidad global; E2 para la capacidad por paquete (DEC-021)

La capacidad se modela en dos niveles (DEC-006):

- **Capacidad global del proveedor por fecha:** valor predeterminado `2` (un proveedor no podrá tener más de dos eventos confirmados en la misma fecha). El conteo se hará sobre reservas activas/confirmadas, excluyendo canceladas y rechazadas.
- **Capacidad por paquete/recurso:** excepción explícita para servicios cuya capacidad no equivale a "un evento por proveedor" (venues, alquiler de equipos, personal por unidades, paquetes paralelos).

Reglas: un paquete sin capacidad propia hereda la global; con capacidad propia, la reserva consume el cupo del paquete y el global, salvo que el proveedor configure inventario independiente; la capacidad y la cantidad requerida son enteros explícitos; un bloqueo manual fija la capacidad disponible en cero o la reduce; la suma de reservas confirmadas no puede exceder ninguna capacidad aplicable; el proveedor no puede cambiar la capacidad retroactivamente para invalidar reservas confirmadas.

### SRS-BOOK-004 — Confirmación

**Entrega:** E2 (DEC-021)

Una reserva exitosa crea un registro de contratación y deja el ítem en `CONFIRMADO`. El precio aceptado, paquete, condiciones y fecha quedarán congelados como snapshot transaccional inmutable (DEC-018): nombre y descripción del paquete, precio y desglose, alcance/inclusiones/exclusiones, configuración fiscal aplicada, porcentaje y base de comisión, proveedor y datos comerciales mínimos, condiciones aceptadas, versión de oferta adjudicada, y fecha/hora y actor que confirmó. Las correcciones se registran como nuevo evento o documento rectificativo; nunca se sobrescribe el acuerdo original.

### SRS-BOOK-005 — Tarifa vinculante

**Entrega:** E2 (DEC-021)

El proveedor no podrá incrementar unilateralmente el precio confirmado. Cualquier cambio de alcance deberá registrarse como modificación propuesta y requerirá aceptación explícita del organizador antes de cambiar el importe.

### SRS-BOOK-006 — Idempotencia

**Entrega:** E2 (DEC-021)

Las solicitudes de reserva deberán admitir una clave de idempotencia para evitar reservas duplicadas por doble clic, reintentos de red o repetición de la petición.

### SRS-BOOK-007 — Cancelación

**Entrega:** E1

La política de cancelación es por etapas (DEC-001) y el MVP no calcula penalidades, multas ni reembolsos:

1. **Antes de la confirmación:** no existe reserva; retirar una selección o solicitud no genera cancelación contractual.
2. **Reserva confirmada y servicio no iniciado:** cualquiera de las partes puede solicitar la cancelación indicando motivo y fecha/hora; la otra parte la acepta o disputa.
3. **Aceptada por ambas partes:** la reserva pasa a `CANCELADO` y se libera la capacidad del proveedor de forma transaccional.
4. **Disputada o sin respuesta en 72 horas:** la reserva pasa a `CANCELACION_EN_REVISION`; la capacidad no se libera hasta resolverla (SRS-ADM-010).
5. **Servicio iniciado o completado:** no hay cancelación ordinaria en autoservicio; requiere soporte/administración conservando el historial.
6. **Causa atribuible a la plataforma o al proveedor:** se registra motivo específico y se habilita revisión administrativa.
7. Siempre se registran actor, fecha, motivo, estado anterior, estado nuevo y evidencia adjunta si existe.

La aceptación es un acuerdo operativo entre las partes y no genera cargos ni promesas de devolución desde ProveeEventos. La cancelación es una transición explícita, distinta del rechazo. Los estados y transiciones están en SRS-BOOK-009 (valores según DEC-022).

### SRS-BOOK-008 — Cierre de contratación y devengo de comisión

**Entrega:** E1

Se separan tres hechos (DEC-002): `BOOKING_CONFIRMED` (compromiso aceptado), `SERVICE_COMPLETED` (servicio ejecutado) y `COMMISSION_ACCRUED` (comisión devengada en el registro interno).

1. El proveedor marca el servicio como realizado.
2. El organizador confirma la finalización o reporta una incidencia dentro de los 5 días calendario siguientes.
3. Si confirma, la contratación se cierra y se registra el devengo.
4. Si no responde, el sistema envía recordatorios y luego cierra automáticamente, siempre que no exista incidencia abierta.
5. Con incidencia o disputa, la comisión queda `RETENIDA` hasta resolverse (SRS-BOOK-010).
6. Si el servicio se cancela antes de ejecutarse, no se devenga comisión.
7. El porcentaje aplicable se congela en el snapshot; cambios de tarifa no alteran reservas históricas, y los devengos erróneos se revierten con auditoría.

El plazo de 5 días es una propuesta operativa que se validará con usuarios durante el piloto. Los estados de la contratación y de la comisión se definen en SRS-BOOK-009 y SRS-BOOK-010.

### SRS-BOOK-009 — Estados de la contratación

**Entrega:** E1

Toda contratación (`Booking`), ya provenga de una adjudicación e-RFQ (E1) o de Instant Book (desde E2), DEBE seguir esta máquina de estados (DEC-023). En E1 el único disparador de creación es la adjudicación:

| Desde | Hacia | Disparador | Regla |
|---|---|---|---|
| — | `CONFIRMADO` | Instant Book o adjudicación | Consume capacidad (SRS-BOOK-002/003) |
| `CONFIRMADO` | `CANCELACION_SOLICITADA` | Organizador o proveedor | Motivo obligatorio; servicio no iniciado |
| `CANCELACION_SOLICITADA` | `CANCELADO` | Contraparte acepta | Libera capacidad en la misma transacción |
| `CANCELACION_SOLICITADA` | `CANCELACION_EN_REVISION` | Contraparte disputa, o 72 h sin respuesta (job), o suspensión del proveedor (SRS-ADM-013) | No libera capacidad |
| `CANCELACION_SOLICITADA` | `CONFIRMADO` | El solicitante retira la solicitud | — |
| `CONFIRMADO` | `CANCELACION_EN_REVISION` | Suspensión del proveedor, con origen `PLATAFORMA` (SRS-ADM-013, DEC-034) | Solo con inicio del servicio futuro; no libera capacidad |
| `CANCELACION_EN_REVISION` | `CANCELADO` o `CONFIRMADO` | `ADMIN_PLATAFORMA` (SRS-ADM-010) | Motivo y auditoría |
| `CANCELACION_EN_REVISION` (origen `PLATAFORMA`) | `CANCELADO` | La organizadora elige cancelar (SRS-ADM-013, DEC-034) | Libera capacidad en la misma transacción |
| `CONFIRMADO` | `EN_PROGRESO` | Job al llegar el inicio local del servicio | Desde aquí no hay cancelación ordinaria |
| `CONFIRMADO` o `EN_PROGRESO` | `SERVICIO_REALIZADO` | Proveedor marca el servicio realizado | Inicia el plazo de 5 días (SRS-BOOK-008) |
| `SERVICIO_REALIZADO` | `COMPLETADO` | Organizador confirma, o 5 días sin incidencia (job) | Devenga comisión (SRS-BOOK-010) |
| `SERVICIO_REALIZADO` | `INCIDENCIA` | Organizador reporta incidencia | Comisión `RETENIDA` |
| `INCIDENCIA` | `COMPLETADO` o `NO_PRESTADO` | `ADMIN_PLATAFORMA` (SRS-ADM-010) | Motivo y auditoría |

Estados terminales: `CANCELADO`, `COMPLETADO` y `NO_PRESTADO`. Una contratación consume capacidad en todos los estados salvo `CANCELADO` y `NO_PRESTADO`. Cualquier otra transición DEBE rechazarse con conflicto de estado. Cada transición registra actor, fecha/hora, estado anterior, estado nuevo y motivo. Los plazos de 72 horas y 5 días son configurables y se calibrarán en el piloto.

Toda contratación en `CANCELACION_EN_REVISION` registra el **origen de la revisión**: `CONTRAPARTE` (disputa o falta de respuesta) o `PLATAFORMA` (suspensión del proveedor). Si una contratación en `CANCELACION_SOLICITADA` pasa a revisión por suspensión, su origen es `PLATAFORMA` y la solicitud de cancelación previa queda en el historial.

### SRS-BOOK-010 — Estado de comisión

**Entrega:** E1

Cada contratación DEBE tener un estado de comisión (DEC-023, DEC-027):

- `PENDIENTE`: desde `CONFIRMADO` hasta `SERVICIO_REALIZADO`;
- `RETENIDA`: mientras la contratación está en `INCIDENCIA`;
- `DEVENGADA`: al pasar a `COMPLETADO`; se registra el importe con el porcentaje y la base congelados en el snapshot (precio acordado con extras aceptados, antes de impuestos, a cargo de la empresa organizadora);
- `NO_APLICA`: contratación `CANCELADO` o `NO_PRESTADO`;
- `REVERTIDA`: corrección de un devengo erróneo por `ADMIN_PLATAFORMA`, con motivo y auditoría; nunca se borra el registro original.

El estado de comisión es un dato de negocio: no implica cobro, factura ni recaudo en el MVP (DEC-033).

## 3.7 e-RFQ / e-RFP en paralelo

### SRS-RFQ-001 — Selección de proveedores

**Entrega:** E1

Para cada ítem e-RFQ, el organizador podrá seleccionar de uno a cinco proveedores. El sistema sugerirá TOP 3 que coincidan en categoría y subtipo, ordenados según ranking y elegibilidad.

### SRS-RFQ-002 — Solicitud individual

**Entrega:** E1

Al enviar, el sistema creará una solicitud independiente por proveedor con snapshot de:
- evento y fecha;
- ubicación;
- número de invitados;
- categoría y subtipo;
- paquete de referencia;
- alcance solicitado;
- datos necesarios para cotizar;
- fecha límite SLA;
- canal previsto.

### SRS-RFQ-003 — Envío paralelo

**Entrega:** E1

Todas las solicitudes seleccionadas se crearán en una única operación lógica. Los despachos externos se procesarán de forma asíncrona y tendrán estado individual de entrega. Un fallo de envío a un proveedor no invalidará los envíos exitosos a los demás.

### SRS-RFQ-004 — SLA

**Entrega:** E1

El organizador seleccionará 6, 12, 24 o 48 horas. El sistema calculará `sla_expira_at` usando una fecha/hora inequívoca. El vencimiento será procesado por cola persistente y también verificado al acceder a la solicitud, para no depender exclusivamente de un temporizador en memoria.

### SRS-RFQ-005 — Estados de solicitud

**Entrega:** E1

Estados:
- `PENDIENTE_ENVIO`;
- `ENVIADO`;
- `RESPONDIDO`;
- `RECHAZADO`;
- `EXPIRADO`;
- `ADJUDICADO`;
- `NO_ADJUDICADO`;
- `ERROR_ENVIO` (estado operativo);
- `CANCELADO` (revocada por el organizador, por la edición o cancelación del evento, o por la administración; SRS-RFQ-013).

Una solicitud vencida no podrá ser respondida con el token original. Si el proveedor responde justo al límite, prevalecerá la hora de recepción registrada por el servidor: se acepta solo si `received_at <= sla_expira_at`.

### SRS-RFQ-006 — Oferta estructurada

**Entrega:** E1

El proveedor podrá:
- confirmar disponibilidad;
- aceptar o rechazar;
- introducir precio firme total;
- desglosar extras;
- registrar condiciones;
- añadir notas.

El sistema validará que una oferta aceptada incluya precio total, moneda, vigencia/condiciones mínimas y disponibilidad declarada.

### SRS-RFQ-007 — Respuesta única y correcciones

**Entrega:** E1

El Magic Link será de un solo uso. Una vez enviada la oferta, el enlace quedará invalidado. Las correcciones posteriores se realizarán mediante una nueva versión de oferta iniciada desde una acción autenticada del proveedor o por reemisión de solicitud autorizada; nunca reactivando silenciosamente el token consumido.

Política de revisiones (DEC-005, TEC-001): una oferta enviada es inmutable. El proveedor puede crear una revisión mientras la solicitud siga abierta y no exista adjudicación, indicando el motivo y confirmando que reemplaza el precio/alcance anterior. La revisión anterior queda en historial como reemplazada, nunca borrada. El Bid Tabulation muestra por defecto la última revisión válida y permite consultar las previas. Al vencer el SLA no se admiten revisiones; para obtener una nueva oferta se crea una nueva ronda (`RfqCycle`), que puede reinvitar al mismo proveedor (DEC-026). Tras la adjudicación la oferta queda congelada; cualquier cambio requiere cancelar la contratación según SRS-BOOK-007 y, si procede, lanzar una nueva ronda. `Offer` es un agregado independiente de `RfqRequest`.

### SRS-RFQ-008 — Bid Tabulation

**Entrega:** E1

El sistema consolidará ofertas por ítem, proveedor y subtipo. Las columnas mínimas serán:
- proveedor;
- estado de respuesta;
- disponibilidad declarada;
- precio firme;
- extras;
- condiciones;
- notas;
- hora de respuesta;
- canal/origen.

Las ofertas se presentarán en una estructura homogénea sin alterar el contenido original del proveedor.

### SRS-RFQ-009 — Adjudicación

**Entrega:** E1

El organizador podrá adjudicar una oferta. La operación deberá ser atómica:
1. verificar que la oferta esté respondida y que su vigencia (`offerValidityUntil`) no haya vencido (SRS-RFQ-012);
1b. verificar y consumir la capacidad del proveedor en las fechas del servicio (SRS-EVT-010) con la misma regla y el mismo mecanismo transaccional de SRS-BOOK-002/003 (TEC-009); si no hay capacidad, rechazar con conflicto de capacidad y no adjudicar;
2. verificar que el ítem siga abierto;
3. marcar oferta elegida como `ADJUDICADO`;
4. marcar las demás solicitudes abiertas/respondidas como `NO_ADJUDICADO`;
5. crear o confirmar el ítem contratado;
6. generar notificaciones de resultado.

Una segunda adjudicación concurrente deberá rechazarse con conflicto de estado. Una adjudicación concurrente con una reserva Instant Book sobre el último cupo del proveedor deberá resolverse con una sola confirmación.

### SRS-RFQ-010 — Sin respuesta o rechazo

**Entrega:** E1

Al rechazar, vencer o cancelar una solicitud, el sistema sugerirá proveedores alternativos elegibles de la misma categoría/subtipo; la nueva ronda puede reinvitar al mismo proveedor. La invitación de reemplazo requerirá confirmación del organizador y respetará el máximo de cinco invitaciones simultáneas por ciclo de solicitud. El ciclo se modela con `RfqCycle`, agrupador de las solicitudes paralelas de una ronda para un ítem (TEC-002); el límite de 1–5 proveedores se garantiza en base de datos.

### SRS-RFQ-011 — Avisos de cortesía

**Entrega:** E1

Al adjudicar, los proveedores no seleccionados recibirán notificación de no adjudicación. El contenido no revelará precios ni datos privados de competidores.

### SRS-RFQ-012 — Ofertas con vigencia vencida

**Entrega:** E1

Una oferta cuya vigencia (`offerValidityUntil`) haya vencido DEBE mostrarse en el Bid Tabulation marcada como "vencida" y NO DEBE poder adjudicarse. Mientras la solicitud siga abierta, el proveedor PUEDE crear una revisión con nueva vigencia (SRS-RFQ-007). Si la solicitud ya no está abierta, el organizador puede invitar al proveedor en una nueva ronda (DEC-026).

El sistema DEBE marcar `VENCIDA` la oferta al llegar su vigencia, mediante un job idempotente además de la verificación al consultar o adjudicar. Si la solicitud queda sin ninguna oferta `RECIBIDA` y su SLA ya venció, pasa a `NO_ADJUDICADO`; la condición se evalúa al vencer la oferta y al vencer el SLA (DEC-035).

### SRS-RFQ-013 — Revocación y reenvío

**Entrega:** E1

1. El organizador PUEDE revocar una solicitud en `PENDIENTE_ENVIO`, `ENVIADO`, `RESPONDIDO` o `ERROR_ENVIO` indicando el motivo; la solicitud pasa a `CANCELADO`, su Magic Link se invalida y se notifica al proveedor. La edición o cancelación del evento revoca las solicitudes según SRS-EVT-008/009, y `ADMIN_PLATAFORMA` puede revocar con motivo auditado.
2. Una solicitud en `ERROR_ENVIO` PUEDE reintentarse (→ `PENDIENTE_ENVIO`) hasta 3 veces; después solo puede cancelarse.
3. Una solicitud adjudicada no puede revocarse; su contratación se gestiona con SRS-BOOK-007.

Origen: DEC-026.

## 3.8 Email y Magic Link

### SRS-MAGIC-001 — Generación de enlace

**Entrega:** E1

Cada solicitud e-RFQ por email tendrá un token aleatorio criptográficamente seguro, almacenándose únicamente su hash. El enlace estará asociado a una solicitud específica y tendrá propósito limitado.

### SRS-MAGIC-002 — Validez

**Entrega:** E1

El token expirará al ocurrir primero:
- vencimiento del SLA;
- respuesta válida;
- revocación/cancelación de la solicitud;
- invalidación administrativa.

### SRS-MAGIC-003 — Uso único

**Entrega:** E1

El consumo del token y el registro de la respuesta deberán ejecutarse atómicamente. Repeticiones posteriores mostrarán una página informativa sin revelar datos sensibles.

### SRS-MAGIC-004 — Protección

**Entrega:** E1

El sistema deberá:
- usar HTTPS;
- evitar tokens en logs y analítica;
- aplicar rate limiting;
- limitar intentos de consulta;
- no incluir el token en la ruta ni en la query de la URL: el enlace lleva el token en el fragmento (`/r#<token>`) y la página lo envía en el cuerpo de la petición (TEC-008);
- no incluir datos personales sensibles en URL;
- usar cabeceras anti-cache apropiadas;
- no cargar recursos de terceros que puedan filtrar el token;
- registrar eventos de emisión, apertura cuando sea medible (sin contar las aperturas de escáneres de correo), consumo, expiración y revocación.

### SRS-MAGIC-005 — Formulario móvil

**Entrega:** E1

El formulario será responsive y permitirá responder sin crear cuenta ni iniciar sesión. Antes de mostrar datos del evento, el token deberá validarse.

### SRS-MAGIC-006 — Notificación de respuesta

**Entrega:** E1

Al aceptar/rechazar, el sistema actualizará el Bid Tabulation y notificará al organizador.

## 3.9 WhatsApp MVP y asistente de IA

### SRS-WA-001 — Plantillas

**Entrega:** E2, adelantable a E1 si hay capacidad (DEC-021)

El sistema mantendrá plantillas globales administradas por `ADMIN_PLATAFORMA` y copias personalizadas por empresa. Las plantillas se organizarán por categoría y permitirán variables como:
`{{nombre_proveedor}}`, `{{subtipo_servicio}}`, `{{fecha_evento}}`, `{{num_invitados}}`, `{{ubicacion_evento}}`, `{{link_formulario}}`.

### SRS-WA-002 — Renderizado determinista

**Entrega:** E2 (DEC-021)

El mensaje se generará por sustitución segura de variables. No se invocará IA para redactar mensajes salientes. Las variables faltantes deberán detectarse antes de abrir WhatsApp.

### SRS-WA-003 — Click-to-Chat

**Entrega:** E2 (DEC-021)

El sistema generará un enlace `wa.me` con número normalizado y texto URL-encoded. El usuario deberá confirmar/ejecutar el envío desde WhatsApp. La plataforma no afirmará que el mensaje fue enviado ni entregado por el mero hecho de abrir el enlace.

### SRS-WA-004 — Limitación de recepción

**Entrega:** E2 (DEC-021)

En MVP no habrá recepción automatizada de mensajes entrantes de WhatsApp ni webhook. El organizador deberá copiar/pegar la respuesta recibida para iniciar el proceso asistido.

### SRS-WA-005 — Asistente IA asistido

**Entrega:** E2 (DEC-021)

El sistema permitirá seleccionar una respuesta libre y generar un prompt estructurado que solicite una salida JSON conforme a un esquema definido. El organizador podrá copiar el prompt a una herramienta de IA externa de uso autorizado y pegar/importar el JSON resultante.

### SRS-WA-006 — Validación del JSON

**Entrega:** E2 (DEC-021)

El backend validará el JSON importado contra un esquema estricto:
- proveedor y solicitud objetivo;
- disponibilidad;
- decisión (oferta/rechazo);
- precio y moneda;
- extras;
- condiciones;
- notas.

Los campos desconocidos se ignorarán o rechazarán según versión del esquema; los importes no válidos no se guardarán.

### SRS-WA-007 — Revisión humana

**Entrega:** E2 (DEC-021)

Antes de registrar la oferta, el organizador deberá revisar y confirmar los datos extraídos. La IA no podrá adjudicar, confirmar reservas ni cambiar precios por sí sola.

### SRS-WA-008 — Trazabilidad de origen

**Entrega:** E2 (DEC-021)

Las respuestas importadas se marcarán como `WHATSAPP_IA_ASISTIDO`, incluyendo usuario que importó, fecha y datos originales aportados. No se afirmará que el sistema verificó automáticamente la identidad del remitente de WhatsApp.

### SRS-WA-009 — Adaptador futuro

**Entrega:** E2 (DEC-021)

La lógica de normalización se expondrá mediante una interfaz desacoplada para permitir la futura integración API oficial, sin que ello implique que el MVP automatice sesiones/login de proveedores de IA ni realice scraping.

## 3.10 Seguimiento de eventos y estados

### SRS-TRK-001 — Seguimiento por ítem

**Entrega:** E1

Cada servicio de un evento tendrá estado individual y un historial de transiciones.

### SRS-TRK-002 — Estados del ítem

**Entrega:** E1

Estados visibles de negocio:
- `COTIZADO`;
- `ENVIADO`;
- `CONFIRMADO`;
- `RECHAZADO`;
- `EN_PROGRESO`;
- `COMPLETADO`;
- `CALIFICADO`.

Estados internos adicionales: `CANCELADO` (contratación cancelada o no prestada, o evento cancelado sin contratación), `EXPIRADO` (la ronda terminó sin ofertas por vencimiento del SLA) y `NO_ADJUDICADO` (la ronda terminó con ofertas, pero ninguna se adjudicó). No se fuerzan dentro de una transición incorrecta. El grafo completo de transiciones está en la sección 9.3 y la correspondencia con el estado de la contratación, en la sección 9.5.

### SRS-TRK-003 — Transiciones

**Entrega:** E1

Las transiciones deberán validarse en backend según la sección 9.3 y auditar actor, timestamp, estado anterior, estado nuevo y motivo. No se permitirá pasar directamente de `COTIZADO` a `CALIFICADO`.

### SRS-TRK-004 — Vista MVP

**Entrega:** E1

El panel de seguimiento será una tabla con filtros por estado y vencimiento SLA. El tablero Kanban queda para Fase 2.

## 3.11 Calificaciones y reseñas

### SRS-REV-001 — Elegibilidad

**Entrega:** E1

Solo un usuario autorizado de la empresa propietaria del evento podrá calificar al proveedor contratado cuando el ítem esté `COMPLETADO`.

### SRS-REV-002 — Dimensiones

**Entrega:** E1

Cada calificación contendrá cuatro puntuaciones enteras de 1 a 5:
- puntualidad;
- calidad del servicio;
- comunicación;
- relación precio-calidad.

### SRS-REV-003 — Promedio

**Entrega:** E1

El promedio será la media aritmética de las cuatro dimensiones para esa reseña. El promedio público del proveedor se calculará a partir de las reseñas válidas, con precisión interna definida y redondeo solo en presentación.

### SRS-REV-004 — Una reseña por contratación

**Entrega:** E1

Una contratación podrá generar como máximo una reseña principal por empresa/proveedor. La reseña no es editable una vez publicada; las correcciones se gestionan por moderación con historial de auditoría (SRS-REV-008).

### SRS-REV-005 — Texto

**Entrega:** E1

La reseña tendrá máximo 500 caracteres. La respuesta del proveedor tendrá máximo 300 caracteres.

### SRS-REV-006 — Respuesta del proveedor

**Entrega:** E1

El proveedor solo podrá responder reseñas asociadas a su perfil. No podrá modificar la reseña original ni la puntuación.

### SRS-REV-007 — Moderación

**Entrega:** E1

Las reseñas reportadas pasarán a una cola de moderación. La moderación podrá ocultar contenido por incumplimiento de políticas, conservando el registro y motivo.

### SRS-REV-008 — Ventana, visibilidad y reporte

**Entrega:** E1

1. La reseña puede crearse durante los 30 días siguientes a que la contratación pase a `COMPLETADO`.
2. La reseña muestra el nombre comercial de la empresa autora (PRD RF-CAL-03) y no muestra datos personales del usuario que la escribió.
3. Pueden reportarla el proveedor afectado y `ADMIN_PLATAFORMA`, con un motivo de la lista `OFENSIVO`, `FALSO`, `DATOS_PERSONALES`, `OTRO` y detalle opcional; un mismo actor no puede reportar dos veces la misma reseña.

Origen: DEC-030.

## 3.12 Administración

### SRS-ADM-001 — Verificación de proveedores

**Entrega:** E1 para niveles 1–2; E2 para el nivel 3 (DEC-021)

El administrador podrá aprobar o rechazar proveedores mediante verificación por niveles, con evidencia proporcional a la categoría y al riesgo (DEC-009):

- **Nivel 1 — Identidad y contacto:** email y teléfono verificados, nombre legal o de persona, ciudad y datos de contacto consistentes.
- **Nivel 2 — Actividad comercial:** tipo de proveedor (persona natural o empresa), identificación fiscal/comercial aplicable (p. ej. NIT), datos de facturación si son necesarios, aceptación de términos y política de datos.
- **Nivel 3 — Evidencia del servicio:** portafolio o trabajos previos, referencias o documentos adicionales en categorías de mayor riesgo, y revisión manual en categorías de seguridad, transporte, cuidado de personas, alimentos u otras con obligaciones especiales.

Se almacena qué evidencia se revisó, quién, cuándo, resultado y vencimiento si aplica; no se guardan documentos de identidad completos si basta una verificación externa o metadato mínimo. La etiqueta pública distingue "identidad/contacto verificados" de "experiencia revisada" y no implica garantía de calidad del servicio. El rechazo deberá registrar motivo y permitir corrección/reenvío del perfil; documentos vencidos y apelación se gestionan por política operativa.

### SRS-ADM-002 — Taxonomía

**Entrega:** E1

El administrador podrá crear, editar, activar y desactivar categorías y subtipos. Los cambios deberán conservar referencias históricas.

### SRS-ADM-003 — Plantillas de eventos

**Entrega:** E1

El administrador podrá crear, editar y desactivar plantillas globales. Las plantillas ya copiadas por empresas no deberán cambiar retroactivamente.

### SRS-ADM-004 — Plantillas WhatsApp

**Entrega:** E2, adelantable a E1 si hay capacidad (DEC-021)

El administrador podrá gestionar plantillas globales. Las empresas podrán crear personalizaciones privadas sin alterar la versión global.

### SRS-ADM-005 — Suspensión

**Entrega:** E1

El administrador podrá suspender usuarios/proveedores con motivo y registro de auditoría. El tratamiento de las solicitudes, ofertas y contrataciones del proveedor suspendido se define en SRS-ADM-013.

### SRS-ADM-006 — Moderación

**Entrega:** E1

El administrador podrá revisar reportes de reseñas, resolverlos y registrar la decisión.

### SRS-ADM-007 — Dashboard

**Entrega:** E1

El panel administrativo mostrará como mínimo:
- usuarios registrados;
- proveedores activos;
- eventos creados;
- cotizaciones generadas;
- ingresos registrados.

Los ingresos solo podrán mostrarse como cero/no disponibles si no existe módulo de cobro integrado; no se inferirán a partir del valor de cotizaciones.

### SRS-ADM-008 — Exportación de comisiones y suscripciones

**Entrega:** E1

`ADMIN_PLATAFORMA` DEBE poder exportar, por periodo, las comisiones `DEVENGADA` y `REVERTIDA` (contratación, empresa, proveedor, base, porcentaje, importe, fecha de cierre) y las suscripciones activas por plan, para la facturación externa y la conciliación manual. Puede registrar la referencia de factura y de pago. ProveeEventos factura fuera del sistema mediante un proveedor de facturación electrónica habilitado ante la DIAN (DEC-033; requiere validación contable).

### SRS-ADM-009 — Gestión de planes

**Entrega:** E1

`ADMIN_PLATAFORMA` DEBE poder crear y versionar planes (SRS-TEN-004), asignar o cambiar el plan de una empresa con fecha de inicio y fin, y consultar el consumo de límites por empresa. Cada cambio queda auditado.

### SRS-ADM-010 — Resolución de disputas

**Entrega:** E1

`ADMIN_PLATAFORMA` DEBE disponer de una bandeja de casos con:
- contrataciones en `CANCELACION_EN_REVISION` (resolución: `CANCELADO` o `CONFIRMADO`), mostrando el origen de la revisión y, si es `PLATAFORMA`, la elección de la organizadora y el fin de su ventana de decisión (SRS-ADM-013);
- contrataciones en `INCIDENCIA` (resolución: `COMPLETADO` o `NO_PRESTADO`);
- reversión de comisiones devengadas por error (`REVERTIDA`);
- apelaciones de verificación de proveedores rechazados.

Cada resolución registra actor, fecha, motivo, estado anterior y nuevo, y notifica a ambas partes. No se calculan penalidades ni reembolsos (DEC-001).

### SRS-ADM-011 — Consulta de auditoría

**Entrega:** E1

`ADMIN_PLATAFORMA` DEBE poder consultar el registro de auditoría (sección 4.5) con filtros por rango de fechas, actor, tenant, acción y tipo de recurso. La consulta:
- muestra los campos de la sección 4.5, nunca payloads sensibles completos ni tokens;
- queda a su vez auditada (quién consultó y con qué filtros);
- no permite modificar ni borrar registros.

### SRS-ADM-012 — Solicitudes de titulares y retención legal

**Entrega:** E1

1. Todo usuario DEBE poder registrar desde la aplicación una solicitud de consulta, corrección o supresión de sus datos y consultar el estado de sus solicitudes (SRS-NFR-PRIV-002).
2. `ADMIN_PLATAFORMA` DEBE disponer de una cola de solicitudes con tipo, estado (`RECIBIDA`, `EN_TRAMITE`, `RESUELTA`, `RECHAZADA`), responsable, fecha límite, resultado y motivo, y registrar cada cambio.
3. `ADMIN_PLATAFORMA` PUEDE activar y liberar una retención legal (`legal_hold`) sobre un recurso (evento, contratación, oferta, reseña, usuario o empresa) con motivo obligatorio. Mientras esté activa, los jobs de archivado, anonimización y eliminación (SRS-EVT-007, sección 4.6) excluyen el recurso y sus dependientes.
4. Una supresión que choque con una retención obligatoria o un `legal_hold` se resuelve parcialmente: se suprime lo permitido y se informa al titular lo que se conserva y por qué.

**Plazos provisionales (DEC-037):** la fecha límite de cada solicitud se calcula en días hábiles con un calendario de festivos de Colombia configurable:

| Tipo de solicitud | Plazo | Prórroga única |
|---|---|---|
| Consulta | 10 días hábiles desde el recibo | Hasta 5 días hábiles más |
| Corrección o supresión (reclamo) | 15 días hábiles desde el día siguiente al recibo | Hasta 8 días hábiles más |

La prórroga exige registrar el motivo e informar al titular antes de que venza el primer plazo, y solo se concede una vez. La cola se ordena por fecha límite y marca las solicitudes vencidas. Los plazos provienen de los artículos 14 y 15 de la Ley 1581 de 2012 y DEBEN validarse con asesoría legal, igual que los pasos intermedios de la ley, antes de operar con datos reales.

### SRS-ADM-013 — Suspensión de proveedor con contrataciones futuras

**Entrega:** E1

Al suspender un proveedor (SRS-ADM-005), el sistema DEBE aplicar DEC-034:
1. Bloquear su aparición en el catálogo, nuevas solicitudes e-RFQ, respuestas, ofertas y reservas Instant Book; invalidar sus Magic Links.
2. Revocar sus solicitudes e-RFQ abiertas (`CANCELADO`, SRS-RFQ-013) e invalidar sus ofertas no adjudicadas (`INVALIDADA`).
3. Pasar cada contratación `CONFIRMADO` o `CANCELACION_SOLICITADA` con inicio futuro a `CANCELACION_EN_REVISION`, con origen `PLATAFORMA` y el motivo de la suspensión (SRS-BOOK-009), y avisar a la organizadora. Una contratación que ya estaba en `CANCELACION_EN_REVISION` conserva su origen y la resuelve la administración.
4. La organizadora elige en 72 h mantener la contratación (vuelve a `CONFIRMADO` si la administración confirma que el proveedor puede prestar el servicio) o cancelarla (`CANCELADO`); sin respuesta, resuelve la administración (SRS-ADM-010). Eligen los roles que pueden cancelar contrataciones (SRS-AUTH-009).
5. Las contrataciones `EN_PROGRESO` o posteriores siguen su ciclo normal (para las acciones del proveedor suspendido, SRS-AUTH-007).
6. La capacidad solo se libera cuando la contratación termina en `CANCELADO`. No hay penalidades ni reembolsos automáticos.
7. Se audita la suspensión con la lista de contrataciones afectadas y cada elección de la organizadora. La reactivación (SRS-AUTH-007) no restaura automáticamente las contrataciones canceladas.
8. La suspensión se aplica en una sola operación atómica y no admite carreras: una adjudicación o reserva simultánea se rechaza, o la contratación creada queda incluida en la revisión (SAD §7.6; DEC-036).

**Operación de la decisión (DEC-036):**
- La ventana de decisión termina en lo primero que ocurra entre 72 h después de la suspensión y el inicio local del servicio. Ese es el plazo efectivo de la regla 4.
- Cancelar es definitivo. Mantener queda registrado y puede cambiarse a cancelar mientras la ventana siga abierta y el caso no esté resuelto; la contratación sigue en `CANCELACION_EN_REVISION`.
- La administración resuelve solo después de que la organizadora elija mantener o de que la ventana se cierre sin respuesta; antes, la resolución se rechaza con conflicto de estado.
- Al cerrarse la ventana, un job marca el caso como pendiente de la administración y le avisa, sin cambiar el estado.
- Elegir fuera de la ventana, o sobre una contratación que no está en revisión de origen `PLATAFORMA`, se rechaza con conflicto de estado.

## 3.13 Notificaciones

### SRS-NOT-001 — Email transaccional

**Entrega:** E1

Se enviarán emails para:
- verificación de cuenta;
- invitación a coordinador;
- recuperación de acceso (gestionada por Auth0);
- solicitud e-RFQ;
- reserva Instant Book;
- respuesta de proveedor;
- vencimiento SLA;
- recordatorio de evento próximo;
- aviso de calificación post-evento;
- rechazo/aprobación/suspensión de proveedor;
- contratación puesta en revisión por suspensión del proveedor, a la organizadora, con el fin de la ventana de decisión (SRS-ADM-013);
- no adjudicación.

### SRS-NOT-002 — Notificación in-app

**Entrega:** E1

El sistema mantendrá notificaciones por usuario con estado leída/no leída, fecha, tipo y destino de acción.

### SRS-NOT-003 — Preferencias

**Entrega:** E1

El usuario podrá configurar categorías de email que desea recibir, excepto comunicaciones esenciales de seguridad, transacciones o cumplimiento que no puedan desactivarse.

### SRS-NOT-004 — Tiempo de despacho

**Entrega:** E1

El despacho de email se iniciará dentro de cinco minutos desde el evento disparador. La entrega final dependerá del proveedor de correo y no se garantizará como controlada por la aplicación.

### SRS-NOT-005 — Reintentos

**Entrega:** E1

Los fallos temporales de envío tendrán reintentos con backoff y límite. Los fallos permanentes quedarán visibles en logs operativos sin exponer datos sensibles.

### SRS-NOT-006 — Estado de entrega de email

**Entrega:** E1

El sistema DEBE recibir los eventos de entrega del proveedor de correo mediante un webhook firmado (entregado, rebotado, bloqueado, spam) y actualizar el estado de despacho (`dispatchStatus`) de la notificación o la solicitud e-RFQ asociada. Un rebote permanente marca la solicitud e-RFQ como `ERROR_ENVIO` (SRS-RFQ-013) y avisa al organizador. El dominio remitente DEBE tener SPF, DKIM y DMARC configurados. La aceptación del envío por el proveedor de correo no equivale a entrega.

---

# 4. Requisitos de datos

## 4.1 Entidades principales

El modelo lógico del MVP incluirá como mínimo:

| Entidad | Responsabilidad |
|---|---|
| Usuario | Identidad interna, rol, estado y referencia al proveedor de identidad |
| Empresa | Tenant organizador, NIT, datos comerciales y plan |
| Coordinador | Relación usuario-empresa |
| Proveedor | Perfil, estado de verificación, cobertura y preferencias |
| Categoría | Nivel superior de taxonomía |
| Subtipo | Especialización perteneciente a una categoría |
| ProveedorCategoría | Relación proveedor-categoría-subtipos |
| PaqueteServicio | Oferta comercial del proveedor |
| Disponibilidad | Fechas/cupos ocupados o bloqueados |
| Portafolio | Referencias multimedia |
| PlantillaEvento | Plantilla global o privada |
| PlantillaCategoría | Categorías/subtipos incluidos en plantilla |
| Evento | Evento propiedad de una empresa |
| Cotización | Snapshot/versionado de propuesta |
| CotizaciónItem | Servicio requerido y seleccionado |
| SolicitudRFQ | Invitación individual a proveedor |
| OfertaRFQ | Datos estructurados de la respuesta, versionables |
| Reserva/Contratación | Compromiso confirmado Instant Book o adjudicado |
| Calificación | Evaluación B2B post-evento |
| Notificación | Aviso in-app/email |
| PlantillaWhatsApp | Plantilla global o privada |
| Auditoría | Historial de cambios sensibles/transaccionales |
| SolicitudTitular | Solicitud de consulta, corrección o supresión de datos personales: tipo, estado, responsable, fechas y resultado (SRS-ADM-012, SRS-NFR-PRIV-002) |
| RetencionLegal | Retención legal (`legal_hold`) sobre un recurso: tipo y ID del recurso, motivo, actor, fechas de activación y liberación (SRS-ADM-012, SRS-EVT-007) |

## 4.2 Reglas de integridad

1. Todas las entidades transaccionales tendrán identificadores únicos.
2. Las claves foráneas deberán impedir referencias huérfanas.
3. NIT será único después de normalización.
4. Email será único según la política de identidad.
5. Un subtipo deberá pertenecer a la categoría referenciada por el paquete.
6. Un ítem de cotización no podrá adjudicarse más de una vez.
7. Un token Magic Link solo podrá consumirse una vez.
8. Una reserva no podrá exceder capacidad ni límite diario del proveedor.
9. Los registros históricos conservarán snapshots de precio, nombre de paquete, categoría/subtipo y condiciones relevantes.
10. Los registros de auditoría no se modificarán desde operaciones ordinarias de usuario.

## 4.3 Tipos y precisión

- Identificadores: UUID.
- Importes: `NUMERIC(14,2)` en COP, con redondeo *half-up* al peso entero por línea según SRS-QUO-013; no usar `FLOAT`/`DOUBLE`.
- Cantidades de personas/capacidad: enteros positivos.
- Calificaciones: enteros 1–5.
- Fechas de evento: fecha local del evento.
- Timestamps operativos: UTC.
- Teléfonos: normalización internacional E.164.
- JSON: solo para atributos extensibles, nunca para reemplazar relaciones centrales consultables.

## 4.4 Disponibilidad y capacidad

El PRD combina calendario por fecha y máximo de dos eventos por proveedor/día. Para resolverlo:
- cada fecha tendrá capacidad máxima configurable, con valor predeterminado 2 eventos;
- la reserva Instant Book consumirá un cupo;
- la reserva adjudicada de e-RFQ también consumirá un cupo al confirmarse;
- los estados cancelados/rechazados no consumirán cupo;
- el control se hará transaccionalmente;
- una fecha marcada como ocupada se tratará como capacidad cero, salvo que el proveedor configure explícitamente disponibilidad parcial/cupo adicional.

El modelo de disponibilidad deberá poder evolucionar de un booleano `ocupado` a cupos por fecha sin romper el contrato funcional.

## 4.5 Auditoría

Se auditarán como mínimo:
- precios y condiciones de paquetes;
- precios de ofertas;
- creación/cambio/cancelación de reservas;
- adjudicaciones;
- cambios de estados;
- verificación/suspensión;
- modificaciones de taxonomía;
- cambios de plan;
- cambios de permisos;
- moderación de reseñas.

Cada evento de auditoría incluirá actor, entidad, identificador, acción, timestamp y valores anteriores/nuevos cuando sea apropiado.

## 4.6 Retención y eliminación

La eliminación de datos personales se atenderá conforme a la normativa colombiana y la política de privacidad. La eliminación de una cuenta no deberá romper transacciones históricas ni auditoría legalmente necesaria; se aplicará anonimización o supresión selectiva cuando proceda.

---

# 5. Reglas de negocio consolidadas

| ID | Regla |
|---|---|
| RN-01 | Solo proveedores `VERIFICADO` y activos aparecen en catálogo. |
| RN-02 | El promedio de una reseña es la media de sus cuatro dimensiones. |
| RN-03 | Solo contrataciones completadas habilitan calificación. |
| RN-04 | El ranking calidad-precio usa la fórmula del PRD y un fallback determinista si faltan datos. |
| RN-05 | Máximo cinco categorías principales por proveedor. |
| RN-06 | Borradores inactivos 90 días: archivo con aviso siete días antes (DEC-003). |
| RN-07 | Presupuesto referencial en MVP; se marcan excesos. |
| RN-08 | Capacidad global predeterminada de dos eventos confirmados por proveedor y fecha, con capacidad por paquete como excepción (DEC-006). |
| RN-09 | Comisión solo para contrataciones cerradas según SRS-BOOK-008; no para ofertas rechazadas/no adjudicadas ni servicios cancelados; con incidencia queda `RETENIDA` (DEC-002, SRS-BOOK-010). |
| RN-10 | El tratamiento de impuestos es una configuración explícita por proveedor/servicio; el precio mostrado indica si incluye impuestos, no aplican o requieren confirmación (DEC-010). |
| RN-11 | Máximo cinco proveedores invitados en un ciclo e-RFQ por ítem; TOP 3 predeterminado. |
| RN-12 | Precio Instant Book vinculante, salvo cambio de alcance aceptado. |
| RN-13 | SLA expira Magic Link y solicitud; respuesta posterior no se acepta con token expirado. |
| RN-14 | Mensajes salientes WhatsApp se ensamblan con plantillas, sin IA. |
| RN-15 | Un ítem de cotización solo puede tener una adjudicación ganadora. |
| RN-16 | Una reserva confirmada consume capacidad de proveedor para la fecha. |
| RN-17 | Abrir un enlace `wa.me` no significa que el mensaje haya sido enviado o recibido. |
| RN-18 | Toda respuesta asistida por IA requiere revisión humana antes de incorporarse como oferta. |
| RN-19 | Los datos de cada empresa están aislados de otros tenants. |
| RN-20 | Una oferta recibida no equivale a contratación hasta que sea adjudicada y confirmada. |
| RN-21 | Con contrataciones activas no se cambia la fecha del evento; con RFQ abiertas, cambiar fecha, ubicación o invitados revoca las solicitudes (DEC-024). |
| RN-22 | Una contratación consume capacidad en cada fecha local que toca su servicio, salvo cruces de medianoche que terminan a las 06:00 o antes (DEC-025). |
| RN-23 | La comisión la paga la empresa organizadora sobre el precio acordado con extras, antes de impuestos (DEC-027). |
| RN-24 | El contacto directo del proveedor solo se revela tras una RFQ enviada (vía `wa.me`) o una contratación confirmada (DEC-028). |
| RN-25 | Alcanzar un límite del plan impide crear recursos nuevos, nunca gestionar compromisos existentes (DEC-029). |

---

# 6. Interfaces externas

## 6.1 API de aplicación

La API será REST/JSON según la arquitectura de referencia. Los contratos detallados se documentarán en OpenAPI durante el SAD/TDD.

Requisitos generales:
- versionado de API;
- validación de entrada;
- errores con códigos consistentes;
- paginación para colecciones;
- filtros explícitos;
- autenticación y autorización en backend;
- idempotencia para operaciones de reserva/adjudicación;
- correlación de solicitudes para observabilidad.

## 6.2 Auth0

La aplicación utilizará Auth0 para registro/autenticación y recuperación de credenciales. El backend mantendrá el mapeo de identidad externa con usuario interno y aplicará autorización propia por tenant y rol.

## 6.3 SendGrid

Se utilizará para emails transaccionales. Los envíos deberán ser idempotentes cuando el disparador pueda repetirse y registrar el identificador de proveedor de correo.

## 6.4 Cloudinary

Se utilizará para subir, transformar y servir multimedia. El backend validará autorización y propiedad antes de aceptar o asociar recursos.

## 6.5 WhatsApp Click-to-Chat

El MVP solo genera un enlace prellenado. El sistema no tendrá acceso a confirmación de envío, entrega ni recepción. La integración oficial con webhooks pertenece a Fase 2.

## 6.6 Google Maps API

Alcance en el MVP (DEC-015): autocompletado de ciudad/dirección cuando el usuario lo necesite, geocodificación de la ubicación del evento y de la cobertura del proveedor, y distancia aproximada sin prometer tiempos de desplazamiento. Quedan fuera optimización de rutas, tráfico y mapas avanzados. La captura manual siempre estará disponible y la cotización deberá seguir funcionando si el proveedor de mapas falla. Se aplican cuotas, alertas de consumo y restricciones de API key.

## 6.7 Generación PDF

El servicio generará PDF a partir de una instantánea (snapshot) de cotización, nunca de datos vivos que puedan cambiar durante la generación. La tecnología por defecto es React-PDF; se usa Puppeteer solo si un prototipo con una cotización realista (tablas largas, saltos de página, tipografías en español, encabezados/pies, tiempo y memoria) demuestra que el diseño requiere fidelidad HTML/CSS (DEC-016). El archivo deberá quedar asociado a la empresa/evento y tener controles de acceso equivalentes a los del recurso original.

---

# 7. Requisitos no funcionales

## 7.1 Rendimiento

| ID | Requisito | Objetivo |
|---|---|---|
| SRS-NFR-PERF-001 | Carga de página principal | Largest Contentful Paint p75 < 2 s en el perfil móvil de referencia (red 4G simulada de 10 Mbps, latencia 100 ms, CPU móvil de gama media) y p75 < 1,5 s en escritorio |
| SRS-NFR-PERF-002 | Generación de cotización automática | p95 < 3 s en servidor para una cotización de 15 ítems con hasta 3 candidatos por ítem, sobre el dataset de referencia |
| SRS-NFR-PERF-003 | Búsqueda y filtrado | p95 < 1 s en servidor para búsquedas con hasta 3 filtros combinados y página de 20 resultados, sobre el dataset de referencia |
| SRS-NFR-PERF-004 | Generación PDF | p95 < 5 s desde la solicitud hasta el documento disponible, para cotizaciones de hasta 30 ítems |
| SRS-NFR-PERF-005 | Concurrencia | 500 usuarios simultáneos con la mezcla de carga de referencia durante 30 minutos, con tasa de error < 1 % y los objetivos PERF-002..004 cumplidos |
| SRS-NFR-PERF-006 | Operaciones críticas | 0 sobreventas y 0 adjudicaciones dobles en la suite de concurrencia (SAD §16.5); p95 < 2 s para reserva y adjudicación (SLO de SAD §12.2). La integridad prevalece sobre la latencia |

**Dataset de referencia:** 2.000 proveedores publicados repartidos en las 21 categorías, 6.000 paquetes, 500 empresas, 5.000 eventos, 15 ítems por evento, 20.000 reseñas y 12 meses de capacidad diaria. **Mezcla de carga de referencia:** 60 % búsqueda y navegación de catálogo, 20 % edición de eventos y cotizaciones, 10 % e-RFQ y Bid Tabulation, 5 % generación de PDF, 5 % adjudicación o reserva.

Los objetivos se miden en un ambiente con la misma configuración de recursos que producción. El plan de pruebas (Plans/Plan0002.md, D4) detalla los perfiles de carga, la duración de cada prueba y el procedimiento de medición.

## 7.2 Seguridad

| ID | Requisito |
|---|---|
| SRS-NFR-SEC-001 | HTTPS/TLS 1.2 o superior para todo tráfico externo. |
| SRS-NFR-SEC-002 | Contraseñas gestionadas por Auth0; si se implementara autenticación propia, usar algoritmo moderno de hashing de contraseñas y parámetros vigentes, no cifrado reversible. |
| SRS-NFR-SEC-003 | Sesiones con expiración tras 24 horas de inactividad, respetando límites del proveedor de identidad. |
| SRS-NFR-SEC-004 | Protección contra SQL injection, XSS, CSRF, SSRF y controles de autorización rota. |
| SRS-NFR-SEC-005 | Validación de permisos y tenant en cada operación de backend. |
| SRS-NFR-SEC-006 | Magic Links aleatorios, firmados o basados en secreto de alta entropía, hash en reposo, propósito único, expiración, rate limiting y token transportado en el fragmento de la URL y en el cuerpo de la petición, nunca en la ruta (TEC-008). |
| SRS-NFR-SEC-007 | Secretos y API keys fuera del código fuente y del cliente. |
| SRS-NFR-SEC-008 | Auditoría de cambios financieros y transaccionales. |
| SRS-NFR-SEC-009 | Protección de datos personales conforme a Ley 1581/2012 y normativa aplicable. |
| SRS-NFR-SEC-010 | Archivos multimedia validados por tipo, tamaño y autorización; no confiar en extensión enviada por el cliente. |
| SRS-NFR-SEC-011 | No incluir tokens, credenciales ni datos sensibles en logs. |
| SRS-NFR-SEC-012 | Rate limiting para login, recuperación, Magic Links, importación JSON y endpoints sensibles. |

## 7.3 Privacidad y cumplimiento

| ID | Requisito |
|---|---|
| SRS-NFR-PRIV-001 | La plataforma DEBE publicar su política de tratamiento de datos y obtener la autorización del titular cuando corresponda (empresas, usuarios y proveedores). |
| SRS-NFR-PRIV-002 | Derechos del titular: el usuario DEBE poder solicitar desde la aplicación consulta, corrección o supresión de sus datos; cada solicitud se registra con estado, responsable, fecha de respuesta y resultado. Los plazos provisionales están en SRS-ADM-012 (DEC-037) y se validan con asesoría legal (Ley 1581 de 2012). La supresión respeta la retención obligatoria y el `legal_hold` (DEC-003). |
| SRS-NFR-PRIV-003 | Minimización: se recolectan únicamente los datos necesarios para el propósito declarado. |
| SRS-NFR-PRIV-004 | Se definen responsables y encargados, y contratos con los proveedores de servicios que procesen datos. |
| SRS-NFR-PRIV-005 | La información de contacto del proveedor no se expone antes del momento definido en SRS-CAT-015. |
| SRS-NFR-PRIV-006 | La aplicación DEBE registrar consentimiento, versión del aviso y fecha/hora para empresas y proveedores. |
| SRS-NFR-PRIV-007 | Transferencia internacional: se mantiene un inventario de subprocesadores (Auth0, SendGrid, Cloudinary, Google Maps, Sentry, hosting), los datos que recibe cada uno, su finalidad y su ubicación; la transferencia internacional se analiza con asesoría legal antes de operar con datos reales (DEC-014). |
| SRS-NFR-PRIV-008 | Asistente WhatsApp: antes de generar el prompt, el sistema DEBE sustituir teléfonos y emails del texto pegado por marcadores, y advertir al usuario que no pegue datos personales innecesarios en herramientas externas. El texto original se conserva solo según DEC-003 (90 días tras cerrar el caso). |

## 7.4 Disponibilidad y recuperación

| ID | Requisito | Objetivo |
|---|---|---|
| SRS-NFR-AVL-001 | Disponibilidad mensual | 99.5% |
| SRS-NFR-AVL-002 | Backups | Automáticos diarios como mínimo |
| SRS-NFR-AVL-003 | RTO | Máximo 4 horas |
| SRS-NFR-AVL-004 | Restauración | Procedimiento probado periódicamente |
| SRS-NFR-AVL-005 | Colas | Mensajes y tareas críticas persistentes, recuperables tras reinicio |

Objetivos de recuperación aprobados (DEC-012): **RPO ≤ 1 hora** mediante backups continuos/WAL o mecanismo equivalente y **RTO ≤ 4 horas**, sujetos a simulacros; backups diarios como base más recuperación a un punto en el tiempo si el proveedor lo soporta; prueba de restauración al menos trimestral durante el MVP. Si el costo de RPO ≤ 1 h no fuera viable en el piloto, solo podrá aceptarse temporalmente un RPO de 24 horas como riesgo explícito, a revisar antes de operar un volumen relevante de reservas. El outbox en PostgreSQL permite reconstruir tareas; Redis no debe ser el único lugar de una operación pendiente.

Hosting y residencia (DEC-013, DEC-014): Vercel + Railway es candidato de MVP, validado mediante una prueba de aceptación técnica con criterios ponderados (seguridad/backups 25 %, disponibilidad/soporte 20 %, latencia/región 20 %, costo 20 %, operación 15 %). Se prefiere una región en Colombia o cercana si cumple los requisitos, se mantiene un inventario de subprocesadores y de datos enviados a cada uno, y se evita enviar contenido completo de cotizaciones a servicios externos cuando basta un identificador.

## 7.5 Escalabilidad y mantenibilidad

| ID | Requisito | Criterio de verificación |
|---|---|---|
| SRS-NFR-SCAL-001 | La API y el worker escalan horizontalmente sin estado compartido en memoria | La suite E2E pasa con dos réplicas de API y dos de worker detrás del balanceador; ninguna sesión ni bloqueo vive en memoria del proceso |
| SRS-NFR-SCAL-002 | Las operaciones de negocio críticas se ejecutan en backend | Las pruebas negativas que invocan la API directamente (sin frontend) no pueden saltarse ninguna regla de capacidad, adjudicación, permisos ni estado |
| SRS-NFR-SCAL-003 | Las integraciones externas están detrás de adaptadores | Cada integración (Auth0, SendGrid, Cloudinary, Maps, PDF) tiene un puerto y un doble de prueba; la suite de integración corre sin red externa |
| SRS-NFR-SCAL-004 | Las migraciones son versionadas y reproducibles | CI crea la base desde cero aplicando todas las migraciones y ejecuta la suite; ninguna migración se edita una vez aplicada en un ambiente compartido |
| SRS-NFR-SCAL-005 | Los contratos API y los eventos internos están documentados | `Tools/check_openapi.py` pasa en CI y cada evento publicado tiene esquema versionado (DDD §8.2) |
| SRS-NFR-SCAL-006 | La taxonomía y las plantillas se administran sin despliegue | Crear o editar una categoría, un subtipo o una plantilla desde el panel admin se refleja en el catálogo sin desplegar código |

## 7.6 Usabilidad y accesibilidad

| ID | Requisito |
|---|---|
| SRS-NFR-USA-001 | Interfaz responsive desde 360 px. |
| SRS-NFR-USA-002 | Español de Colombia. |
| SRS-NFR-USA-003 | COP con separador de miles por puntos y sin centavos en presentación (SRS-QUO-013). |
| SRS-NFR-USA-004 | Formulario Magic Link mobile-first. |
| SRS-NFR-USA-005 | Flujo de cotización de plantilla a PDF/envío con máximo siete clics en el escenario principal. |
| SRS-NFR-USA-006 | Cada mensaje de validación se muestra junto al campo, indica qué está mal y cómo corregirlo, se asocia al campo para lectores de pantalla (`aria-describedby`) y no borra lo que el usuario ya escribió. |
| SRS-NFR-USA-007 | Estados de carga, vacío, error, éxito y expiración explícitos (sección 10.4). |
| SRS-NFR-USA-008 | Accesibilidad objetivo WCAG 2.1 nivel AA: controles operables por teclado, contraste suficiente y etiquetas accesibles. |

## 7.7 Compatibilidad

| ID | Requisito |
|---|---|
| SRS-NFR-COMP-001 | Navegadores objetivo según PRD: Chrome 90+, Firefox 90+, Safari 14+ y Edge 90+. |
| SRS-NFR-COMP-002 | El equipo deberá validar versiones vigentes y ajustar la matriz de soporte antes del lanzamiento si los navegadores mínimos han quedado obsoletos. |
| SRS-NFR-COMP-003 | Funcional en dispositivos con resolución mínima de 360 px de ancho (PRD RNF-22). |

## 7.8 Observabilidad

| ID | Requisito |
|---|---|
| SRS-NFR-OBS-001 | Logs estructurados con correlation ID. |
| SRS-NFR-OBS-002 | Métricas de latencia (p50/p95/p99 por ruta), errores, profundidad y edad de colas, envíos de email, expiraciones SLA y conflictos de reserva y adjudicación, con resolución de 1 minuto y retención de al menos 30 días, que permiten calcular los SLO de SAD §12.2. |
| SRS-NFR-OBS-003 | Trazas de operaciones críticas. |
| SRS-NFR-OBS-004 | Alertas con umbrales iniciales: tasa de 5xx > 2 % durante 5 minutos; edad del mensaje más antiguo de una cola crítica > 5 minutos; retraso de expiración SLA p99 > 2 minutos; eventos de outbox `PENDIENTE` con más de 10 minutos; 3 fallos consecutivos de una integración o de un backup; consumo rápido del presupuesto de error de un SLO (SAD §12.2 y §12.5). |
| SRS-NFR-OBS-005 | Sentry para errores de aplicación. |
| SRS-NFR-OBS-006 | Prohibido registrar secretos o tokens completos. |

---

# 8. Flujos operativos y escenarios de aceptación

## 8.1 Registro y aprobación de proveedor

1. El proveedor registra su cuenta.
2. Verifica email.
3. Completa perfil, categorías, subtipos, portafolio, paquetes y canal.
4. Envía perfil a revisión.
5. Admin aprueba o rechaza con motivo.
6. Solo tras aprobación y perfil publicable aparece en catálogo.

**Aceptación:** un proveedor pendiente nunca aparece en resultados, aunque haya verificado su correo.

## 8.2 Cotización integral

1. Coordinador crea evento o clona uno.
2. Selecciona plantilla.
3. Define fecha, asistentes, ubicación y presupuesto opcional.
4. El sistema calcula TOP 3 por categoría/subtipo.
5. El coordinador selecciona o intercambia opciones.
6. El sistema recalcula totales.
7. El coordinador guarda borrador o genera PDF.
8. Para paquetes Instant Book puede reservar; para e-RFQ selecciona proveedores y envía solicitudes.

**Aceptación:** si una categoría no tiene proveedores, se muestra como pendiente/sin oferta y no impide cotizar las demás categorías.

## 8.3 Reserva Instant Book concurrente

1. Dos coordinadores intentan reservar el último cupo disponible.
2. El backend valida ambas solicitudes.
3. Solo una transacción obtiene el cupo.
4. La segunda recibe conflicto y opciones alternativas.

**Aceptación:** nunca se confirman dos reservas que excedan el límite diario.

## 8.4 e-RFQ por email

1. Coordinador selecciona de uno a cinco proveedores y SLA.
2. El sistema crea solicitudes individuales.
3. Envía Magic Links.
4. Proveedor abre enlace y responde disponibilidad, precio, extras y condiciones.
5. El token se consume una sola vez.
6. Bid Tabulation se actualiza.
7. Coordinador adjudica.
8. Los demás reciben no adjudicación.

**Aceptación:** una solicitud fallida de email no cancela las demás; un enlace expirado o usado no permite una segunda respuesta; si el proveedor ganador ya no tiene capacidad en la fecha, la adjudicación se rechaza y el coordinador puede elegir otra oferta vigente.

## 8.5 Respuesta por WhatsApp en MVP

1. Coordinador abre la plantilla y revisa variables.
2. El sistema abre `wa.me` con mensaje prellenado.
3. El coordinador envía el mensaje desde WhatsApp.
4. El proveedor responde por WhatsApp.
5. El coordinador copia la respuesta al asistente.
6. El sistema produce prompt y permite importar JSON.
7. El coordinador revisa y confirma la oferta estructurada.

**Aceptación:** la interfaz no muestra estado “enviado/entregado” solo por abrir WhatsApp; la oferta importada requiere confirmación humana.

## 8.6 Calificación post-evento

1. El ítem llega a `COMPLETADO`.
2. El sistema habilita calificación.
3. Coordinador califica las cuatro dimensiones y reseña opcional.
4. El proveedor puede responder.
5. El promedio se recalcula.

**Aceptación:** un usuario de otra empresa o un proveedor no contratado no puede crear la calificación.

## 8.7 Respuesta tardía al SLA

1. Una solicitud e-RFQ tiene `sla_expira_at` a las 18:00 (hora del servidor, UTC).
2. El proveedor abre el formulario a las 17:55 y envía su respuesta a las 18:01.
3. El backend compara la hora de recepción del servidor con `sla_expira_at` (SRS-DEC-006).

**Aceptación:** la respuesta se rechaza con `SLA_EXPIRED`, no se crea oferta y la solicitud queda `EXPIRADO` (o lo queda al correr el job). Si el job de expiración corre tarde, una respuesta recibida antes de `sla_expira_at` sí se acepta, y un job que se ejecuta sobre una solicitud ya `RESPONDIDO` con oferta vigente no la modifica; nunca la marca `EXPIRADO` (el cierre sin oferta vigente es el de SRS-RFQ-012; DEC-035).

## 8.8 Cancelación sin respuesta en 72 horas

1. La organizadora solicita cancelar una contratación `CONFIRMADO` con motivo.
2. La contratación pasa a `CANCELACION_SOLICITADA` y se notifica al proveedor.
3. El proveedor no responde en 72 horas.

**Aceptación:** el job de `scheduler` pasa la contratación a `CANCELACION_EN_REVISION`, aparece en la bandeja de disputas (SRS-ADM-010) y la capacidad sigue consumida.

## 8.9 Cancelación disputada

1. El proveedor solicita cancelar; la organizadora rechaza la cancelación con motivo.
2. La contratación pasa a `CANCELACION_EN_REVISION`.
3. `ADMIN_PLATAFORMA` resuelve.

**Aceptación:** si resuelve `CANCELADO`, la capacidad se libera (`ReleaseBookingCapacity`), la comisión queda `NO_APLICA` y el ítem pasa a `CANCELADO`; si resuelve `CONFIRMADO`, nada cambia en capacidad ni comisión. Ambas partes reciben aviso y la resolución queda auditada. No se calculan penalidades.

## 8.10 Límite del plan alcanzado a mitad del flujo

1. Una empresa en plan `BASICO` tiene una e-RFQ mensual disponible.
2. Un coordinador envía una ronda e-RFQ a tres proveedores (consume la cuota).
3. Otro coordinador intenta crear una nueva ronda para otro ítem.
4. Un proveedor de la primera ronda responde y la organizadora adjudica.

**Aceptación:** el paso 3 se rechaza con `PLAN_LIMIT_REACHED` indicando el límite; las respuestas, la Bid Tabulation, la adjudicación y la contratación de la primera ronda funcionan con normalidad (RN-25).

## 8.11 Servicio de varios días y cruce de medianoche

1. Un evento en `America/Bogota` va del viernes 18:00 al domingo 14:00; otro, del viernes 20:00 al sábado 03:00.
2. Se adjudica a un proveedor con capacidad global 2 por fecha, que ya tiene una contratación el sábado.

**Aceptación:** el primer evento consume capacidad el viernes, el sábado y el domingo; el segundo, solo el viernes (DEC-025). Si alguna de las fechas no tiene capacidad, la adjudicación completa se rechaza con `CAPACITY_EXHAUSTED` y no se consume ninguna fecha.

## 8.12 Suspensión de proveedor con contrataciones futuras

1. Un proveedor tiene una contratación `CONFIRMADO` para dentro de 20 días, una `EN_PROGRESO` hoy y una solicitud e-RFQ `ENVIADO`.
2. `ADMIN_PLATAFORMA` lo suspende con motivo.

**Aceptación:** el proveedor desaparece del catálogo; la solicitud pasa a `CANCELADO` y su Magic Link deja de funcionar; la contratación futura pasa a `CANCELACION_EN_REVISION` con origen `PLATAFORMA` y aviso a la organizadora; la contratación `EN_PROGRESO` sigue su ciclo; la capacidad de la futura solo se libera si termina en `CANCELADO` (SRS-ADM-013).

3. La organizadora responde dentro de la ventana de decisión.

**Aceptación:** si elige cancelar, la contratación pasa a `CANCELADO`, la capacidad se libera y la comisión queda `NO_APLICA`. Si elige mantener, la contratación sigue en revisión y solo vuelve a `CONFIRMADO` cuando la administración lo resuelve.

**Aceptación (DEC-036):** una resolución administrativa anterior a la elección y con la ventana abierta se rechaza. El proveedor suspendido puede marcar realizado el servicio en curso y no puede crear ofertas.

---

# 9. Modelo de estados

## 9.1 Estado del proveedor

Dos dimensiones independientes (DEC-031).

**Verificación:**

`PENDIENTE → VERIFICADO | RECHAZADO`

`RECHAZADO → PENDIENTE` mediante corrección y reenvío.

**Cuenta:**

`ACTIVO → SUSPENDIDO` por acción administrativa, con motivo.

`SUSPENDIDO → ACTIVO` solo por reactivación administrativa; la verificación previa se conserva.

Visible en catálogo = `VERIFICADO` ∧ `ACTIVO` ∧ perfil publicable.

## 9.2 Estado de solicitud e-RFQ

`PENDIENTE_ENVIO → ENVIADO | ERROR_ENVIO`

`ENVIADO → RESPONDIDO | RECHAZADO | EXPIRADO`

`RESPONDIDO → ADJUDICADO | NO_ADJUDICADO`

`ENVIADO → NO_ADJUDICADO` si otra oferta gana antes de su respuesta.

`RESPONDIDO → NO_ADJUDICADO` cuando no le queda ninguna oferta `RECIBIDA` y `sla_expira_at` ya venció, de modo que no admite revisiones (SRS-RFQ-012; DEC-035).

`PENDIENTE_ENVIO | ENVIADO | RESPONDIDO | ERROR_ENVIO → CANCELADO` por revocación (SRS-RFQ-013; DEC-026).

`ERROR_ENVIO → PENDIENTE_ENVIO` por reintento, hasta 3 veces (SRS-RFQ-013).

Una solicitud `RESPONDIDO` no pasa a `EXPIRADO` por SLA: la vigencia relevante es la de la oferta (SRS-RFQ-012).

Una solicitud está **abierta** en `PENDIENTE_ENVIO`, `ENVIADO`, `RESPONDIDO` y `ERROR_ENVIO` (este último admite reintento).

Los estados terminales (`RECHAZADO`, `EXPIRADO`, `ADJUDICADO`, `NO_ADJUDICADO`, `CANCELADO`) no se reabren. Para solicitar una nueva oferta se crea una nueva ronda (DEC-026).

## 9.3 Estado de ítem

Estado de seguimiento de cada ítem de cotización (SRS-TRK-001..003). Los estados visibles son `COTIZADO`, `ENVIADO`, `CONFIRMADO`, `RECHAZADO`, `EN_PROGRESO`, `COMPLETADO` y `CALIFICADO`; los internos, `EXPIRADO`, `NO_ADJUDICADO` y `CANCELADO`, que la interfaz muestra con su propia etiqueta y nunca como `RECHAZADO`. El estado del ítem se deriva de los hechos de la ronda e-RFQ, de la contratación y de las reseñas; nadie lo edita a mano.

Camino principal:

`COTIZADO → ENVIADO → CONFIRMADO → EN_PROGRESO → COMPLETADO → CALIFICADO`

| Desde | Hacia | Disparador |
|---|---|---|
| `COTIZADO` | `ENVIADO` | Se envía la primera solicitud de una ronda e-RFQ del ítem |
| `COTIZADO` | `CONFIRMADO` | Reserva Instant Book confirmada (E2) |
| `ENVIADO` | `CONFIRMADO` | Adjudicación de una oferta del ítem (SRS-RFQ-009) |
| `ENVIADO` | `NO_ADJUDICADO` | La ronda termina sin adjudicación y en ella se recibió alguna oferta (`VENCIDA`, `INVALIDADA` o de una solicitud revocada) |
| `ENVIADO` | `EXPIRADO` | La ronda termina sin ofertas y al menos una solicitud en `EXPIRADO` |
| `ENVIADO` | `RECHAZADO` | La ronda termina sin ofertas ni solicitudes `EXPIRADO`, y al menos una en `RECHAZADO` (las demás, `CANCELADO`; la combinación con revocadas, DEC-035) |
| `ENVIADO` | `COTIZADO` | Todas las solicitudes de la ronda terminan en `CANCELADO` sin ofertas, con el evento vigente (DEC-035) |
| `RECHAZADO`, `EXPIRADO`, `NO_ADJUDICADO` | `ENVIADO` | El organizador lanza una nueva ronda (DEC-026) |
| `RECHAZADO`, `EXPIRADO`, `NO_ADJUDICADO` | `CONFIRMADO` | El organizador reserva por Instant Book otro paquete para el ítem (E2) |
| `COTIZADO`, `ENVIADO`, `RECHAZADO`, `EXPIRADO`, `NO_ADJUDICADO` | `CANCELADO` | El evento se cancela y el ítem no tiene contratación (SRS-EVT-009) |
| `CONFIRMADO` | `EN_PROGRESO` | La contratación pasa a `EN_PROGRESO`, `SERVICIO_REALIZADO` o `INCIDENCIA` (§9.5) |
| `CONFIRMADO`, `EN_PROGRESO` | `CANCELADO` | La contratación termina en `CANCELADO` o `NO_PRESTADO` (§9.5) |
| `CANCELADO` | `ENVIADO` o `CONFIRMADO` | Con el evento vigente, el organizador vuelve a cotizar el ítem (nueva ronda) o reserva otro paquete |
| `EN_PROGRESO` | `COMPLETADO` | La contratación llega a `COMPLETADO` |
| `COMPLETADO` | `CALIFICADO` | La organizadora publica la reseña (SRS-REV-001) |

Reglas:
- El ítem pasa a `ENVIADO` cuando se envía la primera solicitud de la ronda, y sigue en `ENVIADO` mientras tenga solicitudes abiertas (§9.2).
- Cuando una ronda termina sin adjudicación, el destino es el primero que aplique en este orden: `CANCELADO` (evento cancelado), `NO_ADJUDICADO`, `EXPIRADO`, `RECHAZADO`, `COTIZADO` (DEC-035).
- `CALIFICADO` es terminal. `COMPLETADO` también lo es si la ventana de reseña (30 días, DEC-030) se cierra sin reseña.
- Si el evento se cancela (SRS-EVT-009), los ítems sin contratación pasan a `CANCELADO` y los ítems con contratación siguen el ciclo de esta.
- No se permite pasar de `COTIZADO` a `CALIFICADO` ni a `COMPLETADO` sin contratación (SRS-TRK-003).

## 9.4 Estado de evento

`BORRADOR → COTIZADO → ENVIADO → EN_PROGRESO → COMPLETADO`

`COTIZADO → EN_PROGRESO` cuando el evento solo tiene contrataciones Instant Book (sin solicitudes e-RFQ) y llega su fecha de inicio.

- `COTIZADO` significa que el evento tiene al menos una cotización generada (`GENERADA`, sección 9.6).
- `ENVIADO` significa que existe al menos una solicitud e-RFQ enviada para el evento.
- `EN_PROGRESO` se alcanza al llegar la fecha/hora local de inicio con al menos una contratación activa.
- `COMPLETADO` cuando todas sus contrataciones están en estado terminal y al menos una en `COMPLETADO`.
- `BORRADOR`, `COTIZADO` y `ENVIADO` pueden pasar a `CANCELADO` según SRS-EVT-009.
- El archivado de borradores es una marca (`archivedAt`), no un estado (SRS-EVT-007).


## 9.5 Estado de contratación

Máquina de estados definida en SRS-BOOK-009 (DEC-023):

`CONFIRMADO → CANCELACION_SOLICITADA → CANCELADO | CANCELACION_EN_REVISION | CONFIRMADO`

`CONFIRMADO → CANCELACION_EN_REVISION` (suspensión del proveedor, origen `PLATAFORMA`, SRS-ADM-013)

`CANCELACION_EN_REVISION → CANCELADO | CONFIRMADO` (administración; con origen `PLATAFORMA`, la organizadora puede llevarla a `CANCELADO`)

`CONFIRMADO → EN_PROGRESO → SERVICIO_REALIZADO → COMPLETADO | INCIDENCIA`

`CONFIRMADO → SERVICIO_REALIZADO` (el proveedor marca antes de que corra el job)

`INCIDENCIA → COMPLETADO | NO_PRESTADO` (administración)

Correspondencia con el estado de seguimiento del ítem (SRS-TRK-002):

| Estado de la contratación | Estado del ítem |
|---|---|
| `CONFIRMADO`, `CANCELACION_SOLICITADA`, `CANCELACION_EN_REVISION` | `CONFIRMADO` |
| `EN_PROGRESO`, `SERVICIO_REALIZADO`, `INCIDENCIA` | `EN_PROGRESO` |
| `COMPLETADO` | `COMPLETADO` (y `CALIFICADO` cuando existe reseña) |
| `CANCELADO`, `NO_PRESTADO` | `CANCELADO` (interno) |

## 9.6 Estado de cotización

Estados de la cotización integral (`QuotationStatus`):

| Estado | Significado |
|---|---|
| `BORRADOR` | En edición: se agregan o quitan ítems y se cambian selecciones |
| `GENERADA` | Se generó un snapshot versionado y su PDF (SRS-QUO-011, SRS-QUO-012) |
| `ENVIADA` | Al menos un ítem tiene una solicitud e-RFQ enviada o una contratación |
| `CERRADA` | El evento terminó (`COMPLETADO`) o se canceló; solo lectura |

Transiciones:
- `BORRADOR → GENERADA` al generar el snapshot/PDF.
- `GENERADA → BORRADOR` al editar la cotización; la siguiente generación crea una versión nueva y las anteriores se conservan.
- `BORRADOR | GENERADA → ENVIADA` al enviar la primera solicitud e-RFQ o confirmar la primera contratación de un ítem.
- En `ENVIADA` se pueden añadir ítems nuevos (en `COTIZADO`) y generar nuevas versiones del PDF; no se eliminan ítems con solicitudes o contrataciones.
- `BORRADOR | GENERADA | ENVIADA → CERRADA` cuando el evento pasa a `COMPLETADO` o `CANCELADO`. `CERRADA` es terminal.

## 9.7 Estado de oferta

Estados de una oferta recibida en una solicitud e-RFQ (`RfqOffer.status`); cada revisión es una oferta inmutable (DEC-005):

| Estado | Significado |
|---|---|
| `RECIBIDA` | Revisión vigente y adjudicable |
| `REEMPLAZADA` | El proveedor envió una revisión posterior (SRS-RFQ-007) |
| `ADJUDICADA` | El organizador la adjudicó (SRS-RFQ-009) |
| `NO_ADJUDICADA` | Otra oferta ganó el ítem o la ronda se cerró sin adjudicarla |
| `INVALIDADA` | El evento cambió o la solicitud se revocó (SRS-EVT-008, SRS-RFQ-013) |
| `VENCIDA` | Terminó su vigencia sin adjudicarse (SRS-RFQ-012) |

Transiciones: `RECIBIDA → REEMPLAZADA | ADJUDICADA | NO_ADJUDICADA | INVALIDADA | VENCIDA`. Solo una oferta `RECIBIDA` es adjudicable; todos los demás estados son terminales. En una adjudicación o al cerrarse la ronda, la solicitud e-RFQ pasa a `ADJUDICADO` o `NO_ADJUDICADO` en la misma transacción que su oferta (§9.2). Cuando una oferta vence, la solicitud sigue `RESPONDIDO` mientras el SLA admita una revisión; vencido el SLA sin ninguna oferta `RECIBIDA`, pasa a `NO_ADJUDICADO` (DEC-035).

---

# 10. Requisitos de interfaz de usuario

## 10.1 Navegación organizador

- Dashboard.
- Mis eventos.
- Cotización rápida.
- Nuevo evento con plantilla.
- Catálogo de proveedores.
- Mis plantillas.
- Perfil/configuración.
- Notificaciones.

## 10.2 Navegación proveedor

- Dashboard.
- Perfil y portafolio.
- Paquetes.
- Disponibilidad.
- Solicitudes e-RFQ.
- Reservas/próximos eventos.
- Calificaciones y respuestas.
- Preferencias de canal.

## 10.3 Navegación administrador

- Dashboard.
- Usuarios y empresas.
- Proveedores pendientes.
- Categorías y subtipos.
- Plantillas de eventos.
- Plantillas WhatsApp.
- Reseñas reportadas.
- Auditoría.

## 10.4 Estados visuales obligatorios

Toda pantalla con datos remotos deberá contemplar:
- carga;
- error recuperable;
- ausencia de resultados;
- ausencia de permisos;
- recurso no encontrado;
- recurso archivado;
- expiración;
- operación en curso;
- confirmación exitosa.

---

# 11. Criterios globales de aceptación del MVP

El MVP será aceptable cuando:

1. Empresas y proveedores puedan registrarse y autenticarse.
2. Los roles y el aislamiento multiempresa funcionen en backend.
3. Un proveedor pueda completar perfil y ser aprobado.
4. El catálogo soporte las 21 categorías y sus subtipos administrables.
5. La búsqueda combine filtros requeridos.
6. Las empresas puedan crear eventos, usar plantillas y clonar eventos.
7. El motor genere cotización rápida e integral con resultados reales.
8. Instant Book bloquee capacidad transaccionalmente y sin sobreventa.
9. e-RFQ envíe de uno a cinco proveedores en paralelo con SLA.
10. El Magic Link permita una respuesta estructurada de un solo uso.
11. El Bid Tabulation consolide respuestas y permita adjudicar un solo ganador.
12. WhatsApp MVP genere mensajes prellenados y no simule automatización inexistente.
13. El asistente IA importe JSON validado con revisión humana.
14. Los usuarios puedan seguir el estado de eventos e ítems.
15. Se generen PDF y notificaciones.
16. Las empresas puedan calificar únicamente proveedores contratados y con servicio completado.
17. El administrador pueda gestionar proveedores, taxonomía, plantillas y moderación.
18. Se cumplan los NFR críticos de seguridad, rendimiento, disponibilidad y privacidad.
19. Existan pruebas automatizadas para permisos, aislamiento, concurrencia de reserva, expiración de Magic Link y adjudicación.
20. Se haya ejecutado un procedimiento de backup y restauración satisfactorio.

---

# 12. Matriz de trazabilidad PRD → SRS

Los rangos de la columna PRD citan solo identificadores definidos en el PRD v2.4 (`Tools/check_package.py`, chequeo 2). La entrega de cada requisito SRS está en su línea `**Entrega:**` y en `Trazabilidad.md`; esta columna resume la del grupo.

| PRD | Requisitos SRS relacionados | Entrega |
|---|---|---|
| RF-AUTH-01..06, RF-MEM-01..04 | SRS-AUTH-001..012, SRS-TEN-005 | E1 (transferencia de propiedad: E2) |
| RF-CAT-01..08 | SRS-CAT-001..015, SRS-TEN-001..004 | E1 (verificación nivel 3: E2) |
| RF-COT-01..03, RF-COT-05..06 | SRS-QUO-001..014 | E1 |
| RF-PLT-01..05 | SRS-EVT-002..005, SRS-EVT-011 | E1 |
| RF-INT-01..03, RF-INT-05..08 | SRS-EVT-001, SRS-EVT-007..010, SRS-QUO-006..013 | E1 |
| RF-SEG-01..06 | SRS-EVT-006, SRS-RFQ-001..013, SRS-MAGIC-001..006, SRS-WA-001..009, SRS-TRK-001..004 | E1 (WhatsApp: E2) |
| RF-BOOK-01..05 | SRS-BOOK-001..006, SRS-CAT-007, SRS-CAT-009 | E1 (capacidad global y regla transaccional) / E2 (Instant Book) |
| RF-RFQ-01..07 | SRS-RFQ-001..007, SRS-RFQ-010, SRS-RFQ-013, SRS-MAGIC-001..006 | E1 |
| RF-BID-01..04 | SRS-RFQ-008, SRS-RFQ-009, SRS-RFQ-011, SRS-RFQ-012 | E1 |
| RF-WA-01..05 | SRS-WA-001..009 | E2 |
| RF-CIE-01..04 | SRS-BOOK-007..010, SRS-ADM-010 | E1 |
| RF-CAL-01..05 | SRS-REV-001..008 | E1 |
| RF-ADM-01..06 | SRS-ADM-001..013 | E1 (verificación nivel 3 y plantillas WhatsApp: E2) |
| RF-NOT-01..03 | SRS-NOT-001..006 | E1 |
| RNF-01..05 | SRS-NFR-PERF-001..006 | E1 |
| RNF-06..10 | SRS-NFR-SEC-001..008, SRS-NFR-SEC-010..012 | E1 |
| RNF-11 (mapeo doble: seguridad y privacidad) | SRS-NFR-SEC-009 y SRS-NFR-PRIV-001..008 | E1 |
| RNF-12..16 | SRS-NFR-USA-001..008 | E1 |
| RNF-17, RNF-18, RNF-20 | SRS-NFR-AVL-001..005 | E1 |
| RNF-19 | SRS-NFR-SCAL-001..006 | E1 |
| RNF-21..22 | SRS-NFR-COMP-001..003 | E1 |
| — (observabilidad, sin RNF en el PRD) | SRS-NFR-OBS-001..006 | E1 |
| RF-COT-04, RF-INT-04 | — (Fase 3, fuera del MVP: comparación lado a lado y versiones Económica/Estándar/Premium) | Fase 3 |

`SRS-NFR-SEC-009` también deriva de RNF-11: la fila de RNF-11 declara el mapeo doble y la fila de RNF-06..10 lo excluye para no contarlo dos veces.

---

# 13. Conflictos, decisiones y aclaraciones aplicadas

Esta sección hace explícitas las ambigüedades del PRD y las resoluciones adoptadas para que desarrollo y QA no tengan que inventar comportamiento.

| ID | Ambigüedad/conflicto detectado | Resolución aplicada en este SRS | Impacto |
|---|---|---|---|
| SRS-DEC-001 | `AMBOS` no define cómo enrutar. | En MVP se envía Email Magic Link y se ofrece Click-to-Chat adicional; no se afirma envío automático de WhatsApp. | SRS-CAT-008 |
| SRS-DEC-002 | El PRD habla de WhatsApp con respuestas libres, pero MVP solo dispone de `wa.me`. | `wa.me` abre el cliente; no hay webhook ni recepción automática. Respuesta se copia/pega y procesa asistidamente. | SRS-WA-003..008 |
| SRS-DEC-003 | “Planes gratuitos vía sesión/login” de IA no especifica integración autorizada ni técnica estable. | No automatizar sesiones, scraping ni uso de interfaces web de terceros. MVP genera prompt y permite importación manual de JSON. | SRS-WA-005..009 |
| SRS-DEC-004 | El ERD modela `DISPONIBILIDAD` como booleano por fecha, pero la regla permite dos eventos diarios. | Tratar disponibilidad como capacidad/cupos por fecha; un bloqueo booleano representa capacidad cero. | SRS-BOOK y sección 4.4 |
| SRS-DEC-005 | La búsqueda consulta disponibilidad antes de reservar. | La consulta es indicativa; la reserva revalida y consume cupo en una transacción atómica. | SRS-BOOK-002 |
| SRS-DEC-006 | No se define qué sucede con respuestas que llegan exactamente al vencimiento. | La hora de recepción del servidor decide; se acepta solo si es menor o igual al SLA. | SRS-RFQ-005 |
| SRS-DEC-007 | Adjudicación no describe concurrencia ni doble selección. | Adjudicación atómica con una sola oferta ganadora por ítem. | SRS-RFQ-009 |
| SRS-DEC-008 | Los estados del ítem no incluyen expiración/no adjudicación/cancelación. | Se mantienen estados de negocio visibles y se agregan estados internos explícitos (`EXPIRADO`, `NO_ADJUDICADO`, `CANCELADO`), con el grafo completo en la sección 9.3. | SRS-TRK y sección 9.3 |
| SRS-DEC-009 | El modelo de datos no separa claramente solicitud de oferta recibida. | Se recomienda entidad/versiones `OfertaRFQ` asociada a `SolicitudRFQ`; preserva solicitud original y revisiones. | Sección 4.1 |
| SRS-DEC-010 | Instant Book no define pagos, cancelación ni reembolsos. | MVP registra compromiso/reserva; no procesa pagos ni calcula penalidades. Cancelación requiere motivo y auditoría. | SRS-BOOK-004..007 |
| SRS-DEC-011 | Comisión del 3% y suscripciones se describen, pero pasarela de pago queda en Fase 3. | Registrar contratación y comisión devengada como dato de negocio; no simular cobro o recaudo. | SRS-QUO-008 |
| SRS-DEC-012 | Auth0 administra credenciales, pero el modelo incluye contraseña. | Auth0 será fuente de credenciales; no almacenar contraseña local. `auth0_id` vincula identidad externa. | SRS-AUTH-003 |
| SRS-DEC-013 | El ERD enumera `ADMIN_EMPRESA`, pero el texto alterna “Admin Empresa” y “Dueño”. | Unificar rol como `ADMIN_EMPRESA`; coordinadores son miembros subordinados de la misma empresa. Actualizado por DEC-008 y DEC-022: el dueño es `PROPIETARIO`. | SRS-AUTH-005, SRS-AUTH-009 |
| SRS-DEC-014 | Los límites por plan se describen, pero no el mecanismo de facturación. | MVP registra plan y aplica cuotas configuradas; cobro recurrente automatizado queda fuera. | SRS-TEN-003 |
| SRS-DEC-015 | “Eliminar borradores” puede entrar en conflicto con auditoría y retención. | Archivar/borrado lógico tras 90 días y purgar conforme a la política de retención aprobada (DEC-003, SRS §4.6). | SRS-EVT-007 |
| SRS-DEC-016 | Ranking calidad-precio incorpora promedio bayesiano/proximidad sin fórmula completa. | Fórmula explicable y versionada con pesos iniciales 40/30/20/10 y fallback determinista (ver DEC-004 de `Decisiones.md`). | SRS-QUO-004 |
| SRS-DEC-017 | La calificación promedio del perfil y el promedio de dimensiones pueden interpretarse de varias formas. | Cada reseña promedia cuatro dimensiones; el perfil agrega reseñas válidas. | SRS-REV-002..003 |
| SRS-DEC-018 | La tarifa con IVA incluido depende de condiciones fiscales del proveedor. | Configuración fiscal explícita por proveedor/servicio; no se infiere tratamiento tributario (ver DEC-010 de `Decisiones.md`). | RN-10 |

## 13.1 Decisiones de producto y técnicas aprobadas

**Alcance:** las filas de esta sección resumen DEC-001..018 y TEC-001..005, aprobadas el 23-11-2026. DEC-019..034, TEC-006..012 y ADR-016..022 se aprobaron el 23-11-2026; su detalle está en `Decisiones.md` §4b y se citan en cada sección afectada.

Las decisiones antes pendientes quedaron aprobadas en `Decisiones.md`, donde se documentan situación, alternativas, ventajas, costos y riesgos. Esta tabla resume la resolución adoptada y su justificación; los plazos legales, fiscales y contables siguen requiriendo validación profesional en Colombia. Los identificadores `SRS-DEC-xxx` de la tabla anterior son locales del SRS; las referencias `DEC-001..018` y `TEC-001..005` remiten a `Decisiones.md`.

| ID | Resolución adoptada | Justificación | Requisitos afectados |
|---|---|---|---|
| DEC-001 | Cancelación por etapas con motivo obligatorio, aceptación bilateral y estado `CANCELACION_EN_REVISION` (valor según DEC-022); sin penalidades ni reembolsos automáticos | Sin pagos ni marco contractual validado, automatizar penalizaciones sería difícil de ejecutar y conflictivo; libera capacidad solo con decisión clara y genera evidencia | SRS-BOOK-007 |
| DEC-002 | Comisión devengada al completar el servicio y confirmar el organizador (5 días, cierre automático sin incidencia, `RETENIDA` en disputa según DEC-022) | Liga la comisión a un servicio cumplido, no a una oferta; separa GMV, bookings completados y comisión | SRS-BOOK-008, SRS-QUO-008, RN-09 |
| DEC-003 | Retención por categoría de dato, borrado lógico, jobs auditados y `legal_hold` | Evita borrar evidencia contractual y reduce acumulación de datos personales | SRS-EVT-007, sección 7.3 |
| DEC-004 | Ranking 40/30/20/10 explicable, versionado y configurable | Reduce sesgo por pocas reseñas, no equipara precio bajo con calidad y es explicable | SRS-QUO-004 |
| DEC-005 / TEC-001 | Ofertas inmutables con revisiones trazables antes de adjudicar; `Offer` agregado independiente | Permite corregir errores sin perder trazabilidad ni comparar datos que cambian sin aviso | SRS-RFQ-007 |
| DEC-006 | Capacidad global (2 por fecha) más capacidad por paquete como excepción | Conserva la regla simple del piloto sin limitar venues, equipos o staffing | SRS-BOOK-003, SRS-CAT-009 |
| DEC-007 | Zona IANA por evento, instantes UTC y fecha local conservada | Evita errores al comparar fechas y permite expansión | SRS-EVT-001, SRS-RFQ-005 |
| DEC-008 | Varios `ADMIN_EMPRESA`, un único `PROPIETARIO` (valores DEC-022), transferencia controlada | Evita punto único de falla manteniendo responsabilidad clara | SRS-AUTH-009 |
| DEC-009 | Verificación de proveedores por tres niveles según riesgo | No excluye proveedores pequeños y permite endurecer controles por categoría | SRS-ADM-001 |
| DEC-010 | Configuración fiscal explícita por proveedor/servicio; comisión separada y congelada | Evita mostrar "IVA incluido" cuando no corresponde y facilita facturación futura | SRS-QUO-008, RN-10 |
| DEC-011 | Roles fijos con permisos predefinidos; sin editor granular | Menor complejidad de implementación, QA y soporte | SRS-AUTH-009 |
| DEC-012 | RPO ≤ 1 h y RTO ≤ 4 h, con prueba trimestral de restauración | Una pérdida de 24 h de reservas y adjudicaciones erosiona la confianza | Sección 7.4 (SRS-NFR-AVL) |
| DEC-013 / DEC-014 | Vercel + Railway como candidato validado por criterios ponderados; región cercana a Colombia con inventario de subprocesadores | Evita decidir por precio o familiaridad y hace visible el flujo internacional de datos | Secciones 2.3 y 7.4 |
| DEC-015 | Mapas limitados a autocompletado, geocodificación y distancia aproximada, con captura manual | Controla costos y evita que Maps bloquee reservas | Sección 6.6 |
| DEC-016 | React-PDF por defecto desde snapshot; Puppeteer solo si el prototipo lo exige | Evita un navegador headless sin valor y garantiza consistencia histórica | Sección 6.7 |
| DEC-017 | Sesión en servidor con cookies seguras; sin tokens en `localStorage` | Reduce exposición ante XSS y separa autenticación de autorización | SRS-AUTH-003 |
| DEC-018 | Snapshots inmutables de las decisiones comerciales | Explica qué aceptó cada parte y evita que editar el catálogo cambie reservas | SRS-BOOK-004 |
| TEC-002 | `RfqCycle` agrupa las solicitudes paralelas de una ronda | Hace explícitos el límite de 1–5 proveedores, el SLA común y las rondas | SRS-RFQ-010 |
| TEC-003 | Idempotencia obligatoria en reserva, adjudicación y creaciones repetibles | Evita reservas duplicadas y dobles adjudicaciones | SRS-BOOK-006 |
| TEC-004 | Outbox transaccional en PostgreSQL procesado por worker | Garantiza notificaciones recuperables tras un commit | Sección 7 |
| TEC-005 | Tenant resuelto en backend; RLS como defensa adicional | Reduce el riesgo de exposición cruzada entre empresas | SRS-AUTH-005 |

**Decisiones de Review V1 y V2:** DEC-019..034 y TEC-006..012 (`Decisiones.md` §4b), aprobadas el 23-11-2026, están aplicadas en esta especificación y se citan en cada requisito afectado como "(DEC-0xx)". Principales requisitos afectados: SRS-AUTH-001/002/009..012, SRS-TEN-004, SRS-CAT-003/010/015, SRS-EVT-001/007..010, SRS-QUO-001/008/013, SRS-BOOK-007..010, SRS-RFQ-005/007/009/012/013, SRS-REV-004/008, SRS-NOT-006, SRS-ADM-008..013 y SRS-NFR-PRIV-002/007/008.

**Decisiones de Review V3:** DEC-035..037 (`Decisiones.md` §4b), aprobadas con fecha 23-11-2026, están aplicadas en SRS-AUTH-005/007, SRS-ADM-012/013, SRS-RFQ-012, SRS-NFR-PRIV-002, §8.7, §8.12 y §9.2, §9.3 y §9.7. Los plazos de DEC-037 requieren validación legal antes de operar con datos reales.

---

# 14. Estrategia de pruebas derivada del SRS

## 14.1 Pruebas unitarias

- validación de NIT, email, teléfono, precios y capacidad;
- cálculo de precio base + precio por persona;
- cálculo de promedios de reseñas;
- ranking y fallback;
- transiciones de estado;
- renderizado de plantillas WhatsApp;
- validación de JSON importado.

## 14.2 Pruebas de integración

- Auth0: login, token inválido, expiración y mapeo de usuario;
- SendGrid: envío, fallo temporal, fallo permanente y reintento;
- Cloudinary: carga autorizada y rechazo de archivo inválido;
- Redis/BullMQ: SLA, reintentos y recuperación de tareas;
- PostgreSQL: integridad referencial y transacciones de reserva/adjudicación;
- PDF: contenido, acceso y snapshot correcto.

## 14.3 Pruebas de seguridad

- acceso cruzado entre tenants;
- escalamiento de privilegios;
- IDOR/BOLA sobre eventos, cotizaciones y proveedores;
- abuso/reutilización de Magic Link;
- fuerza bruta y rate limiting;
- XSS en reseñas, descripciones y notas;
- inyección SQL;
- CSRF donde aplique;
- carga de archivos maliciosos;
- filtración de tokens en logs o referers.

## 14.4 Pruebas de concurrencia

- dos reservas simultáneas para el último cupo;
- dos adjudicaciones simultáneas para el mismo ítem;
- adjudicación concurrente con una reserva Instant Book sobre el último cupo del mismo proveedor y fecha;
- doble envío de formulario Magic Link;
- reintento duplicado de creación de e-RFQ;
- dos actualizaciones simultáneas de disponibilidad;
- suspensión de un proveedor concurrente con una adjudicación o reserva sobre ese proveedor (SRS-ADM-013).

## 14.5 Pruebas de aceptación

Los escenarios de la sección 8 se convertirán en pruebas E2E. Ningún flujo crítico se considerará listo solo por pasar pruebas unitarias.

---

# 15. Glosario

| Término | Definición |
|---|---|
| B2B | Business to Business; relación comercial entre empresas/profesionales. |
| Empresa organizadora | Empresa que contrata proveedores para producir eventos. |
| Proveedor freelance | Profesional independiente o microempresa que ofrece servicios para eventos. |
| Categoría | Nivel superior de clasificación de servicios. |
| Subtipo | Especialización dentro de una categoría. |
| Instant Book | Reserva inmediata de un paquete con tarifa vinculante y disponibilidad validada. |
| e-RFQ / e-RFP | Solicitud electrónica de cotización/propuesta enviada a varios proveedores. |
| Bid Tabulation | Tabla que normaliza y compara las ofertas recibidas. |
| Magic Link | Enlace seguro, de propósito limitado y un solo uso para responder una solicitud. |
| SLA | Ventana límite de respuesta de una solicitud e-RFQ. |
| Tenant | Espacio de datos aislado correspondiente a una empresa. |
| Idempotencia | Propiedad por la que repetir una operación no crea efectos duplicados. |
| Snapshot | Copia inmutable de datos relevantes en el momento de una operación. |
| Click-to-Chat | Enlace que abre WhatsApp con destinatario y texto prellenado. |
| RTO | Tiempo objetivo máximo para recuperar el servicio tras una interrupción. |
| RPO | Pérdida máxima de datos temporal aceptable tras una interrupción. |
| COP | Peso colombiano. |
| MVP | Producto mínimo viable; primera fase operativa. |

Glosario consolidado: `Glosario.md`.

---

# 16. Criterio de cierre del SRS

Este SRS se considera suficientemente definido para iniciar el diseño de arquitectura y contratos técnicos del MVP cuando:
- los requisitos funcionales de las secciones 3–6 estén aceptados;
- todas las decisiones de `Decisiones.md` estén aprobadas o rechazadas (cumplido: DEC-019..037 y TEC-006..012 figuran aprobadas con fecha 23-11-2026);
- los requisitos no funcionales tengan escenarios de medición;
- los identificadores de requisitos se mantengan en historias, commits y pruebas;
- cualquier cambio posterior actualice este documento y su matriz de trazabilidad.

**Siguiente documento recomendado:** `ProveeEventos_SAD.md` — Software Architecture Document. El SAD deberá convertir estos requisitos en componentes, límites de contexto, contratos, secuencias, despliegue, seguridad y decisiones arquitectónicas.
