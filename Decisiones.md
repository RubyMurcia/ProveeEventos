# ProveeEventos — Registro de decisiones

**Archivo:** `Decisiones.md`  
**Versión:** 1.6  
**Fecha:** 25 de noviembre de 2026  
**Producto:** ProveeEventos  
**Alcance:** MVP / Fase 1  
**Estado:** DEC-001..018 y TEC-001..005 aprobadas (propuesta recomendada adoptada el 23 de noviembre de 2026) e incorporadas en PRD, SRS, SAD, DDD y API Spec. DEC-019..034 y TEC-006..012 (sección 4b, derivadas de `Reviews/Review_V1.md` y `Reviews/Review_V2.md`) y ADR-016..022 del SAD **aprobadas el 23 de noviembre de 2026** e incorporadas en los mismos documentos. DEC-035..037 (derivadas de `Reviews/Review_V3.md`) **aprobadas con fecha 23 de noviembre de 2026** e incorporadas en los mismos documentos. TEC-013 (ampliación del contrato API 1.4.0) está **pendiente de aprobación**

## Historial de versiones

| Versión | Fecha | Descripción |
|---|---|---|
| 1.0 | 23-11-2026 | Registro de DEC-001..018 y TEC-001..005, aprobadas |
| 1.1 | 23-11-2026 | Se añaden DEC-019..033 y TEC-006..011 como propuestas pendientes de aprobación (Plan0001, Review V1); se corrige el resumen de DEC-012 |
| 1.2 | 24-11-2026 | Review V2 (Plan0003): se añaden DEC-034 y TEC-012 (pendientes); TEC-011 incorpora la regla de exención de `Idempotency-Key` y la extensión de `If-Match`; §6 incluye el orden de aprobación de las propuestas; §7 corrige su frase introductoria |
| 1.3 | 24-11-2026 | Se registran como aprobadas (23-11-2026) DEC-019..034, TEC-006..012 y ADR-016..022; se retiran las marcas de pendiente en todos los documentos (P00 de Plan0002) |
| 1.4 | 24-11-2026 | Review V3 (Plan0004): se añaden DEC-035..037 como propuestas pendientes de aprobación; el título de §4b deja de llamar "propuestas" a las decisiones ya aprobadas; §1 aclara a qué versiones de origen se refiere |
| 1.5 | 24-11-2026 | Se registran como aprobadas (fecha de registro 23-11-2026) DEC-035..037; se retiran las marcas de pendiente en todos los documentos y el PRD pasa a 2.4 (P10 de Plan0002); §9 recoge dónde se incorporaron |
| 1.6 | 25-11-2026 | Se añade TEC-013 como propuesta pendiente de aprobación: ampliación y corrección del contrato API 1.4.0 derivadas de la especificación UX/UI (`Reviews/ReviewsUXUI_V1.md`) |

---

## 1. Propósito

Este documento reúne las decisiones de producto, operación, negocio y arquitectura que los documentos PRD v2.2, SRS v1.0, SAD v1.0 y DDD v1.0 identifican como pendientes o que requieren una selección explícita antes de producción. Esas son las versiones de origen de la primera tanda (DEC-001..018 y TEC-001..005); las decisiones posteriores surgen de las revisiones indicadas en la sección 4b, y las versiones vigentes de cada documento están en su propio historial.

Para cada decisión se presenta:

- **Situación:** qué no está definido o qué ambigüedad debe cerrarse.
- **Propuesta recomendada:** la opción que considero más equilibrada para el MVP.
- **Ventajas:** qué mejora al adoptar la propuesta.
- **Costos y riesgos:** qué se sacrifica o qué debe vigilarse.
- **Alternativa:** otra opción razonable cuando vale la pena compararla.
- **Momento de aprobación:** cuándo debe quedar resuelta.

Las decisiones de este documento fueron aprobadas adoptando la propuesta recomendada (sección 7) y ya están incorporadas en los demás documentos de diseño (sección 9). No constituyen asesoría jurídica, tributaria o contable. En particular, las decisiones fiscales, de privacidad, contratación y residencia de datos deben validarse con profesionales competentes en Colombia.

## 2. Criterios utilizados

Las recomendaciones priorizan:

1. Proteger a organizadores y proveedores de compromisos ambiguos.
2. Reducir fricción para proveedores freelance y microempresas.
3. Mantener el MVP pequeño, operable y económicamente viable.
4. Evitar automatizar penalizaciones o decisiones difíciles de revertir.
5. Preservar historial, trazabilidad y evidencia de lo ocurrido.
6. Mantener PostgreSQL como fuente de verdad de las operaciones críticas.
7. No convertir capacidades futuras —pagos, WhatsApp Business API o automatizaciones avanzadas— en requisitos ocultos del MVP.
8. Permitir que las reglas comerciales puedan configurarse sin reescribir el dominio.

## 3. Resumen ejecutivo

| ID | Decisión | Propuesta resumida | Prioridad |
|---|---|---|---|
| DEC-001 | Cancelaciones | Política por etapas, motivo obligatorio, sin penalidad/reembolso automático en MVP | Crítica |
| DEC-002 | Devengo de comisión | Se considera cerrada al completar el servicio y aceptar el organizador; fallback con plazo de disputa | Crítica |
| DEC-003 | Retención y eliminación | Retención por categoría de dato; separar datos personales, transacciones y auditoría | Crítica |
| DEC-004 | Ranking | Fórmula explicable y configurable; calidad bayesiana, precio, proximidad y relevancia | Alta |
| DEC-005 | Edición de ofertas | Versiones inmutables; permitir revisión antes de adjudicación con trazabilidad | Alta |
| DEC-006 | Capacidad diaria | Límite base de dos eventos por proveedor/fecha, con capacidad específica por paquete como excepción | Crítica |
| DEC-007 | Zona horaria | Zona IANA por evento; fecha local como dato de negocio y timestamps en UTC | Crítica |
| DEC-008 | Administradores | Permitir varios administradores, con un propietario principal y transferencia controlada | Alta |
| DEC-009 | Verificación de proveedores | Verificación por niveles, evidencia mínima proporcional al riesgo | Crítica |
| DEC-010 | IVA y comisión | Configuración fiscal explícita por proveedor/servicio; no inferir tratamiento tributario | Crítica |
| DEC-011 | Permisos de coordinador | Roles fijos en MVP, con permisos predefinidos; evitar editor granular inicial | Alta |
| DEC-012 | RPO | RPO ≤ 1 h y RTO ≤ 4 h; RPO de 24 h solo como riesgo temporal explícito y revisado | Alta |
| DEC-013 | Hosting y residencia | Elegir proveedor por seguridad, backups, región, soporte y costo total; no decidir solo por precio | Alta |
| DEC-014 | Región de datos | Preferir región cercana a Colombia si cumple requisitos; documentar subprocesadores y transferencias | Alta |
| DEC-015 | Mapas | MVP con geocodificación/autocompletado limitado y captura manual de respaldo | Media |
| DEC-016 | Generación PDF | Elegir tras prototipo; preferencia inicial por React-PDF si los documentos son simples | Media |
| DEC-017 | Sesión Auth0/Next.js | Sesión gestionada en servidor con cookies seguras; no guardar tokens sensibles en localStorage | Crítica |
| DEC-018 | Permisos y propiedad de datos históricos | Conservar snapshots y auditoría; no reescribir acuerdos históricos al editar catálogo | Crítica |

**Decisiones de la sección 4b (aprobadas el 23 de noviembre de 2026):**

| ID | Decisión | Propuesta resumida | Prioridad |
|---|---|---|---|
| DEC-019 | Jerarquía y PRD | PRD v2.2 consolidado con el alcance real; se mantiene la jerarquía PRD > SRS > SAD > DDD > API | Crítica |
| DEC-020 | Taxonomía | 21 categorías con códigos estables `CAT-01..21`; subtipos iniciales en el Anexo B del PRD | Crítica |
| DEC-021 | Entregas del MVP | E1 piloto (núcleo e-RFQ) y E2 (Instant Book, capacidad por paquete, asistente WhatsApp, verificación nivel 3, transferencia de propiedad) | Crítica |
| DEC-022 | Idioma de enums y roles | Estados y roles de negocio en español; códigos técnicos de modalidad/canal/origen se conservan; vocabulario único de roles | Alta |
| DEC-023 | Estados de contratación y comisión | Máquina de estados de `Booking`, estado de comisión y sincronización con el ítem | Crítica |
| DEC-024 | Eventos con compromisos | Reglas para editar o cancelar un evento con reservas o RFQ abiertas | Crítica |
| DEC-025 | Capacidad en eventos de varios días | Cada fecha local tocada consume capacidad; excepción para cruces de medianoche hasta las 06:00 | Alta |
| DEC-026 | Reapertura de RFQ | No se reabren estados terminales; nueva ronda; estado `CANCELADO`; reintento de envío; ofertas vencidas | Alta |
| DEC-027 | Comisión: pagador y base | La paga el organizador; base: precio acordado con extras, antes de impuestos | Crítica |
| DEC-028 | Revelación de contacto | Contacto directo solo vía enlace `wa.me` de una RFQ enviada o tras reserva/adjudicación | Alta |
| DEC-029 | Planes, prueba y límites | Plan `PRUEBA` de 90 días; límites que bloquean creación, nunca compromisos existentes | Alta |
| DEC-030 | Reseñas | Ventana de 30 días, no editables, identifican a la empresa, reporte con motivo | Media |
| DEC-031 | Verificación y suspensión | Dimensiones ortogonales: estado de verificación y estado de cuenta | Alta |
| DEC-032 | Redondeo de COP | `NUMERIC(14,2)` interno; redondeo half-up al peso por línea | Media |
| DEC-033 | Proceso de cobro en el MVP | Facturación externa mensual a partir de exportaciones; conciliación manual | Alta |
| DEC-034 | Suspensión con contrataciones futuras | La suspensión bloquea operaciones nuevas; las contrataciones futuras pasan a revisión administrativa con aviso a la organizadora | Alta |
| TEC-006 | Tenant activo | Organización activa en la sesión BFF, cabecera `X-Organization-Id` validada | Alta |
| TEC-007 | Registro autenticado | El registro de empresa/proveedor exige identidad Auth0; email tomado del token | Crítica |
| TEC-008 | Magic Link sin token en el path | Token en el fragmento de la URL web y en el cuerpo de las peticiones | Alta |
| TEC-009 | Confirmación de compromisos única | `ConfirmBooking` compartido por Instant Book y adjudicación, con bloqueo ordenado de capacidad | Crítica |
| TEC-010 | Alineación de módulos | 12 módulos = 12 contextos del DDD; seguimiento en Quotation; comisiones en Booking | Alta |
| TEC-011 | Contrato de errores y concurrencia | `problem+json` con catálogo de códigos; `ETag`/`If-Match`; `Idempotency-Key` reutilizable | Media |
| TEC-012 | Modelo de paginación | Página para colecciones acotadas; cursor para catálogo público, notificaciones y auditoría; un modelo por operación | Media |
| TEC-013 | Contrato API 1.4.0 (pendiente) | Exponer por API los datos y operaciones que la interfaz necesita para requisitos ya definidos y corregir la composición de esquemas | Alta |

**Decisiones de la sección 4b derivadas de Review V3 (aprobadas el 23 de noviembre de 2026):**

| ID | Decisión | Propuesta resumida | Prioridad |
|---|---|---|---|
| DEC-035 | Cierre de ronda e-RFQ sin adjudicación | Destino único del ítem según lo ocurrido en la ronda; una solicitud respondida sin oferta vigente y con SLA vencido pasa a `NO_ADJUDICADO` | Alta |
| DEC-036 | Operación de la revisión por suspensión | Ventana de decisión, quién resuelve, acciones que conserva el proveedor suspendido y serialización con la confirmación | Alta |
| DEC-037 | Plazo provisional de solicitudes de titulares | Consultas en 10 días hábiles (+5); reclamos en 15 (+8), sujeto a validación legal | Media |

---

# 4. Decisiones de producto y operación

## DEC-001 — Política de cancelación de reservas y servicios


> **Nota (v1.1):** los valores `CANCELLED` y `CANCELLATION_REVIEW` de esta decisión aprobada pasan a `CANCELADO` y `CANCELACION_EN_REVISION` según DEC-022, y la máquina de estados completa está en DEC-023 (ambas aprobadas el 23-11-2026). El texto aprobado se conserva como registro.

**Situación**

El SRS y el DDD identifican la política de cancelación como pendiente. El sistema necesita distinguir una cancelación de una simple edición, un rechazo de oferta o una reserva no confirmada. Tampoco se ha definido una política de penalizaciones, anticipos o reembolsos. Los pagos están fuera del MVP.

**Propuesta recomendada**

Adoptar una política por etapas y mantener el MVP sin cálculo automático de penalizaciones ni reembolsos:

1. **Antes de la confirmación:** no existe reserva; el organizador puede retirar una selección o solicitud sin generar una cancelación contractual.
2. **Reserva confirmada y servicio no iniciado:** cualquiera de las partes puede solicitar cancelación indicando motivo y fecha/hora. La otra parte recibe notificación y puede aceptar o disputar.
3. **Cancelación aceptada por ambas partes:** la reserva pasa a `CANCELLED`; se libera la capacidad del proveedor de forma transaccional.
4. **Cancelación disputada o sin respuesta:** la reserva pasa a un estado de revisión (`CANCELLATION_REVIEW` o equivalente); no se libera capacidad automáticamente hasta resolverla.
5. **Servicio iniciado o completado:** no permitir cancelación ordinaria desde autoservicio. El caso requiere soporte o administración, conservando el historial.
6. **Cancelación por causa atribuible a la plataforma o proveedor:** registrar motivo específico y habilitar revisión administrativa.
7. Registrar siempre actor, fecha, motivo, estado anterior, estado nuevo y evidencia adjunta si existe.

Para el MVP, la aceptación de la cancelación debe ser un acuerdo operativo entre las partes. No debe generar cargos, multas ni promesas de devolución desde ProveeEventos.

**Ventajas**

- Reduce conflictos por cancelaciones unilaterales.
- Evita que el sistema invente una penalización sin tener pagos integrados.
- Permite liberar capacidad solo cuando existe una decisión clara.
- Genera evidencia para soporte, métricas y futuras políticas comerciales.
- Es sencillo de explicar a proveedores pequeños.

**Costos y riesgos**

- La resolución bilateral puede tardar.
- Se necesita una bandeja de casos pendientes y un procedimiento de soporte.
- No protege económicamente a una parte frente a cancelaciones tardías; eso debe resolverse en condiciones comerciales futuras.

**Alternativa**

Permitir cancelación unilateral con ventanas temporales y penalizaciones predefinidas. No la recomiendo para el MVP: sin pagos ni marco contractual validado, sería una regla difícil de ejecutar y potencialmente conflictiva.

**Aprobación necesaria:** antes de habilitar cancelación autónoma en producción. La política contractual y sus textos deben revisarse legalmente.

## DEC-002 — Momento en que una contratación se considera cerrada para devengar comisión


> **Nota (v1.1):** el valor `ON_HOLD` pasa a `RETENIDA` según DEC-022, y los estados de contratación y comisión se detallan en DEC-023 (aprobada el 23-11-2026). El texto aprobado se conserva como registro.

**Situación**

El SRS pide definir el momento exacto en que una contratación queda cerrada para calcular la comisión. El MVP no procesa pagos: la comisión puede registrarse como dato comercial/contable interno, pero no cobrarse automáticamente.

**Propuesta recomendada**

Separar tres hechos que no deben confundirse:

- `BOOKING_CONFIRMED`: compromiso aceptado y reserva confirmada.
- `SERVICE_COMPLETED`: el servicio fue ejecutado.
- `COMMISSION_ACCRUED`: la comisión quedó devengada en el registro interno.

Regla propuesta:

1. El proveedor marca el servicio como realizado.
2. El organizador confirma la finalización o reporta una incidencia dentro de los **5 días calendario** siguientes.
3. Si el organizador confirma, la contratación se cierra y se registra el devengo de comisión.
4. Si no responde en esos 5 días, el sistema envía recordatorios y luego cierra automáticamente, siempre que no exista una incidencia abierta.
5. Si hay disputa, la comisión queda `ON_HOLD` hasta que se resuelva.
6. Si el servicio se cancela antes de ejecutarse, no se devenga comisión en el MVP.
7. El porcentaje aplicable se congela en el snapshot de la contratación; cambios futuros de tarifa no alteran reservas históricas.

**Ventajas**

- Vincula la comisión a una contratación efectivamente cumplida, no a una mera oferta.
- Da al organizador una ventana razonable para reportar incumplimientos.
- Evita que una disputa se convierta automáticamente en deuda.
- Permite medir GMV, bookings completados y comisión devengada por separado.
- Es implementable sin pasarela de pagos.

**Costos y riesgos**

- El cierre automático por silencio puede ser discutible si el organizador no vio las notificaciones.
- Cinco días es una propuesta operativa, no una obligación legal; debe probarse con usuarios.
- Se necesita un proceso de incidencias y reversión auditada de devengos erróneos.

**Alternativa**

Devengar al confirmar la reserva. Es más simple, pero penaliza al proveedor si el servicio nunca se realiza y confunde compromiso con cumplimiento. No la recomiendo.

**Aprobación necesaria:** antes de reportes de comisiones, acuerdos comerciales con proveedores o cualquier cobro futuro.

## DEC-003 — Retención y eliminación de datos

**Situación**

La política de retención está pendiente. El SRS contempla archivar borradores inactivos después de 90 días, pero esto no resuelve la retención de datos personales, transacciones, documentos, mensajes ni auditoría.

**Propuesta recomendada**

Aprobar una política por categoría, no un único plazo para toda la base de datos:

| Categoría | Propuesta inicial | Tratamiento |
|---|---|---|
| Borradores de eventos/cotizaciones sin actividad | 90 días | Archivar; avisar 7 días antes; permitir reactivación si no hay conflicto |
| Solicitudes e-RFQ y ofertas | Asociadas al historial de contratación | Conservar según plazo comercial/legal aplicable |
| Reservas y snapshots comerciales | Según plazo legal/contable aplicable | No eliminar por simple cierre de cuenta |
| Auditoría de seguridad y operaciones | Plazo definido por análisis de riesgo y obligación aplicable | Acceso restringido; integridad protegida |
| Archivos temporales y adjuntos no necesarios | 90 días después de cerrar el caso, salvo disputa | Eliminar o anonimizar |
| Respuestas WhatsApp pegadas y borradores de IA | 90 días tras cierre de la solicitud, salvo necesidad probatoria | Minimizar el texto almacenado; conservar la oferta estructurada |
| Cuenta de usuario inactiva | Aviso previo y proceso de cierre | Eliminar/anonymizar datos no sujetos a retención obligatoria |
| Consentimientos y versiones de avisos | Mientras sean necesarios para demostrar el consentimiento y según plazo aplicable | Conservar evidencia mínima |

La tabla es una política inicial de producto. Los plazos definitivos deben validarse frente a la Ley 1581 de 2012, normas reglamentarias, obligaciones tributarias/comerciales, contratos y criterios de asesoría legal en Colombia. No fijar un plazo legal por intuición.

Implementar:
- borrado lógico para recursos que deban desaparecer de la interfaz;
- eliminación física o anonimización mediante jobs auditados;
- retención legal (`legal_hold`) para disputas o requerimientos;
- registro de solicitud, ejecución y resultado de eliminación;
- exportación/corrección de datos personales según el procedimiento que se apruebe.

**Ventajas**

- Evita borrar evidencia de una contratación.
- Reduce acumulación innecesaria de datos personales.
- Permite atender solicitudes de titulares de datos.
- Hace posible automatizar limpieza sin comprometer auditoría.

**Costos y riesgos**

- Requiere una matriz de retención por tabla/archivo y procesos de purga.
- La anonimización debe diseñarse cuidadosamente para no dejar identificadores indirectos.
- Puede ser necesario conservar ciertos datos más tiempo por obligación legal.

**Alternativa**

Conservar todo indefinidamente. Es fácil de implementar a corto plazo, pero aumenta el riesgo de privacidad, seguridad y costos.

**Aprobación necesaria:** antes de producción y antes de recopilar datos personales reales a escala.

## DEC-004 — Fórmula de ranking calidad-precio

**Situación**

El PRD propone ranking por relación calidad-precio, promedio bayesiano y proximidad, pero no define una fórmula completa ni parámetros. El SRS recomienda mantener la intención del PRD y un fallback determinista.

**Propuesta recomendada**

Usar un ranking explicable, versionado y configurable. Para la primera versión, recomiendo esta composición:

- **Calidad ajustada (40 %):** promedio bayesiano de reseñas verificadas, con contracción hacia el promedio global/categoría cuando hay pocas reseñas.
- **Precio relativo (30 %):** posición del precio total estimado frente a proveedores comparables del mismo subtipo y alcance.
- **Proximidad/cobertura (20 %):** distancia o adecuación a la zona de servicio, sin premiar cercanía si el proveedor no cubre la ubicación.
- **Relevancia operativa (10 %):** coincidencia de categoría/subtipo, modalidad, disponibilidad indicativa y completitud del perfil.

Reglas adicionales:
1. Aplicar primero filtros de elegibilidad: proveedor activo y verificado, cobertura, categoría/subtipo y condiciones mínimas.
2. No permitir que una buena puntuación compense incumplir un filtro obligatorio.
3. No usar precio más bajo como sinónimo de mejor proveedor.
4. Si no hay ubicación precisa, redistribuir el peso de proximidad proporcionalmente entre los demás factores.
5. Si no hay reseñas suficientes, usar el prior de la categoría y mostrar que la calificación tiene poca evidencia.
6. Desempate determinista: calidad ajustada, luego precio, luego antigüedad de publicación o ID estable.
7. Guardar `ranking_version` y los componentes calculados para poder explicar y reproducir el orden.
8. Mostrar una explicación sencilla: “mejor coincidencia”, “mejor valor”, “mejor calificación con reseñas verificadas”; no presentar el score interno como verdad objetiva.

**Ventajas**

- Reduce el sesgo hacia proveedores nuevos o con pocas reseñas.
- Evita premiar precios bajos sin considerar calidad.
- Es explicable a organizadores y proveedores.
- Permite ajustar pesos con datos reales sin cambiar la arquitectura.
- Facilita pruebas A/B y análisis de impacto futuro.

**Costos y riesgos**

- Los pesos 40/30/20/10 son una hipótesis inicial, no una verdad estadística.
- La distancia puede ser injusta en zonas rurales o ciudades con tráfico complejo.
- El promedio bayesiano requiere un prior y un parámetro de fuerza que deben calibrarse.

**Alternativa**

Ordenar únicamente por promedio de reseñas y precio. Es más simple, pero favorece a perfiles con pocas reseñas extremas y no representa bien cobertura o pertinencia.

**Aprobación necesaria:** antes de publicar ranking como criterio predeterminado. Los pesos deben validarse con pruebas y datos del piloto.

## DEC-005 — Edición de una oferta después de responder


> **Nota (v1.1):** el punto 6 (reapertura por el organizador) queda sustituido por DEC-026: no se reabren solicitudes; se crea una nueva ronda (aprobada el 23-11-2026). El texto aprobado se conserva como registro.

**Situación**

El SRS no define si un proveedor puede modificar una oferta ya enviada ni qué ocurre con una oferta que ya está siendo comparada. El DDD recomienda separar `Offer` de `RfqRequest` y preservar historial/versionado.

**Propuesta recomendada**

Permitir revisiones controladas antes de la adjudicación:

1. Una oferta enviada se vuelve inmutable.
2. El proveedor puede crear una revisión mientras la solicitud siga abierta y no exista adjudicación.
3. La nueva revisión debe indicar motivo del cambio.
4. La revisión anterior permanece en historial, marcada como reemplazada, no borrada.
5. La tabla comparativa muestra por defecto la última revisión válida, pero permite consultar versiones previas.
6. Al vencer el SLA, no se permiten revisiones salvo que el organizador reabra explícitamente la solicitud.
7. Después de adjudicar, la oferta queda congelada. Cualquier cambio requiere cancelar/reabrir la contratación según política, no editar silenciosamente la oferta.
8. El proveedor debe confirmar que el nuevo precio/alcance reemplaza al anterior.

**Ventajas**

- Permite corregir errores honestos y negociar sin perder trazabilidad.
- Evita que el organizador compare datos que cambian sin aviso.
- Conserva evidencia del precio y condiciones adjudicadas.
- Es compatible con un agregado `Offer` independiente y versionado.

**Costos y riesgos**

- Aumenta complejidad de UI, estados y auditoría.
- Puede generar confusión si llegan varias revisiones cerca del vencimiento.
- Requiere reglas claras sobre SLA y re-apertura.

**Alternativa**

Bloquear toda oferta al primer envío y exigir una nueva solicitud para corregirla. Es más simple, pero introduce fricción innecesaria.

**Aprobación necesaria:** antes de implementar la edición de ofertas y cerrar el modelo de datos RFQ.

## DEC-006 — Capacidad: dos eventos por día o capacidad por paquete

**Situación**

El MVP establece un valor predeterminado de dos eventos por día por proveedor, pero no está definido si aplica a todos los servicios. Un fotógrafo puede cubrir más de un evento; un venue o catering puede tener capacidad muy distinta. El SRS ya recomienda modelar cupos por fecha y no un booleano.

**Propuesta recomendada**

Adoptar un modelo de capacidad en dos niveles:

- **Capacidad global del proveedor por fecha:** valor predeterminado `2`, aplicable como límite conservador inicial.
- **Capacidad por paquete/recurso:** excepción explícita para servicios cuya capacidad no sea equivalente a “un evento por proveedor” (por ejemplo, venue, alquiler de equipos, personal por unidades o paquetes paralelos).

Reglas:
1. Si el paquete no declara capacidad específica, hereda la capacidad global.
2. Si declara capacidad específica, la reserva debe consumir tanto el cupo del paquete como el cupo global, salvo que el proveedor configure explícitamente que el paquete opera con inventario independiente.
3. La capacidad se expresa como unidades/cupos enteros; la cantidad requerida por una reserva también es explícita.
4. Un bloqueo manual fija capacidad disponible en cero o reduce el cupo.
5. La búsqueda muestra disponibilidad orientativa; la reserva vuelve a validar y consumir cupos de forma atómica en PostgreSQL.
6. No permitir que la suma de reservas confirmadas exceda ninguna de las capacidades aplicables.
7. El proveedor no puede cambiar capacidad retroactivamente para invalidar reservas confirmadas.

**Ventajas**

- Conserva la regla simple para el piloto.
- No limita artificialmente servicios que manejan inventario o múltiples equipos.
- Permite crecer a recursos/unidades sin rehacer las reservas.
- Mantiene una sola lógica transaccional para Instant Book y adjudicación e-RFQ.

**Costos y riesgos**

- Es más complejo que un contador único por proveedor/fecha.
- Requiere que el proveedor entienda qué representa una unidad de capacidad.
- Puede haber errores de configuración; usar valores predeterminados seguros y validaciones.

**Alternativa**

Aplicar siempre máximo dos eventos por proveedor/fecha, sin excepciones. Es simple, pero perjudica categorías como venues, alquileres o staffing.

**Aprobación necesaria:** antes de habilitar reservas Instant Book y adjudicaciones que creen una reserva.

## DEC-007 — Zona horaria del evento y eventos que cruzan medianoche

**Situación**

El SRS exige fechas locales para eventos y timestamps operativos UTC, pero no define zona horaria oficial ni tratamiento de eventos que cruzan medianoche.

**Propuesta recomendada**

- Guardar una zona horaria IANA por evento, por ejemplo `America/Bogota`.
- Guardar `startsAtUtc` y `endsAtUtc` como instantes UTC, además de la zona IANA original.
- Conservar la fecha/hora local introducida por el usuario para mostrar y auditar.
- Derivar la zona inicial de la ciudad seleccionada, pero permitir confirmación explícita.
- Para eventos de varios días, usar un intervalo de inicio/fin; no representar todo con una sola fecha.
- Calcular disponibilidad diaria según la zona local del evento y una regla aprobada para servicios que cruzan medianoche.
- Los SLAs y timestamps técnicos usan UTC; la interfaz muestra la hora local correspondiente.
- No usar offsets fijos como `UTC-5` como sustituto de una zona IANA.

**Ventajas**

- Evita errores al comparar fechas de eventos y reservas.
- Permite expansión internacional futura.
- Mantiene coherencia entre notificaciones, calendarios y disponibilidad.
- Distingue el día comercial local del instante UTC.

**Costos y riesgos**

- Se deben validar fechas ambiguas o inexistentes en zonas con cambios de horario.
- Requiere almacenar más de un dato temporal.
- En Colombia actual el horario es estable, pero el diseño no debe codificar esa circunstancia como regla universal.

**Alternativa**

Guardar solo fecha local y asumir `America/Bogota` en toda la aplicación. Es suficiente para un piloto estrictamente colombiano, pero crea deuda técnica si hay expansión o eventos en zonas distintas.

**Aprobación necesaria:** antes de implementar disponibilidad, SLA, reservas y recordatorios.

## DEC-008 — Múltiples administradores y transferencia de propiedad de empresa


> **Nota (v1.1):** los roles `OWNER`, `ADMIN` y `COORDINATOR` pasan a `PROPIETARIO`, `ADMIN_EMPRESA` y `COORDINADOR`, con `COORDINADOR_RESTRINGIDO`, según DEC-022 (aprobada el 23-11-2026). El texto aprobado se conserva como registro.

**Situación**

El DDD/SRS dejan pendiente si una empresa puede tener más de un administrador y cómo se transfiere la propiedad.

**Propuesta recomendada**

Permitir varios administradores por empresa, pero mantener un único **propietario principal**:

- `OWNER`: un único miembro responsable de la propiedad de la organización.
- `ADMIN`: uno o más administradores operativos.
- `COORDINATOR`: usuarios que gestionan eventos con permisos predefinidos.

El propietario puede nombrar y revocar administradores. La transferencia de propiedad exige confirmación del propietario actual y aceptación del nuevo propietario. Si el propietario pierde acceso o deja la empresa, se inicia un procedimiento de recuperación con soporte y verificación.

No permitir que un administrador se elimine a sí mismo si eso deja a la empresa sin propietario válido. Mantener historial de cambios.

**Ventajas**

- Evita que una empresa dependa de una sola cuenta para operar.
- Reduce riesgo de bloqueo cuando un empleado se retira.
- Mantiene responsabilidad clara sobre la propiedad.
- Es compatible con el modelo de membresías del DDD.

**Costos y riesgos**

- Añade flujo de transferencia y recuperación.
- Debe definirse qué sucede con facturación, plan y datos cuando cambia el propietario.
- Requiere autenticación reforzada para operaciones sensibles.

**Alternativa**

Un solo administrador total por empresa. Es más sencillo, pero genera un punto único de falla y dificulta operaciones de equipos.

**Aprobación necesaria:** antes de cerrar el modelo de organizaciones, membresías e invitaciones.

## DEC-009 — Verificación de proveedores y evidencias requeridas

**Situación**

El proveedor debe ser aprobado por administración antes de aparecer en el catálogo. El SRS distingue verificación de email y aprobación administrativa, pero no define la evidencia exacta.

**Propuesta recomendada**

Crear verificación por niveles, con requisitos proporcionales a la categoría y riesgo:

**Nivel 1 — Identidad y contacto**
- email verificado;
- teléfono verificado;
- nombre legal o nombre de persona;
- ciudad y datos de contacto consistentes.

**Nivel 2 — Actividad comercial**
- tipo de proveedor: persona natural o empresa;
- identificación fiscal/comercial aplicable (por ejemplo, NIT cuando corresponda);
- datos de facturación o documento equivalente, si son necesarios para la operación;
- aceptación de términos y política de datos.

**Nivel 3 — Evidencia del servicio**
- portafolio o evidencia de trabajos anteriores;
- referencias o documentos adicionales para categorías de mayor riesgo;
- revisión manual para categorías que impliquen seguridad, transporte, cuidado de personas, alimentos u otras obligaciones especiales.

La plataforma debe almacenar qué evidencia fue revisada, quién la revisó, fecha, resultado y vencimiento si aplica. No almacenar documentos de identidad completos si basta una verificación externa o metadato mínimo. La etiqueta pública debe distinguir “identidad/contacto verificados” de “experiencia revisada” si se usan niveles diferentes.

**Ventajas**

- Evita exigir el mismo paquete documental a un fotógrafo freelance y a un proveedor de servicios de mayor riesgo.
- Reduce barreras de entrada.
- Hace la decisión administrativa auditable.
- Permite endurecer controles por categoría sin rediseñar el flujo.

**Costos y riesgos**

- La revisión manual consume tiempo operativo.
- Se necesita política para documentos vencidos, rechazo y apelación.
- Los niveles no deben inducir al usuario a creer que ProveeEventos garantiza la calidad del servicio.

**Alternativa**

Exigir NIT y documentación completa a todos. Puede elevar la confianza aparente, pero excluye proveedores legítimos y pequeños que operan bajo otras figuras.

**Aprobación necesaria:** antes de abrir el registro de proveedores al público. Revisar legalmente los requisitos por categoría.

## DEC-010 — Tratamiento de IVA, impuestos y comisión

**Situación**

El PRD/SRS mencionan precios con IVA incluido, pero el tratamiento depende de la condición fiscal del proveedor y de la naturaleza del servicio. También falta definir cómo se presenta la comisión de ProveeEventos. No se deben inferir obligaciones tributarias a partir del perfil comercial.

**Propuesta recomendada**

Separar en el modelo y en la interfaz:

1. **Precio del proveedor:** precio total que el proveedor declara para el servicio.
2. **Tratamiento de impuestos:** configuración explícita y validada según tipo de proveedor/operación; no asumir que todos cobran IVA ni aplicar una tasa universal sin validación.
3. **Comisión de plataforma:** porcentaje o regla comercial independiente, versionada y congelada en el snapshot de contratación.
4. **Precio mostrado al organizador:** indicar si el precio incluye impuestos, si estos no aplican o si el proveedor debe confirmarlos.
5. **Documento comercial:** identificar claramente quién presta el servicio y quién sería responsable de facturar cada concepto.
6. **MVP:** registrar el cálculo y el desglose informativo, pero no emitir factura tributaria ni recaudar pagos si esas capacidades no están incluidas y validadas.

La configuración fiscal debe ser administrable y tener vigencia desde/hasta. No cambiar retrospectivamente el snapshot de una contratación.

**Ventajas**

- Evita mostrar un precio “IVA incluido” cuando el tratamiento no corresponde.
- Separa la remuneración del proveedor de la comisión de plataforma.
- Facilita futura facturación/pagos sin alterar el historial.
- Reduce riesgo de errores contables.

**Costos y riesgos**

- Requiere asesoría contable/tributaria y parametrización.
- Puede haber más de un tratamiento fiscal para servicios similares.
- El MVP debe comunicar con claridad que la plataforma no sustituye la factura del proveedor.

**Alternativa**

Aplicar IVA incluido a todos los paquetes y calcular comisión sobre el total. No la recomiendo: puede ser incorrecto según el proveedor, la operación y la naturaleza del servicio.

**Aprobación necesaria:** antes de mostrar desgloses fiscales definitivos, formalizar comisiones o emitir documentos con apariencia tributaria.

## DEC-011 — Permisos granulares del coordinador

**Situación**

El SRS deja pendiente si el coordinador tendrá permisos configurables o si basta un rol fijo.

**Propuesta recomendada**

Para el MVP, utilizar permisos predefinidos y simples:

- **Administrador/propietario:** administra empresa, miembros, plan y todas las operaciones.
- **Coordinador:** crea y gestiona eventos, cotizaciones, RFQ, reservas y seguimiento.
- **Coordinador restringido (opcional si el producto lo necesita desde el piloto):** puede consultar y editar eventos asignados, pero no adjudicar ni cancelar contrataciones.

No construir inicialmente un editor visual de permisos por acción. Si se requiere limitar acceso, usar un conjunto pequeño de perfiles y asignación por evento/área.

**Ventajas**

- Menor complejidad de implementación y pruebas.
- Fácil de explicar a empresas pequeñas.
- Evita combinaciones de permisos difíciles de auditar.
- Permite ampliar permisos con evidencia de uso.

**Costos y riesgos**

- Algunas empresas grandes podrían requerir reglas más específicas.
- La autorización por evento debe probarse cuidadosamente para no abrir acceso entre coordinadores.

**Alternativa**

RBAC configurable con permisos individuales desde el inicio. Ofrece flexibilidad, pero aumenta mucho el costo de producto, soporte y QA.

**Aprobación necesaria:** antes de implementar membresías y matriz de autorización.

## DEC-012 — RPO y estrategia de recuperación

**Situación**

El SAD propone RPO máximo de 24 horas si solo hay backup diario, pero queda pendiente aprobación. El RTO objetivo del SRS es máximo 4 horas.

**Propuesta recomendada**

Para una plataforma que registra reservas y adjudicaciones, recomiendo apuntar a:

- **RPO objetivo ≤ 1 hora** mediante backups continuos/WAL o mecanismo equivalente.
- **RTO objetivo ≤ 4 horas**, sujeto a simulacros.
- Backups diarios como base más recuperación a un punto en el tiempo si el proveedor lo soporta.
- Prueba de restauración al menos trimestral durante el MVP y después según riesgo.
- Outbox en PostgreSQL como fuente para reconstruir tareas; Redis no debe ser el único lugar donde exista una operación pendiente.

Si el costo de RPO ≤ 1 hora no es viable en el piloto, se puede aprobar temporalmente RPO de 24 horas, pero debe comunicarse como riesgo explícito y revisarse antes de procesar un volumen relevante de reservas.

**Ventajas**

- Reduce pérdida potencial de reservas y ofertas.
- Protege la confianza entre organizadores y proveedores.
- Hace que el RPO sea una decisión consciente de negocio, no una consecuencia accidental del backup.

**Costos y riesgos**

- Backups continuos/PITR pueden incrementar costos.
- RPO y RTO solo se consideran reales después de pruebas de restauración.

**Alternativa**

RPO 24 horas con backup diario. Es más económico, pero podría perder un día de operaciones confirmadas.

**Aprobación necesaria:** antes de producción y selección final del hosting.

## DEC-013 — Proveedor de hosting

**Situación**

El PRD/SAD proponen Vercel para frontend y Railway para API, worker, PostgreSQL y Redis como referencia. La selección final requiere validar costos, región, backups, conexiones, soporte y SLA.

**Propuesta recomendada**

Mantener Vercel + Railway como candidato de MVP, no como decisión irreversible. Ejecutar una prueba de aceptación técnica comparando al menos una alternativa administrada equivalente con estos criterios ponderados:

- 25 %: seguridad, backups, restauración y aislamiento de red;
- 20 %: disponibilidad, soporte y observabilidad;
- 20 %: latencia y región;
- 20 %: costo total mensual y costo al escalar;
- 15 %: facilidad de despliegue, migración y operación.

La base de datos debe estar en una región cercana al mercado inicial siempre que cumpla los requisitos de seguridad y disponibilidad. Separar API y worker como procesos, aunque compartan repositorio/lógica del monolito modular.

**Ventajas**

- Evita elegir solo por familiaridad o precio inicial.
- Permite conservar la arquitectura propuesta sin acoplarla al proveedor.
- Hace comparables los costos de producción y crecimiento.

**Costos y riesgos**

- Requiere una prueba técnica breve y tiempo de evaluación.
- La mejor región disponible puede no ser la más cercana.
- El costo de transferencia, backups y conexiones puede cambiar el costo aparente.

**Alternativa**

Adoptar directamente Vercel + Railway. Es razonable para acelerar el MVP si se valida que cumple backups, región, límites de conexión y presupuesto.

**Aprobación necesaria:** antes de staging integrado y producción.

## DEC-014 — Región de hosting y residencia de datos

**Situación**

El SAD deja pendiente la región y residencia de datos. La plataforma opera inicialmente en Colombia y tratará datos personales de empresas, coordinadores y proveedores.

**Propuesta recomendada**

- Preferir una región en Colombia si existe una opción que cumpla seguridad, disponibilidad y costos; de lo contrario, evaluar una región cercana (por ejemplo, en América) y documentar la decisión.
- Mantener inventario de subprocesadores: hosting, autenticación, correo, archivos, analítica y mapas.
- Documentar qué datos se envían a cada proveedor y para qué finalidad.
- Revisar contratos, transferencias internacionales, encargados y medidas de seguridad con asesoría legal colombiana.
- Evitar enviar contenido completo de cotizaciones o documentos a servicios externos si solo se requiere un identificador o metadato.

**Ventajas**

- Hace visible el flujo internacional de datos.
- Permite tomar una decisión de hosting compatible con la operación real.
- Reduce exposición innecesaria a terceros.

**Costos y riesgos**

- La región geográfica no garantiza por sí sola cumplimiento normativo.
- Algunas integraciones SaaS pueden procesar datos fuera de la región elegida.

**Alternativa**

Elegir la región más barata y documentar después. No la recomiendo porque posterga un tema de privacidad y operación.

**Aprobación necesaria:** antes de producción y de conectar servicios externos con datos reales.

## DEC-015 — Alcance de Google Maps en el MVP

**Situación**

El PRD contempla autocompletado y cercanía; el SRS permite captura manual si el servicio falla. El SAD considera Maps una integración opcional y no crítica.

**Propuesta recomendada**

Incluir únicamente:
- autocompletado de ciudad/dirección cuando el usuario lo necesite;
- geocodificación de la ubicación del evento y cobertura del proveedor;
- cálculo de distancia aproximada en línea recta o por proveedor de mapas, sin prometer tiempo real de desplazamiento;
- captura manual siempre disponible como alternativa.

No incluir en MVP optimización de rutas, tráfico, mapas avanzados ni cargos por uso ilimitado. Aplicar cuotas, alertas de consumo y restricciones de API key.

**Ventajas**

- Mejora la búsqueda por cobertura y proximidad.
- Mantiene una alternativa si el servicio externo falla.
- Controla costos y evita que mapas bloqueen reservas.

**Costos y riesgos**

- La geocodificación puede tener costo variable.
- La distancia geográfica no equivale a tiempo de traslado.
- Requiere revisar términos de uso y restricciones de almacenamiento del proveedor.

**Alternativa**

No integrar mapas en MVP y usar ciudad/zona seleccionada manualmente. Es la opción más económica, pero reduce precisión del filtro geográfico.

**Aprobación necesaria:** antes de comprometer presupuesto de API; puede diferirse sin bloquear el núcleo transaccional.

## DEC-016 — Generación de PDF: Puppeteer o React-PDF

**Situación**

El SAD deja la selección pendiente hasta realizar un prototipo.

**Propuesta recomendada**

Hacer una prueba corta con una cotización realista y comparar:
- fidelidad visual;
- tablas largas y saltos de página;
- tipografías y caracteres españoles;
- encabezados/pies;
- tiempo y memoria de generación;
- compatibilidad con el entorno de despliegue;
- facilidad de mantenimiento.

Preferencia inicial:
- **React-PDF** si el documento es estructurado, con tablas y estilos controlados, sin necesidad de reproducir HTML complejo.
- **Puppeteer** si el diseño requiere fidelidad exacta con componentes HTML/CSS existentes o plantillas visuales complejas.

En ambos casos, generar desde un snapshot de cotización y no desde datos vivos que puedan cambiar mientras se genera el PDF.

**Ventajas**

- La decisión se basa en un prototipo y no en preferencia personal.
- El snapshot garantiza consistencia histórica.
- Evita instalar un navegador headless si no aporta valor.

**Costos y riesgos**

- React-PDF puede requerir trabajo extra para layouts complejos.
- Puppeteer puede elevar consumo de memoria y complejidad operativa.

**Alternativa**

Elegir React-PDF directamente para reducir infraestructura. Es una decisión razonable si el diseño final es sencillo.

**Aprobación necesaria:** antes de desarrollar la exportación definitiva.

## DEC-017 — Patrón de autenticación Auth0 con Next.js

**Situación**

El SAD deja pendiente el patrón de sesión. Auth0 será la fuente de autenticación; ProveeEventos mantiene autorización interna y no almacena contraseñas locales.

**Propuesta recomendada**

Usar un flujo de sesión gestionada en servidor (BFF/session pattern) con cookies:
- `HttpOnly`;
- `Secure` en producción;
- `SameSite` apropiado al flujo;
- expiración y renovación controladas;
- protección CSRF para operaciones mutables cuando corresponda;
- tokens de acceso no expuestos a JavaScript del navegador ni guardados en `localStorage`;
- API valida issuer, audience, firma y expiración;
- roles y tenant se resuelven en backend desde la base de datos, no desde datos arbitrarios del cliente.

La elección concreta debe seguir el SDK y las recomendaciones vigentes de Auth0/Next.js en el momento de implementación.

**Ventajas**

- Reduce exposición de tokens ante XSS.
- Centraliza sesión y renovación.
- Mantiene separadas autenticación y autorización multi-tenant.

**Costos y riesgos**

- Requiere configurar correctamente cookies, dominios y CSRF.
- El despliegue frontend/backend debe coordinar dominios y callbacks.

**Alternativa**

SPA con tokens en memoria. Puede ser válida en ciertas arquitecturas, pero no recomiendo `localStorage` para tokens de sesión.

**Aprobación necesaria:** antes de implementar login y proteger rutas.

## DEC-018 — Historial, snapshots y propiedad de los datos históricos

**Situación**

El DDD establece que cambios futuros en paquetes o plantillas no deben modificar cotizaciones y contrataciones anteriores. También se requiere trazabilidad de adjudicaciones y ofertas.

**Propuesta recomendada**

Adoptar snapshots inmutables para los datos que constituyen una decisión comercial:
- nombre y descripción del paquete;
- precio y desglose;
- alcance, inclusiones y exclusiones;
- impuestos/configuración fiscal aplicada;
- porcentaje y base de comisión;
- proveedor y datos comerciales mínimos;
- condiciones aceptadas;
- versión de la oferta adjudicada;
- fecha/hora y actor que confirmó.

Las entidades vivas pueden cambiar, pero el snapshot histórico no. Si hay una corrección, se registra un nuevo evento o documento rectificativo, nunca se sobrescribe el acuerdo original.

**Ventajas**

- Permite explicar qué aceptó cada parte.
- Evita que una edición del catálogo cambie reservas ya confirmadas.
- Facilita soporte, auditoría, reportes y futuras integraciones de pago.
- Refuerza la separación entre oferta, adjudicación y Booking.

**Costos y riesgos**

- Duplica algunos datos intencionalmente.
- Requiere definir qué campos exactos se congelan.
- Los datos personales incluidos en snapshots también deben respetar retención y minimización.

**Alternativa**

Guardar solo referencias a paquetes y ofertas actuales. Es más compacto, pero rompe la trazabilidad si los datos originales cambian o se eliminan.

**Aprobación necesaria:** antes del diseño físico de base de datos y Prisma.

---

# 4b. Decisiones derivadas de las revisiones del paquete (Review V1, V2 y V3)

Estas decisiones surgen de `Reviews/Review_V1.md` (DEC-019..033, TEC-006..011, aplicadas mediante `Plans/Plan0001.md`), de `Reviews/Review_V2.md` (DEC-034, TEC-012 y ampliación de TEC-011, aplicadas mediante `Plans/Plan0003.md`) y de `Reviews/Review_V3.md` (DEC-035..037, aplicadas mediante `Plans/Plan0004.md`). **Estado de todas: Aprobada (23 de noviembre de 2026),** con la propuesta recomendada de cada una. Las validaciones profesionales indicadas (contable y tributaria para DEC-027 y DEC-033; legal para la privacidad, incluidos los plazos de DEC-037) siguen siendo necesarias antes de operar con datos y cobros reales. Mientras estuvieron pendientes, los documentos las citaban con la marca "pendiente"; esa marca se retiró al aprobarlas.

## DEC-019 — Jerarquía documental y PRD consolidado

**Situación:** el PRD disponible (v1.0) no contiene Instant Book, e-RFQ, Magic Link, SLA, Bid Tabulation, subtipos ni la taxonomía de 21 categorías. SRS, SAD y DDD derivan de un "PRD v2.2" que no estaba en el repositorio, y la regla de prevalencia daba prioridad al documento desactualizado.

**Propuesta recomendada:** publicar `ProveeEventos_PRD.md` como **v2.2 consolidada**, con el alcance real del SRS y las decisiones aprobadas. Se mantiene la jerarquía PRD > SRS > SAD > DDD > API > Decisiones: el PRD define qué y por qué; el SRS, el comportamiento verificable. El historial declara que las versiones 2.0–2.1 no se conservaron.

**Ventajas:** las referencias existentes a "PRD v2.2" pasan a ser válidas; la regla de prevalencia vuelve a funcionar; el backlog tiene una fuente de producto completa.

**Costos y riesgos:** hay que revisar el PRD con producto; mantener PRD y SRS sincronizados exige disciplina.

**Alternativa:** declarar el SRS como fuente normativa del alcance y relegar el PRD a visión. Es más rápido, pero deja el PRD obsoleto como referencia de negocio.

**Aprobación necesaria:** antes de generar el backlog.

## DEC-020 — Taxonomía y códigos de categoría

**Situación:** el PRD define 17 categorías (`CAT-17 = Otros`) y el SRS 21 (`CAT-17 = Bar, Coctelería y Bebidas`, `CAT-21 = Otros`). Además, los subtipos iniciales no están definidos en ningún documento.

**Propuesta recomendada:** adoptar las 21 categorías del SRS-CAT-003 con códigos estables `CAT-01`..`CAT-21`; nunca reutilizar un código; fijar los subtipos iniciales con código `CAT-xx-NN` en el Anexo B del PRD v2.2.

**Ventajas:** una sola taxonomía; datos semilla listos; filtros por subtipo implementables.

**Costos y riesgos:** los subtipos iniciales son una propuesta que debe validarse con proveedores reales durante el piloto.

**Alternativa:** volver a 17 categorías; perdería servicios relevantes (bar, staffing, infraestructura, merchandising).

**Aprobación necesaria:** antes de cargar datos semilla.

## DEC-021 — Entregas del MVP (E1 piloto y E2)

**Situación:** el plan de 12 semanas del PRD cubría el alcance de la v1.0; el SRS añade Instant Book con capacidad en dos niveles, e-RFQ con SLA, Magic Link, Bid Tabulation, WhatsApp asistido, cancelación por etapas, cierre con comisión, verificación por niveles, outbox y RPO ≤ 1 h.

**Propuesta recomendada:**
- **E1 (piloto):** identidad, empresas y membresías; catálogo y verificación niveles 1–2; eventos y plantillas; cotización rápida e integral; e-RFQ por email con Magic Link y SLA; Bid Tabulation; adjudicación con capacidad global; cancelación y cierre de servicio; seguimiento en tabla; PDF; reseñas; notificaciones; administración básica.
- **E2:** Instant Book; capacidad por paquete; asistente WhatsApp con IA asistida y Click-to-Chat; verificación nivel 3; transferencia de propiedad.
- La plantilla WhatsApp y Click-to-Chat pueden adelantarse a E1 si hay capacidad.

**Ventajas:** plan realista; valida primero la propuesta central (comparar ofertas firmes) antes de invertir en Instant Book, que exige tarifas vinculantes que los freelance quizá no publiquen.

**Costos y riesgos:** el diferencial de "reserva inmediata" llega más tarde; hay que comunicarlo en el piloto.

**Alternativa:** mantener el MVP completo con un plazo mayor (aproximadamente 22 semanas) y sin piloto intermedio.

**Aprobación necesaria:** antes de planificar sprints. Es una decisión de negocio.

## DEC-022 — Idioma de enums y vocabulario de roles

**Situación:** conviven `BOTH`/`AMBOS`, `CANCELLED`/`CANCELADO`, `ON_HOLD`, y tres vocabularios de roles (`ADMIN_EMPRESA`/`COORDINADOR`, `OWNER`/`ADMIN`/`COORDINATOR` y `COORDINATOR_RESTRINGIDO`).

**Propuesta recomendada:**
- **Estados y roles de negocio:** en español, MAYÚSCULAS, sin tildes ni espacios.
- **Códigos técnicos establecidos que se conservan:** modalidad, canal y origen (`INSTANT_BOOK`, `E_RFQ`, `EMAIL_FORM`, `WHATSAPP`, `AMBOS`, `EMAIL_MAGIC_LINK`, `PORTAL_PROVEEDOR`, `WHATSAPP_IA_ASISTIDO`).
- **Eventos de dominio:** siguen en inglés, porque son nombres de código.
- **Vocabulario único de roles:**
  - de membresía: `PROPIETARIO`, `ADMIN_EMPRESA`, `COORDINADOR`, `COORDINADOR_RESTRINGIDO`;
  - globales: `PROVEEDOR`, `ADMIN_PLATAFORMA`.
- **Valores reemplazados:**
  - `OWNER`/`ADMIN`/`COORDINATOR`/`COORDINATOR_RESTRINGIDO`;
  - `BOTH`;
  - `CANCELLED` y `CANCELLATION_REVIEW`;
  - `ON_HOLD` como valor de estado, que pasa a `RETENIDA`.

**Ventajas:** un solo vocabulario en SRS, API, base de datos y UI; sin mapeos ad hoc.

**Costos y riesgos:** cambia valores que aparecían en decisiones aprobadas (DEC-001, DEC-002, DEC-008); su semántica no cambia.

**Alternativa:** todos los códigos en inglés con etiquetas en español en la UI; exigiría traducir los estados existentes del SRS.

**Aprobación necesaria:** antes del esquema físico y del contrato API v1.1.

## DEC-023 — Máquina de estados de la contratación (Booking) y de la comisión

**Situación:** no existía máquina de estados de `Booking`; la API tenía estados sin "servicio realizado pendiente de confirmación" ni "incidencia", y no estaba definida la relación con el estado del ítem y de la comisión.

**Propuesta recomendada:**
- **Booking:**
  - `CONFIRMADO` → `CANCELACION_SOLICITADA`;
  - `CANCELACION_SOLICITADA` → `CANCELADO` (la contraparte acepta), → `CANCELACION_EN_REVISION` (disputa, o 72 h sin respuesta) o → `CONFIRMADO` (el solicitante retira la solicitud);
  - `CANCELACION_EN_REVISION` → `CANCELADO` o `CONFIRMADO` (resuelve la administración);
  - `CONFIRMADO` → `EN_PROGRESO` (al llegar el inicio local del servicio; job);
  - `CONFIRMADO` o `EN_PROGRESO` → `SERVICIO_REALIZADO` (lo marca el proveedor);
  - `SERVICIO_REALIZADO` → `COMPLETADO` (el organizador confirma, o 5 días sin incidencia) o → `INCIDENCIA` (el organizador reporta);
  - `INCIDENCIA` → `COMPLETADO` o `NO_PRESTADO` (resuelve la administración);
  - terminales: `CANCELADO`, `COMPLETADO`, `NO_PRESTADO`.
- **Capacidad:** se consume en todos los estados salvo `CANCELADO` y `NO_PRESTADO`.
- **Comisión (`CommissionStatus`):**
  - `PENDIENTE` (desde `CONFIRMADO` hasta `SERVICIO_REALIZADO`);
  - `RETENIDA` (`INCIDENCIA`);
  - `DEVENGADA` (`COMPLETADO`);
  - `NO_APLICA` (`CANCELADO` o `NO_PRESTADO`);
  - `REVERTIDA` (corrección auditada).
- **Estado del ítem:**
  - `CONFIRMADO` ↔ Booking `CONFIRMADO` o `CANCELACION_*`;
  - `EN_PROGRESO` ↔ `EN_PROGRESO`, `SERVICIO_REALIZADO` o `INCIDENCIA`;
  - `COMPLETADO` ↔ `COMPLETADO`;
  - `CALIFICADO` cuando existe reseña;
  - estado interno `CANCELADO` ↔ `CANCELADO` o `NO_PRESTADO`.

**Ventajas:** cancelación, cierre, comisión, reseñas y seguimiento usan un mismo ciclo; la capacidad se libera solo con decisiones claras.

**Costos y riesgos:** más estados que probar; los plazos (72 h, 5 días) son operativos y se calibrarán en el piloto.

**Alternativa:** estados mínimos (`CONFIRMADO`, `CANCELADO`, `COMPLETADO`) con banderas; oculta los casos de disputa.

**Aprobación necesaria:** antes de implementar cancelación y cierre.

## DEC-024 — Editar o cancelar un evento con compromisos

**Situación:** la edición permitía cambiar fecha, invitados y ubicación con reservas confirmadas o RFQ abiertas, sin reglas sobre la capacidad consumida, los precios congelados ni los Magic Links vigentes.

**Propuesta recomendada:**
- **Con reservas activas** (no terminales):
  - no se permite cambiar fecha, zona u horario por edición; se cancelan los compromisos afectados (DEC-001) o se clona el evento;
  - cambiar invitados o ubicación no altera los precios congelados; si afecta un precio por persona o el alcance, se registra una *modificación propuesta* que la contraparte acepta (SRS-BOOK-005).
- **Con RFQ abiertas:** cambiar fecha, ubicación o invitados revoca las solicitudes abiertas (estado `CANCELADO`, Magic Links invalidados), invalida las ofertas no adjudicadas (`INVALIDADA`) y avisa al proveedor; el organizador puede lanzar una nueva ronda.
- **Cancelar el evento:**
  - solo si ninguna reserva está en `EN_PROGRESO` o un estado posterior;
  - revoca las RFQ abiertas e inicia `CANCELACION_SOLICITADA` en cada reserva `CONFIRMADO`;
  - el evento pasa a `CANCELADO` de inmediato y las reservas siguen su ciclo DEC-001; la capacidad se libera por reserva.

**Ventajas:** evita capacidad consumida en fechas incorrectas y ofertas basadas en datos obsoletos.

**Costos y riesgos:** más fricción para el organizador al reprogramar; requiere mensajes claros en la UI.

**Alternativa:** permitir la edición libre y marcar las ofertas como "desactualizadas"; deja la decisión al usuario, pero mantiene la capacidad en la fecha anterior.

**Aprobación necesaria:** antes de implementar la edición de eventos.

## DEC-025 — Capacidad para eventos de varios días o que cruzan medianoche

**Situación:** DEC-007 remite a "una regla aprobada para servicios que cruzan medianoche" que no existía.

**Propuesta recomendada:** una reserva consume capacidad en **cada fecha local** (zona del evento) que toca el intervalo del servicio, que por defecto es el intervalo del evento. Excepción: si el servicio cruza medianoche y termina a las 06:00 locales o antes del día siguiente, consume solo la fecha de inicio.

Ejemplos:
- viernes 20:00 a sábado 03:00 consume el viernes;
- viernes 18:00 a domingo 14:00 consume viernes, sábado y domingo.

**Ventajas:** regla simple y predecible, coherente con el límite diario.

**Costos y riesgos:** el umbral de las 06:00 es arbitrario y se revisará con datos del piloto.

**Alternativa:** consumir solo la fecha de inicio siempre; subestima la ocupación en eventos de varios días.

**Aprobación necesaria:** antes de implementar la capacidad.

## DEC-026 — Reapertura de solicitudes e-RFQ, revocación y ofertas vencidas

**Situación:** SRS-RFQ-007 permitía "reabrir" una solicitud vencida, mientras SRS §9.2 y el DDD prohibían reabrir estados terminales. No existían revocación, reenvío ni tratamiento de ofertas con vigencia vencida.

**Propuesta recomendada:**
- No se reabren estados terminales. Para pedir de nuevo una oferta, incluso al mismo proveedor, se crea una nueva ronda `RfqCycle` (máximo 5 invitados por ronda).
- Se añade el estado `CANCELADO`, por revocación del organizador, edición del evento o administración.
- `ERROR_ENVIO` admite reintento (→ `PENDIENTE_ENVIO`) hasta 3 veces, o cancelación.
- Una oferta con vigencia vencida no es adjudicable: aparece en Bid Tabulation como "vencida" y el proveedor puede crear una revisión con nueva vigencia mientras la solicitud siga abierta.

**Ventajas:** estados terminales estables, auditoría simple, sin tokens reactivados.

**Costos y riesgos:** reinvitar crea una nueva solicitud y un nuevo Magic Link (ligeramente más pasos).

**Alternativa:** permitir la reapertura con un token nuevo; complica la máquina de estados y la auditoría.

**Aprobación necesaria:** antes de implementar e-RFQ.

## DEC-027 — Comisión: quién la paga y sobre qué base

**Situación:** el PRD fija una comisión del 3 % "sobre contrataciones cerradas", pero no define quién la paga ni su base (con o sin impuestos, con o sin extras).

**Propuesta recomendada:** la comisión la paga la **empresa organizadora**. La base es el precio acordado del servicio, incluidos los extras aceptados, **antes de impuestos**. El porcentaje inicial es del 3 %, versionado y congelado en el snapshot de la contratación (DEC-010, DEC-018).

**Ventajas:** coherente con la cotización integral, que muestra la comisión en el total del organizador (RF-INT-03); no grava impuestos de terceros.

**Costos y riesgos:** requiere validación contable y tributaria; puede afectar la adopción si el organizador percibe un sobrecosto.

**Alternativa:** comisión a cargo del proveedor, descontada de su precio; reduce la fricción del organizador pero exige acuerdo comercial con cada proveedor.

**Aprobación necesaria:** antes de formalizar comisiones o emitir documentos.

## DEC-028 — Revelación de datos de contacto del proveedor

**Situación:** SRS §7.3 dice que el contacto "no se expondrá antes del momento de negocio definido", pero ese momento no estaba definido; es central para el riesgo de contratación por fuera (R5).

**Propuesta recomendada:** el teléfono, WhatsApp y email directos del proveedor no aparecen en el perfil público ni en los resultados. Se revelan a la empresa:
- (a) dentro del enlace `wa.me` generado para una RFQ enviada a ese proveedor, con registro en auditoría;
- (b) tras una reserva confirmada o una adjudicación.

**Ventajas:** protege el modelo de comisión y los datos personales del proveedor.

**Costos y riesgos:** algunos organizadores lo verán como fricción; el contacto puede filtrarse por otros medios.

**Alternativa:** contacto visible para empresas registradas; maximiza la conversión, pero facilita contratar por fuera.

**Aprobación necesaria:** antes de publicar el catálogo.

## DEC-029 — Planes, periodo de prueba y comportamiento ante límites

**Situación:** SRS-TEN-003 exige validar límites del plan, pero no había plan de prueba (el riesgo R1 proponía 3 meses gratis), ni gestión de planes, ni comportamiento al exceder un límite o al vencer el plan.

**Propuesta recomendada:**
- Planes `PRUEBA` (90 días, límites del plan Pro), `BASICO`, `PRO` y `ENTERPRISE`, configurables como datos con vigencia.
- Al alcanzar un límite se rechaza crear el recurso con `PLAN_LIMIT_REACHED`; nunca se bloquean operaciones sobre compromisos existentes.
- Con el plan vencido, la cuenta queda en solo lectura para nuevas operaciones, pero puede gestionar sus reservas y RFQ existentes.
- `ADMIN_PLATAFORMA` asigna y cambia los planes.

**Ventajas:** reduce la barrera de entrada; nunca deja compromisos huérfanos.

**Costos y riesgos:** requiere un proceso manual de cobro (DEC-033) y de seguimiento de vencimientos.

**Alternativa:** plan gratuito permanente con límites bajos; complica la conversión.

**Aprobación necesaria:** antes de abrir el registro de empresas.

## DEC-030 — Reseñas: ventana, edición, visibilidad y reporte

**Situación:** no estaban definidos el plazo para calificar, si la reseña es editable, si identifica a la empresa ni quién puede reportarla.

**Propuesta recomendada:**
- Ventana de 30 días desde que la contratación queda `COMPLETADO`.
- La reseña no es editable; las correcciones van por moderación.
- Muestra el nombre comercial de la empresa autora (PRD RF-CAL-03).
- La pueden reportar el proveedor afectado y `ADMIN_PLATAFORMA`, con motivo de una lista cerrada (`OFENSIVO`, `FALSO`, `DATOS_PERSONALES`, `OTRO`).

**Ventajas:** reputación estable y trazable; reduce manipulación.

**Costos y riesgos:** las empresas pueden ser reacias a firmar reseñas negativas.

**Alternativa:** reseñas anónimas para el público con autor visible solo para la administración.

**Aprobación necesaria:** antes de habilitar reseñas.

## DEC-031 — Verificación y suspensión como dimensiones ortogonales

**Situación:** SRS y DDD usaban un solo ciclo con `SUSPENDIDO` dentro de la verificación, mientras la API separaba la verificación del estado de cuenta.

**Propuesta recomendada:**
- `verificationStatus`: `PENDIENTE`, `VERIFICADO`, `RECHAZADO`.
- `accountStatus`: `ACTIVO`, `SUSPENDIDO`.
- Visible en catálogo = `VERIFICADO` ∧ `ACTIVO` ∧ perfil publicable.
- La suspensión no borra el resultado de la verificación; la reactivación restaura la visibilidad sin repetir la verificación.

**Ventajas:** modela correctamente suspender a un proveedor pendiente o reactivar sin perder la verificación.

**Costos y riesgos:** dos campos en lugar de uno.

**Alternativa:** ciclo único con `SUSPENDIDO`; pierde el estado de verificación previo.

**Aprobación necesaria:** antes del esquema físico.

## DEC-032 — Redondeo de importes en COP

**Situación:** el schema `Money` admitía dos decimales sin regla de redondeo para precio por persona × invitados, comisión e impuestos.

**Propuesta recomendada:** cálculo interno con `NUMERIC(14,2)`; redondeo *half-up* al peso entero por línea al presentar y al congelar el snapshot; subtotales y comisión se calculan sobre las líneas redondeadas; los importes se presentan sin centavos.

**Ventajas:** totales reproducibles entre pantalla, PDF y snapshot.

**Costos y riesgos:** pequeñas diferencias frente a cálculos sin redondeo por línea.

**Alternativa:** redondear solo el total; las líneas mostradas pueden no sumar el total.

**Aprobación necesaria:** antes de implementar la cotización.

## DEC-033 — Proceso de cobro en el MVP

**Situación:** el MVP no procesa pagos, pero las suscripciones y la comisión del 3 % generan ingresos y ProveeEventos debe facturarlos.

**Propuesta recomendada:**
1. Mensualmente, `ADMIN_PLATAFORMA` exporta las comisiones `DEVENGADA` y las suscripciones activas.
2. ProveeEventos factura fuera del sistema mediante un proveedor de facturación electrónica habilitado ante la DIAN.
3. Los pagos se concilian manualmente y su referencia se registra en la plataforma.

**Ventajas:** permite operar el piloto sin pasarela de pagos.

**Costos y riesgos:** trabajo manual; requiere validación contable y tributaria profesional en Colombia.

**Alternativa:** integrar la pasarela antes (Fase 3 adelantada).

**Aprobación necesaria:** antes del primer ciclo de facturación.

## DEC-034 — Suspensión de un proveedor con contrataciones futuras

**Situación:** SRS-ADM-005 y SRS-AUTH-007 definen que la suspensión bloquea operaciones nuevas y conserva el historial, pero no qué ocurre con las contrataciones ya confirmadas cuya fecha aún no llega (Review V2, F-05). Suspender a un proveedor con agenda cargada dejaba el comportamiento sin definir.

**Propuesta recomendada:**
1. La suspensión bloquea de inmediato: aparición en el catálogo, nuevas solicitudes e-RFQ, respuestas a solicitudes abiertas (sus Magic Links se invalidan), ofertas y reservas Instant Book.
2. Las solicitudes e-RFQ abiertas del proveedor pasan a `CANCELADO` por revocación (SRS-RFQ-013) y sus ofertas no adjudicadas a `INVALIDADA`.
3. Cada contratación `CONFIRMADO` o `CANCELACION_SOLICITADA` con inicio futuro pasa a `CANCELACION_EN_REVISION` con origen "plataforma" y motivo de la suspensión. La organizadora recibe aviso y elige, dentro de 72 h, mantener la contratación (vuelve a `CONFIRMADO`; requiere que la administración confirme que el proveedor puede prestar el servicio) o cancelarla; sin respuesta, la administración resuelve.
4. Las contrataciones `EN_PROGRESO` o posteriores siguen su ciclo normal; el cierre y la comisión no cambian.
5. La capacidad solo se libera cuando la contratación termina en `CANCELADO` (`ReleaseBookingCapacity`). No hay penalidades ni reembolsos automáticos (DEC-001).
6. Todo queda auditado con actor, motivo y contrataciones afectadas.

**Alternativas:**
- Cancelar automáticamente todas las contrataciones futuras: simple, pero deja a la organizadora sin servicio sin consultarla.
- No tocar las contrataciones: la organizadora descubre el problema tarde.

**Ventajas:** la organizadora decide con información; no se libera capacidad ni se pierde evidencia sin una decisión explícita.

**Costos y riesgos:** carga administrativa si se suspende a un proveedor con muchas contrataciones; requiere plantilla de aviso (Plan0002, matriz de notificaciones).

**Aprobación necesaria:** antes de habilitar la suspensión de proveedores en el piloto (E1).

**Estado:** Aprobada (23 de noviembre de 2026).

## TEC-006 — Organización activa (tenant activo)

**Situación:** un usuario puede tener varias membresías, pero la API usaba `/organizations/current` sin mecanismo para elegir la empresa activa.

**Propuesta recomendada:** el BFF guarda en la sesión la organización activa y la envía como `X-Organization-Id`. La API valida que exista una membresía activa. Sin cabecera: si el usuario tiene una sola membresía, se usa esa; si tiene varias, `400 ORGANIZATION_REQUIRED`.

**Ventajas:** contexto de tenant explícito y validado en cada petición.

**Costos y riesgos:** el BFF debe ofrecer un selector de organización.

**Alternativa:** organización en la ruta (`/organizations/{id}/...`); rutas más largas.

**Aprobación necesaria:** antes del contrato API v1.1.

## TEC-007 — Registro autenticado

**Situación:** `POST /organizations` y `POST /providers` eran anónimos y recibían el email en el cuerpo; sin identidad autenticada no hay `auth0_id` que vincular, y cualquiera podía registrar empresas a nombre de terceros.

**Propuesta recomendada:**
- Ambos endpoints exigen un token Auth0 válido de un usuario sin membresía ni perfil.
- El email se toma del token y debe estar verificado para activar la cuenta.
- El signup de Auth0 incluye protección anti-bot.
- Las disputas de NIT las verifica soporte y la reasignación queda auditada.

**Ventajas:** vínculo identidad ↔ usuario inequívoco; evita la usurpación.

**Costos y riesgos:** flujo de dos pasos (signup en Auth0, luego registro de la empresa).

**Alternativa:** Auth0 Actions que crean el usuario interno en el post-registro; acopla la lógica al IdP.

**Aprobación necesaria:** antes del contrato API v1.1.

## TEC-008 — Magic Link sin token en el path

**Situación:** el token iba en la ruta (`/magic-links/{token}`), y las URL de acceso quedan en los logs de proxies y hosting, contra SRS-MAGIC-004. Además, los escáneres de correo abren los enlaces.

**Propuesta recomendada:** el correo enlaza a `https://<web>/r#<token>`. La página lee el fragmento, que no viaja al servidor, y llama `POST /magic-links/form` y `POST /magic-links/response` con el token en el cuerpo. Las aperturas por escáneres no cuentan como apertura.

**Ventajas:** el token no aparece en logs de acceso ni en el `Referer`.

**Costos y riesgos:** requiere JavaScript en la página del formulario.

**Alternativa:** canjear el token por una sesión de formulario de corta duración en la primera visita.

**Aprobación necesaria:** antes de implementar Magic Link.

## TEC-009 — Confirmación de compromisos única (`ConfirmBooking`)

**Situación:** la adjudicación e-RFQ creaba la contratación sin validar ni consumir la capacidad del proveedor, contra DEC-006 y SRS §4.4.

**Propuesta recomendada:** un solo caso de uso `ConfirmBooking(origin, terms, quantity, serviceInterval)`, usado por Instant Book y por la adjudicación dentro de la misma transacción:
1. asegurar la existencia de las filas de capacidad con `INSERT … ON CONFLICT DO NOTHING`;
2. bloquear con `SELECT … FOR UPDATE` en orden fijo: capacidad global por fecha, en orden ascendente, y luego la capacidad del paquete;
3. revalidar y consumir;
4. si no hay capacidad, `409 CAPACITY_EXHAUSTED` y la adjudicación no se produce.

**Ventajas:** una sola implementación del control de capacidad; evita interbloqueos y la sobreventa entre canales.

**Costos y riesgos:** la transacción de adjudicación es algo más larga.

**Alternativa:** dos implementaciones separadas; duplica la lógica crítica.

**Aprobación necesaria:** antes de implementar Booking y Award.

## TEC-010 — Alineación de módulos con los contextos del DDD

**Situación:** el SAD definía 11 módulos y el DDD 12 contextos, con carpetas distintas; nadie era dueño del seguimiento por ítem ni del registro de comisiones; la matriz de dependencias del SAD tenía un ciclo.

**Propuesta recomendada:**
- Los 12 contextos del DDD son los módulos del SAD, con los nombres de carpeta del DDD §16.1.
- El seguimiento del ítem es de `Quotation` (`QuotationItem.trackingStatus` más historial), actualizado por eventos de RFQ, Booking y Reviews.
- `CommissionRecord` es de `Availability & Booking`.
- La matriz de dependencias es acíclica.

**Ventajas:** un solo mapa de módulos; ownership claro; pruebas de arquitectura posibles.

**Costos y riesgos:** reorganizar el texto del SAD.

**Alternativa:** contexto separado "Item Tracking" y "Commission Ledger"; más módulos para el MVP.

**Aprobación necesaria:** antes de crear el repositorio backend.

## TEC-011 — Contrato de errores y concurrencia optimista

**Situación:** los errores solo tenían `code: string`; faltaban respuestas de error y `Idempotency-Key` en varias operaciones; los `PATCH` podían sobrescribirse entre usuarios.

**Propuesta recomendada:**
- Errores `application/problem+json` (RFC 9457) con `code` estable de un catálogo, más `correlationId`.
- `ETag`/`If-Match` en los `PATCH` de evento, cotización, paquete y plantilla (`412` si cambió).
- `Idempotency-Key` como componente reutilizable en toda creación repetible.

**Ventajas:** el frontend reacciona por código; sin pérdidas silenciosas de edición.

**Costos y riesgos:** más cabeceras que gestionar en el cliente.

**Alternativa:** campo `version` en el cuerpo en lugar de `ETag`.

**Ampliación (v1.2, Review V2):**
- `ETag`/`If-Match` también en el perfil del proveedor (`updateMyProvider`) y su disponibilidad (`setProviderAvailability`), que editan varios usuarios o pestañas y tienen riesgo de pérdida de edición (M-02).
- **Exenciones de `Idempotency-Key`** (M-01). Un `POST` puede omitirla solo si cumple una de estas condiciones, que se documenta en la operación:
  1. es un cálculo sin efecto persistente (p. ej. construir el enlace Click-to-Chat o generar el prompt del asistente);
  2. es idempotente por naturaleza (marcar como leída, marcar favorito, aceptar una invitación ya aceptada);
  3. se deduplica por un identificador del emisor (webhook de SendGrid por `sg_event_id`);
  4. está protegido por un consumo único transaccional (respuesta por Magic Link, cuyo token se consume una sola vez).

**Aprobación necesaria:** antes del contrato API v1.1.

## TEC-012 — Modelo de paginación de la API

**Situación:** el contrato v1.1.0 declaraba a la vez `page`/`pageSize` y `cursor`/`limit` en tres operaciones, y `PageMeta` mezclaba ambos modelos; además el catálogo público prometía un máximo de 50 resultados por página mientras el parámetro compartido permitía 100 (Review V2, E-07 y E-09).

**Propuesta recomendada:**
- **Paginación por página** (`page`, `pageSize` con máximo 100; respuesta `PageMeta` con `page`, `pageSize`, `totalItems`, `totalPages`) para colecciones acotadas del tenant o de administración.
- **Paginación por cursor** (`cursor` opaco, `limit`; respuesta `CursorPageMeta` con `limit` y `nextCursor`) para colecciones grandes o que cambian mientras se recorren: catálogo público (`limit` máximo 50), notificaciones y auditoría.
- Cada operación usa un solo modelo; combinar parámetros de ambos es un error `400 VALIDATION_FAILED`.
- El cursor codifica la clave de orden y el último identificador; es estable ante inserciones nuevas.

**Alternativas:** solo página (simple, pero costoso y con duplicados en colecciones que cambian); solo cursor (sin número total de páginas en los listados administrativos).

**Ventajas:** el cliente sabe qué modelo aplica; el límite público queda garantizado por el contrato.

**Costos y riesgos:** dos componentes de paginación en el frontend.

**Aprobación necesaria:** antes de generar clientes desde el contrato API v1.2.

**Estado:** Aprobada (23 de noviembre de 2026).

## DEC-035 — Cierre de una ronda e-RFQ sin adjudicación

**Situación:** el grafo del ítem (SRS §9.3) no define el destino cuando todas las solicitudes de una ronda terminan en `CANCELADO` sin ofertas, ni cuando se mezclan rechazos y revocaciones. Además, una solicitud `RESPONDIDO` no expira por SLA: si su oferta vence después del SLA, el proveedor ya no puede revisarla y la solicitud queda abierta indefinidamente, con el ítem en `ENVIADO` (Review V3, E-15 y M-28).

**Propuesta recomendada:**
1. Una solicitud está **abierta** en `PENDIENTE_ENVIO`, `ENVIADO`, `RESPONDIDO` o `ERROR_ENVIO` (este último admite reintento).
2. Una solicitud `RESPONDIDO` sin ninguna oferta `RECIBIDA` y con `sla_expira_at` vencido pasa a `NO_ADJUDICADO`. La condición se evalúa al vencer la oferta y al vencer el SLA. Mientras el SLA siga abierto, la solicitud permanece `RESPONDIDO` y el proveedor puede enviar una revisión.
3. Cuando el ítem no tiene solicitudes abiertas ni contratación, su estado es el primero que aplique:
   1. `CANCELADO`, si el evento se canceló;
   2. `NO_ADJUDICADO`, si en la última ronda se recibió alguna oferta;
   3. `EXPIRADO`, si alguna solicitud terminó en `EXPIRADO`;
   4. `RECHAZADO`, si alguna solicitud terminó en `RECHAZADO`;
   5. `COTIZADO`, si todas se revocaron sin ofertas (el ítem vuelve a estar listo para una nueva ronda).

**Alternativas:**
- Un estado interno nuevo (`SIN_RESPUESTA`) para la ronda revocada: más explícito, pero amplía todos los enums.
- Usar `NO_ADJUDICADO` para cualquier cierre sin adjudicación: simple, pero afirma que hubo ofertas cuando no las hubo.
- Dejar la solicitud respondida abierta hasta que el organizador la revoque: obliga a una limpieza manual.

**Ventajas:** ningún ítem queda atrapado; el estado describe lo ocurrido sin enums nuevos.

**Costos y riesgos:** volver a `COTIZADO` oculta en el estado que hubo una ronda revocada; el historial de transiciones la conserva.

**Aprobación necesaria:** antes de implementar el seguimiento del ítem (E1).

**Estado:** Aprobada (23 de noviembre de 2026).

## DEC-036 — Operación de la revisión por suspensión de proveedor

**Situación:** DEC-034 decide que la organizadora elige en 72 h mantener o cancelar, pero no cómo se registra la elección, qué pasa si el servicio empieza antes de las 72 h ni cuándo puede resolver la administración (Review V3, F-16). Además, un proveedor suspendido no puede operar (SRS-AUTH-007), así que las contrataciones que "siguen su ciclo normal" quedan sin quien las marque como realizadas, y una adjudicación concurrente con la suspensión podría crear una contratación que escape a la revisión.

**Propuesta recomendada:**
1. **Ventana de decisión:** termina en lo primero que ocurra entre 72 h después de la suspensión y el inicio local del servicio.
2. **Elección de la organizadora:** cancelar es definitivo y pasa la contratación a `CANCELADO`; mantener queda registrado, puede cambiarse a cancelar mientras la ventana siga abierta y el caso no esté resuelto, y la contratación sigue en `CANCELACION_EN_REVISION`.
3. **Administración:** resuelve cuando la organizadora eligió mantener o cuando la ventana se cerró sin respuesta. Antes, la resolución se rechaza. Al cerrarse la ventana, un job marca el caso como pendiente de la administración y le avisa; no cambia el estado.
4. **Proveedor suspendido:** conserva únicamente la consulta de sus contrataciones vigentes y las acciones de ciclo sobre las que sigan en curso (marcar servicio realizado, responder una cancelación). Todo lo demás permanece bloqueado.
5. **Concurrencia:** todos los efectos de la suspensión se aplican en una sola transacción; la suspensión bloquea la fila del proveedor (`FOR UPDATE`) y `ConfirmBooking` la bloquea en modo compartido (`FOR SHARE`) antes de las filas de capacidad. El orden pasa a ser ítem → proveedor → capacidad global → paquete.

**Alternativas:**
- Permitir que la administración resuelva en cualquier momento: más ágil ante un fraude, pero quita la decisión a la organizadora.
- Que la administración marque el servicio realizado en nombre del proveedor suspendido: evita darle acceso, pero añade carga operativa y debilita la evidencia.

**Ventajas:** el flujo aprobado queda implementable y sin carreras.

**Costos y riesgos:** permisos parciales para una cuenta suspendida, que requieren pruebas negativas; un bloqueo adicional en la confirmación.

**Aprobación necesaria:** antes de habilitar la suspensión de proveedores en el piloto (E1).

**Estado:** Aprobada (23 de noviembre de 2026).

## DEC-037 — Plazo provisional de las solicitudes de titulares

**Situación:** SRS-ADM-012 exige una fecha límite en la cola de solicitudes, pero difiere el plazo a la asesoría legal, así que la cola no se puede probar (Review V3, M-22).

**Propuesta recomendada:** usar como objetivo provisional los plazos máximos de la Ley 1581 de 2012:
- **consulta** (art. 14): 10 días hábiles desde el recibo, prorrogables hasta 5 días hábiles más;
- **reclamo**, es decir corrección o supresión (art. 15): 15 días hábiles desde el día siguiente al recibo, prorrogables hasta 8 días hábiles más;
- la prórroga exige informar al titular el motivo y la nueva fecha antes de que venza el primer plazo;
- los días hábiles usan un calendario de festivos de Colombia configurable.

La asesoría legal debe confirmar los plazos y los pasos intermedios de la ley (por ejemplo, el requerimiento al titular cuando el reclamo está incompleto) antes de operar con datos reales.

**Alternativas:** un único plazo de 15 días hábiles para todo (incumple el plazo de las consultas); no fijar ninguno (la cola no es verificable).

**Ventajas:** fecha límite calculable y probable desde E1.

**Costos y riesgos:** mantener el calendario de festivos; si la validación legal cambia los plazos, son datos de configuración.

**Aprobación necesaria:** con validación legal, antes de abrir el producto al público.

**Estado:** Aprobada (23 de noviembre de 2026). La validación legal no consta y sigue siendo necesaria antes de operar con datos reales.

---

## TEC-013 — Ampliación y corrección del contrato API (v1.4.0)

**Situación:** al especificar la interfaz (`ProveeEventos_UXUI.md`) se comprobó que el contrato v1.3.0 no permitía cumplir en pantalla varios requisitos ya definidos (lecturas ausentes, campos que se escriben y no se devuelven, gestión administrativa sin operaciones), que difería del modelo de datos en los puntos de TDD §4.6 y que siete esquemas compuestos heredaban `additionalProperties: false` de un cuerpo de petición, por lo que rechazaban datos legítimos (por ejemplo, una respuesta con `id`).

**Propuesta recomendada:** publicar el contrato 1.4.0 con:
- 28 operaciones nuevas, todas ligadas a requisitos del SRS o al PRD (`Trazabilidad.md`);
- campos de respuesta que faltaban en contratación, solicitud e-RFQ, perfil propio del proveedor, empresa, notificación, cotización y auditoría;
- correcciones de TDD §4.6 y composición de esquemas con una base `*Fields` y cuerpos cerrados con `unevaluatedProperties: false`.

**Elecciones incluidas que requieren confirmación:** (a) la disponibilidad pública solo informa `DISPONIBLE` o `SIN_CAPACIDAD`, sin cupos, con rango máximo de 62 días; (b) el contacto del proveedor se consulta mientras la contratación no esté `CANCELADO` ni `NO_PRESTADO`, auditado; (c) cualquiera de las partes propone una modificación y responde la contraparte, con una sola propuesta pendiente por contratación; (d) los planes se versionan por revisiones inmutables y los vigentes son públicos; (e) la organizadora ve el nombre del proveedor y el proveedor ve el nombre comercial de la empresa en la contratación.

**Alternativas:** mantener 1.3.0 y recortar la interfaz (incumple requisitos E1); componer los datos en el BFF (imposible cuando el dato no se expone).

**Ventajas:** la interfaz cubre los requisitos sin inventar datos; el contrato coincide con el modelo.

**Costos y riesgos:** cambios incompatibles con 1.3.0 (sin clientes publicados); hay que actualizar la trazabilidad API→tablas del TDD §4.6 y revisar que las composiciones respeten SAD §4.4.

**Aprobación necesaria:** antes de generar clientes desde el contrato API v1.4 e implementar sus operaciones.

**Estado:** Pendiente de aprobación.

# 5. Decisiones técnicas derivadas del SAD y DDD

Estas decisiones no cambian directamente la propuesta comercial, pero deben quedar confirmadas para evitar que el desarrollo avance con supuestos distintos.

## TEC-001 — Oferta como agregado independiente

**Propuesta:** mantener `Offer` como agregado separado de `RfqRequest`, con revisiones inmutables.

**Ventajas:** historial independiente, concurrencia más clara, cambios de oferta sin cargar el agregado de solicitud y mayor facilidad para auditar adjudicación.

**Costo:** más tablas y coordinación transaccional. La adjudicación debe seguir protegida por transacción y restricción única por ítem.

**Recomendación:** aprobar junto con DEC-005.

## TEC-002 — Rondas e-RFQ explícitas

**Propuesta:** introducir `RfqCycle` como agrupador de las solicitudes paralelas de una misma ronda para un ítem de cotización.

**Ventajas:** representa claramente el límite de 1–5 proveedores, el SLA común, las invitaciones y una eventual segunda ronda.

**Costo:** una entidad adicional y estados propios.

**Recomendación:** aprobar si se contempla reabrir o repetir rondas; para una única ronda simple puede mantenerse como agrupación lógica, pero el límite debe estar garantizado en base de datos.

## TEC-003 — Idempotencia y transacciones

**Propuesta:** exigir idempotencia para reserva instantánea, adjudicación y operaciones de creación que puedan repetirse por reintentos; proteger capacidad y ganador único con PostgreSQL.

**Ventajas:** evita reservas duplicadas y dobles adjudicaciones.

**Costo:** almacenamiento de claves, resultados y políticas de expiración.

**Recomendación:** decisión técnica obligatoria, no dejarla a criterio de cada endpoint.

## TEC-004 — Outbox transaccional

**Propuesta:** insertar eventos de salida en PostgreSQL dentro de la transacción de negocio y procesarlos con worker/BullMQ.

**Ventajas:** una reserva no queda confirmada sin que exista registro recuperable de las notificaciones pendientes.

**Costo:** requiere tabla outbox, worker idempotente y monitoreo.

**Recomendación:** adoptar en el MVP para reservas, adjudicaciones, RFQ y cambios de estado relevantes.

## TEC-005 — Aislamiento multi-tenant

**Propuesta:** resolver tenant desde membresía autenticada en backend; todos los repositorios/casos de uso que acceden a recursos de empresa exigen `organizationId`. Evaluar PostgreSQL Row Level Security como defensa adicional, no como sustituto de autorización.

**Ventajas:** reduce riesgo de exposición cruzada entre empresas.

**Costo:** disciplina de acceso a datos y pruebas negativas sistemáticas.

**Recomendación:** obligatorio desde la primera migración.

---

# 6. Orden recomendado de aprobación

No todas las decisiones tienen que resolverse el mismo día. Este orden minimiza retrabajo:

## Antes de cerrar el modelo de datos

1. DEC-006 — Capacidad por proveedor/paquete.
2. DEC-007 — Zona horaria y fechas.
3. DEC-008 — Administradores y membresías.
4. DEC-005 — Versionado de ofertas.
5. DEC-010 — Datos fiscales y snapshots.
6. DEC-018 — Historial y snapshots.
7. TEC-001 y TEC-002 — Modelo RFQ/Offer.

## Antes de implementar los flujos transaccionales

1. DEC-001 — Cancelaciones.
2. DEC-002 — Devengo de comisión.
3. TEC-003 — Idempotencia.
4. TEC-004 — Outbox.
5. DEC-011 — Permisos de coordinador.

## Antes de abrir el producto al público

1. DEC-009 — Verificación de proveedores.
2. DEC-003 — Retención y eliminación.
3. DEC-010 — Tratamiento fiscal.
4. DEC-013 y DEC-014 — Hosting, región y residencia.
5. DEC-012 — RPO/RTO.
6. DEC-017 — Sesión y autenticación.

## Puede decidirse durante el piloto

- DEC-004 — Ajuste fino de pesos del ranking, manteniendo desde el principio una fórmula inicial explicable.
- DEC-015 — Alcance exacto de mapas.
- DEC-016 — Motor de PDF, después del prototipo.
- Ajustes a ventanas de confirmación y recordatorios, con métricas del piloto.

TEC-005 (aislamiento multi-tenant) quedó aprobada junto con TEC-001..004 (§7) y se aplica desde el inicio del modelo de datos.

## Decisiones de la sección 4b y ADR-016..022 del SAD

Orden recomendado de aprobación de las decisiones derivadas de Review V1 y Review V2. Todas se aprobaron el 23 de noviembre de 2026; la lista se conserva como referencia de qué hito depende de cada una. Para decisiones futuras, si una propuesta se rechaza, se corrigen los documentos que la citan (`grep -n "<ID>" *.md *.yaml`) antes de continuar.

**1. Antes de iniciar el modelo de datos y la entrega E1:**
1. DEC-019 — Jerarquía documental y PRD consolidado.
2. DEC-021 — Entregas E1/E2.
3. DEC-022 — Idioma de enums y vocabulario de roles.
4. TEC-010 y ADR-022 — Doce módulos alineados con el DDD.
5. DEC-023 — Estados de contratación y comisión.
6. DEC-025 y ADR-016 — Capacidad diaria y eventos de varios días.
7. DEC-026 — RFQ sin reapertura, revocación y ofertas vencidas.
8. DEC-031 — Verificación y cuenta como dimensiones independientes.
9. DEC-032 — Redondeo de COP.
10. TEC-009, ADR-017 y ADR-019 — `ConfirmBooking`, bloqueo y snapshot de contratación.
11. ADR-020 — Proyecciones reconstruibles.
12. ADR-018 — Row-Level Security como defensa en profundidad.

**2. Antes de cerrar el contrato API y generar clientes:**
1. TEC-006 — Organización activa.
2. TEC-007 — Registro autenticado.
3. TEC-008 y ADR-021 — Magic Link con token en el fragmento.
4. TEC-011 — Errores, concurrencia optimista e idempotencia.
5. TEC-012 — Paginación.

**3. Antes de cargar datos semilla y abrir el piloto:**
1. DEC-020 — Taxonomía de 21 categorías.
2. DEC-024 — Eventos con compromisos.
3. DEC-028 — Revelación de contacto.
4. DEC-029 — Planes, prueba y límites.
5. DEC-030 — Reseñas.
6. DEC-034 — Suspensión con contrataciones futuras.

**4. Con validación profesional (legal, contable o tributaria) en Colombia:**
1. DEC-027 — Pagador y base de la comisión.
2. DEC-033 — Proceso de cobro en el MVP.

## Decisiones de Review V3 (DEC-035..037)

Aprobadas; la lista se conserva como referencia de qué hito depende de cada una:
1. DEC-035 — antes de modelar el seguimiento del ítem y las solicitudes e-RFQ (E1).
2. DEC-036 — antes de modelar la contratación y habilitar la suspensión de proveedores (E1).
3. DEC-037 — validación legal antes de operar con datos personales reales.

## Propuesta pendiente (contrato 1.4.0)

- TEC-013 — antes de generar clientes e implementar las operaciones nuevas del contrato.

---

# 7. Registro de aprobación

Registro de la revisión de producto del 23 de noviembre de 2026: para DEC-001..018 y TEC-001..005 se adoptó la **propuesta recomendada** descrita en este documento. Las decisiones de la sección 4b (DEC-019..034 y TEC-006..012) y los ADR-016..022 del SAD se aprobaron el 23 de noviembre de 2026 con su propuesta recomendada; el responsable de cada una queda por asignar. DEC-035..037 se aprobaron con la misma fecha y su propuesta recomendada; la validación legal de DEC-037 sigue siendo necesaria antes de operar con datos reales.

| ID | Decisión final | Responsable | Fecha | Estado |
|---|---|---|---|---|
| DEC-001 | Propuesta recomendada adoptada | Producto + Legal | 23 de noviembre de 2026 | Aprobada |
| DEC-002 | Propuesta recomendada adoptada | Producto + Finanzas | 23 de noviembre de 2026 | Aprobada |
| DEC-003 | Propuesta recomendada adoptada | Producto + Legal/Privacidad | 23 de noviembre de 2026 | Aprobada |
| DEC-004 | Propuesta recomendada adoptada | Producto + Datos | 23 de noviembre de 2026 | Aprobada |
| DEC-005 | Propuesta recomendada adoptada | Producto + Arquitectura | 23 de noviembre de 2026 | Aprobada |
| DEC-006 | Propuesta recomendada adoptada | Producto + Operaciones | 23 de noviembre de 2026 | Aprobada |
| DEC-007 | Propuesta recomendada adoptada | Producto + Arquitectura | 23 de noviembre de 2026 | Aprobada |
| DEC-008 | Propuesta recomendada adoptada | Producto | 23 de noviembre de 2026 | Aprobada |
| DEC-009 | Propuesta recomendada adoptada | Operaciones + Legal | 23 de noviembre de 2026 | Aprobada |
| DEC-010 | Propuesta recomendada adoptada | Finanzas + Contabilidad/Legal | 23 de noviembre de 2026 | Aprobada |
| DEC-011 | Propuesta recomendada adoptada | Producto + Seguridad | 23 de noviembre de 2026 | Aprobada |
| DEC-012 | Propuesta recomendada adoptada | Producto + DevOps | 23 de noviembre de 2026 | Aprobada |
| DEC-013 | Propuesta recomendada adoptada | Arquitectura + DevOps | 23 de noviembre de 2026 | Aprobada |
| DEC-014 | Propuesta recomendada adoptada | Legal/Privacidad + DevOps | 23 de noviembre de 2026 | Aprobada |
| DEC-015 | Propuesta recomendada adoptada | Producto + DevOps | 23 de noviembre de 2026 | Aprobada |
| DEC-016 | Propuesta recomendada adoptada | Arquitectura + UX | 23 de noviembre de 2026 | Aprobada |
| DEC-017 | Propuesta recomendada adoptada | Arquitectura + Seguridad | 23 de noviembre de 2026 | Aprobada |
| DEC-018 | Propuesta recomendada adoptada | Producto + Arquitectura | 23 de noviembre de 2026 | Aprobada |
| TEC-001–005 | Propuesta recomendada adoptada | Arquitectura | 23 de noviembre de 2026 | Aprobada |
| DEC-019 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-020 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-021 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-022 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-023 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-024 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-025 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-026 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-027 | Propuesta recomendada adoptada (sección 4b); requiere validación contable/tributaria | Por asignar | 23 de noviembre de 2026 | Pendiente de investigación legal |
| DEC-028 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-029 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-030 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-031 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-032 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-033 | Propuesta recomendada adoptada (sección 4b); requiere validación contable/tributaria | Por asignar | 23 de noviembre de 2026 | Pendiente de investigación legal |
| DEC-034 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| TEC-006–012 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 23 de noviembre de 2026 | Aprobada |
| ADR-016–022 (SAD §17) | Propuesta SAD adoptada | Por asignar | 23 de noviembre de 2026 | Aprobada |
| DEC-035 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 24 de noviembre de 2026 | Aprobada |
| DEC-036 | Propuesta recomendada adoptada (sección 4b) | Por asignar | 24 de noviembre de 2026 | Aprobada |
| DEC-037 | Propuesta recomendada adoptada (sección 4b); requiere validación legal | Por asignar | 24 de noviembre de 2026 | Pendiente de investigación legal |
| TEC-013 | Propuesta recomendada aplicada al contrato 1.4.0, sujeta a confirmación | Por asignar | — | Pendiente de aprobación |

---

# 8. Criterio de cierre

Una decisión se considera cerrada cuando:

1. Se elige una alternativa concreta.
2. Se documenta quién la aprobó y en qué fecha.
3. Se identifican los documentos afectados (PRD, SRS, SAD, DDD, OpenAPI y modelo de datos).
4. Se actualizan los requisitos y criterios de aceptación correspondientes.
5. Se crean pruebas que demuestren el comportamiento aprobado.
6. Si la decisión afecta arquitectura, se registra el ADR correspondiente.
7. Las reglas comerciales visibles se incorporan a términos, políticas o textos de interfaz.

**Recomendación final:** no empezar el esquema físico de PostgreSQL/Prisma hasta cerrar al menos las decisiones de capacidad, zona horaria, membresías, versionado de ofertas, tratamiento fiscal y snapshots. Son las que más pueden provocar cambios estructurales si se posponen.

---

# 9. Incorporación en los documentos de diseño

Las decisiones se incorporaron en los documentos de diseño con su justificación y se eliminaron las listas de decisiones pendientes que mantenían el SRS (§13.1), el SAD (§19) y el DDD (§17.3):

| Documento | Dónde se incorporaron |
|---|---|
| PRD | Reglas de negocio RN-04, RN-06, RN-08, RN-09, RN-10; RNF-08 y RNF-18; stack (PDF y hosting); Anexo A |
| SRS | SRS-AUTH-003, SRS-AUTH-005, SRS-AUTH-009 (nuevo), SRS-EVT-001, SRS-EVT-007, SRS-QUO-004, SRS-QUO-008, SRS-BOOK-003, 004, 007 y 008 (nuevo), SRS-RFQ-007 y 010, SRS-ADM-001, secciones 2.3, 6.6, 6.7, 7.2 y 13.1 |
| SAD | §5.4, §6.2 a §6.4, §9.6, §9.7, §11.2, §11.4, §13.1, §14, ADR-001 a ADR-015 y §19 |
| DDD | BC-02, BC-07, BC-08, agregados Event, Booking y Offer, §6.2, §8.1 (eventos nuevos), §14.3 y §17 |
| API Spec | Cancelación por etapas, cierre de contratación, revisiones de oferta, transferencia de propiedad, zona horaria del evento, capacidad por paquete y niveles de verificación |

La tabla anterior recoge la primera tanda. DEC-035..037 se incorporaron así:

| Documento | DEC-035 | DEC-036 | DEC-037 |
|---|---|---|---|
| PRD | — | RF-ADM-05 | — |
| SRS | SRS-RFQ-012, §8.7, §9.2, §9.3, §9.7 | SRS-AUTH-005/007, SRS-ADM-013, §8.12 | SRS-ADM-012, SRS-NFR-PRIV-002 |
| SAD | §8.2, §8.4 | §7.1, §7.2, §7.6, §8.2, §11.2, §15, §16.5, ADR-017 | — |
| DDD | §7, §15.2, §15.5 | §7, §9.2, §10.3, §14.2, §14.3, §15.4 | — |
| API Spec | — | `listBookings`, `getBooking`, `respondBookingCancellation`, `recordBookingCompletion`, `decideSuspensionReview`, `setProviderSuspension`, `resolveBookingDispute` | Solicitudes de titulares (`dueDate`, `extendedDueDate`, `extendDueDate`) |
