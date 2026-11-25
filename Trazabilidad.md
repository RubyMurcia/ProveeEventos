# ProveeEventos — Matriz de trazabilidad

Esta matriz relaciona cada requisito funcional del SRS con su contexto del DDD, las operaciones del contrato API que lo implementan, los eventos de dominio que produce o consume y su entrega prevista. Se genera a partir de SRS v1.3 y API v1.4.0 (25-11-2026). Cubre los requisitos funcionales del SRS (secciones 3.x); los requisitos no funcionales (SRS-NFR-*) se trazan a sus pruebas en el plan de pruebas (Plans/Plan0002.md, D4). Columnas: **ID** (identificador estable `SRS-*`); **Título** (encabezado del requisito en el SRS); **Contexto DDD** (bounded context responsable según DDD §18); **operationId(s) API** (operaciones de `ProveeEventos_API_Spec.yaml` que implementan el requisito; cuando el requisito no tiene endpoint propio se usa `—` con su justificación entre paréntesis: regla interna, job o solo frontend); **Eventos de dominio** (nombres del catálogo DDD §8.1, o `—`); **Entrega** (E1 piloto o E2, según DEC-021). Los jobs programados de SAD §8.2 se anotan en la columna de operaciones como "(job: ...)" con su nombre exacto, separados por ";"; el trabajo asíncrono que no es un job programado se anota como "(proceso asíncrono: ...)".

| ID | Título | Contexto DDD | operationId(s) API | Eventos de dominio | Entrega |
|---|---|---|---|---|---|
| SRS-AUTH-001 | Registro de empresa | Identity & Access | registerOrganization | OrganizationCreated | E1 |
| SRS-AUTH-002 | Registro de proveedor | Identity & Access | registerProvider | — | E1 |
| SRS-AUTH-003 | Inicio y cierre de sesión | Identity & Access | — (regla interna: BFF y validación de token) | — | E1 |
| SRS-AUTH-004 | Recuperación de acceso | Identity & Access | — (solo frontend: flujo de recuperación de Auth0) | — | E1 |
| SRS-AUTH-005 | Autorización basada en roles y tenant | Identity & Access | — (regla interna: autorización en cada petición) | — | E1 |
| SRS-AUTH-006 | Invitación de coordinadores | Identity & Access | inviteCoordinator, acceptInvitation, resendInvitation, revokeInvitation, listCoordinators, listInvitations (job: Expiración de invitaciones y transferencias) | MembershipInvited, MembershipActivated | E1 |
| SRS-AUTH-007 | Suspensión y reactivación | Identity & Access | setUserSuspension, setOrganizationSuspension, listUsersForAdmin | — | E1 |
| SRS-AUTH-008 | Perfil y preferencias de usuario | Identity & Access | getCurrentUser, updateMyPreferences | — | E1 |
| SRS-AUTH-009 | Roles internos de empresa, administradores y propiedad | Organizations & Tenancy | transferOrganizationOwnership, acceptOwnershipTransfer, rejectOwnershipTransfer, updateCoordinator, getPendingOwnershipTransfer (job: Expiración de invitaciones y transferencias) | OwnershipTransferred | E1 (transferencia: E2) |
| SRS-AUTH-010 | Organización activa | Organizations & Tenancy | getCurrentOrganization (regla interna: organización activa en la sesión BFF y cabecera X-Organization-Id) | — | E1 |
| SRS-AUTH-011 | Asignación de eventos a coordinador restringido | Organizations & Tenancy | setEventAssignees, getEventAssignees | — | E1 |
| SRS-AUTH-012 | Autenticación reforzada | Identity & Access | — (regla interna: MFA y max_age en Auth0) | — | E1 |
| SRS-TEN-001 | Aislamiento de datos | Organizations & Tenancy | — (regla interna: aislamiento por tenant y RLS) | — | E1 |
| SRS-TEN-002 | Propiedad del evento | Organizations & Tenancy | createEvent, setEventAssignees | EventCreated | E1 |
| SRS-TEN-003 | Límites del plan | Organizations & Tenancy | getPlanUsage (regla interna en la creación de recursos) | — | E1 |
| SRS-TEN-004 | Planes, prueba y exceso de límites | Organizations & Tenancy | setOrganizationPlan, getPlanUsage, listPublicPlans (job: Vencimiento de plan) | — | E1 |
| SRS-TEN-005 | Datos de la empresa activa | Organizations & Tenancy | getCurrentOrganization, updateCurrentOrganization | — | E1 |
| SRS-CAT-001 | Alta y edición de perfil | Provider Catalog | getMyProvider, updateMyProvider | — | E1 |
| SRS-CAT-002 | Validación de portafolio | Provider Catalog | createMediaUploadSignature, registerMedia, reorderMedia, deleteMedia, listMyMedia | — | E1 |
| SRS-CAT-003 | Categorías y subtipos | Taxonomy & Templates | listCategories, createCategory, updateCategory, createSubtype, updateSubtype | — | E1 |
| SRS-CAT-004 | Integridad de taxonomía | Taxonomy & Templates | createSubtype, updateSubtype (regla interna de integridad) | — | E1 |
| SRS-CAT-005 | Límite de categorías del proveedor | Provider Catalog | updateMyProvider (regla interna) | — | E1 |
| SRS-CAT-006 | Paquetes de servicio | Provider Catalog | listMyPackages, createPackage, getMyPackage, updatePackage, deactivatePackage | ServicePackagePublished, ServicePackageChanged | E1 |
| SRS-CAT-007 | Modalidad de contratación | Provider Catalog | createPackage, updatePackage | ServicePackageChanged | E1 |
| SRS-CAT-008 | Canal preferido | Provider Catalog | updateMyProvider | — | E1 |
| SRS-CAT-009 | Disponibilidad | Availability & Booking | getProviderAvailability, setProviderAvailability, getPublicProviderAvailability | — | E1 |
| SRS-CAT-010 | Visibilidad de catálogo | Provider Catalog | searchProviders, getPublicProvider | ProviderVerified, ProviderSuspended | E1 |
| SRS-CAT-011 | Búsqueda y filtros | Provider Catalog | searchProviders | — | E1 |
| SRS-CAT-012 | Resultados | Provider Catalog | searchProviders, getPublicProvider | — | E1 |
| SRS-CAT-013 | Ordenamiento | Provider Catalog | searchProviders | — | E1 |
| SRS-CAT-014 | Capacidad y precio estimado | Provider Catalog | searchProviders, createQuickQuotation | — | E1 |
| SRS-CAT-015 | Revelación de datos de contacto | Provider Catalog | buildWhatsappClickToChat, getPublicProvider, getBookingProviderContact | — | E1 |
| SRS-EVT-001 | Crear evento | Event Management | createEvent, getEvent | EventCreated | E1 |
| SRS-EVT-002 | Plantillas predefinidas | Taxonomy & Templates | listEventTemplates, getEventTemplate | — | E1 |
| SRS-EVT-003 | Modificar plantilla antes de cotizar | Taxonomy & Templates | updateEvent (regla interna: la plantilla global no se altera) | — | E1 |
| SRS-EVT-004 | Plantillas personalizadas | Taxonomy & Templates | createEventTemplate, getEventTemplate, updateEventTemplate, deactivateEventTemplate | — | E1 |
| SRS-EVT-005 | Clonar evento | Event Management | cloneEvent | EventCloned | E1 |
| SRS-EVT-006 | Estados del evento | Event Management | transitionEventStatus (job: Inicio de servicio) | EventCompleted | E1 |
| SRS-EVT-007 | Borradores inactivos | Event Management | reactivateEvent (job: Borradores inactivos; Purga por retención) | — | E1 |
| SRS-EVT-008 | Edición de evento con compromisos | Event Management | updateEvent | — | E1 |
| SRS-EVT-009 | Cancelación de evento con compromisos | Event Management | transitionEventStatus | RfqRequestCancelled, BookingCancellationRequested, EventCancelled | E1 |
| SRS-EVT-010 | Fechas de capacidad del servicio | Availability & Booking | — (regla interna: aplicada en createInstantBooking y awardRfqOffer) | — | E1 |
| SRS-EVT-011 | Listado de eventos | Event Management | listEvents | — | E1 |
| SRS-QUO-001 | Cotización rápida | Quotation | createQuickQuotation, listQuickQuotations | QuotationCreated | E1 |
| SRS-QUO-002 | Elegibilidad de proveedores | Quotation | — (regla interna: elegibilidad del motor) | — | E1 |
| SRS-QUO-003 | Comparación normalizada | Quotation | createQuickQuotation | — | E1 |
| SRS-QUO-004 | Ranking | Quotation | — (regla interna: ranking explicable y versionado) | — | E1 |
| SRS-QUO-005 | Presupuesto referencial | Quotation | createQuickQuotation | — | E1 |
| SRS-QUO-006 | Cotización integral | Quotation | createQuotation | QuotationCreated | E1 |
| SRS-QUO-007 | Selección y sustitución | Quotation | updateQuotationSelections, addQuotationItem, removeQuotationItem | QuotationItemSelected | E1 |
| SRS-QUO-008 | Totales | Quotation | getQuotation (regla interna: cálculo de totales) | — | E1 |
| SRS-QUO-009 | Guardar borrador | Quotation | createQuotation, updateQuotationSelections | — | E1 |
| SRS-QUO-010 | Favoritos | Quotation | markQuickQuotationFavorite, unmarkQuickQuotationFavorite | — | E1 |
| SRS-QUO-011 | PDF | Quotation | requestQuotationPdf, getDocument | — | E1 |
| SRS-QUO-012 | Versionado | Quotation | requestQuotationPdf, listQuotationDocuments (regla interna: snapshot) | QuotationVersionCreated | E1 |
| SRS-QUO-013 | Redondeo de importes | Quotation | — (regla interna: redondeo NUMERIC(14,2)) | — | E1 |
| SRS-QUO-014 | Listado de cotizaciones | Quotation | listQuotations | — | E1 |
| SRS-BOOK-001 | Condiciones de reserva | Availability & Booking | createInstantBooking | — | E2 |
| SRS-BOOK-002 | Reserva atómica | Availability & Booking | createInstantBooking | BookingConfirmed | E1 (regla transaccional en la adjudicación) / E2 (Instant Book) |
| SRS-BOOK-003 | Límite de eventos por fecha | Availability & Booking | — (regla interna: capacidad validada en reserva y adjudicación) | — | E1 (capacidad global) / E2 (capacidad por paquete) |
| SRS-BOOK-004 | Confirmación | Availability & Booking | createInstantBooking, getBooking | BookingConfirmed | E2 |
| SRS-BOOK-005 | Tarifa vinculante | Availability & Booking | listBookingChangeProposals, proposeBookingChange, respondBookingChangeProposal (regla interna: tarifa congelada; cambios por modificación propuesta) | — | E2 |
| SRS-BOOK-006 | Idempotencia | Availability & Booking | createInstantBooking (cabecera Idempotency-Key) | — | E2 |
| SRS-BOOK-007 | Cancelación | Availability & Booking | recordBookingCancellation, respondBookingCancellation | BookingCancellationRequested, BookingCancellationDisputed, BookingCancelled | E1 |
| SRS-BOOK-008 | Cierre de contratación y devengo de comisión | Availability & Booking | recordBookingCompletion (job: Cierre automático) | ServiceMarkedDone, ServiceIncidentReported, BookingClosed, CommissionAccrued | E1 |
| SRS-BOOK-009 | Estados de la contratación | Availability & Booking | listBookings, getBooking, getBookingHistory (regla interna: máquina de estados) (job: Inicio de servicio; Cancelación sin respuesta) | — | E1 |
| SRS-BOOK-010 | Estado de comisión | Availability & Booking | exportCommissions, reverseCommission | CommissionAccrued, CommissionWithheld, CommissionReversed | E1 |
| SRS-RFQ-001 | Selección de proveedores | RFQ & Offers | createRfqCycle | RfqCycleCreated | E1 |
| SRS-RFQ-002 | Solicitud individual | RFQ & Offers | createRfqCycle, getRfqRequest | RfqCycleCreated | E1 |
| SRS-RFQ-003 | Envío paralelo | RFQ & Offers | createRfqCycle, retryRfqDispatch | RfqRequestSent | E1 |
| SRS-RFQ-004 | SLA | RFQ & Offers | createRfqCycle (job: Expiración de SLA) | RfqRequestExpired | E1 |
| SRS-RFQ-005 | Estados de solicitud | RFQ & Offers | listRfqRequests, getRfqRequest | RfqRequestExpired, RfqRequestCancelled | E1 |
| SRS-RFQ-006 | Oferta estructurada | RFQ & Offers | submitProviderPortalOffer, submitMagicLinkResponse | OfferReceived | E1 |
| SRS-RFQ-007 | Respuesta única y correcciones | RFQ & Offers | reviseRfqOffer, submitMagicLinkResponse, listRfqOffers | OfferRevised | E1 |
| SRS-RFQ-008 | Bid Tabulation | RFQ & Offers | getBidTabulation | — | E1 |
| SRS-RFQ-009 | Adjudicación | RFQ & Offers | awardRfqOffer | OfferAwarded, OfferNotAwarded | E1 |
| SRS-RFQ-010 | Sin respuesta o rechazo | RFQ & Offers | rejectRfqRequest, listRfqAlternatives | OfferRejected, RfqRequestExpired | E1 |
| SRS-RFQ-011 | Avisos de cortesía | RFQ & Offers | awardRfqOffer (aviso de cortesía) | OfferNotAwarded | E1 |
| SRS-RFQ-012 | Ofertas con vigencia vencida | RFQ & Offers | getBidTabulation (regla interna: vigencia de la oferta) (job: Vencimiento de ofertas) | OfferExpired, OfferNotAwarded | E1 |
| SRS-RFQ-013 | Revocación y reenvío | RFQ & Offers | cancelRfqRequest, retryRfqDispatch | RfqRequestCancelled | E1 |
| SRS-MAGIC-001 | Generación de enlace | RFQ & Offers | createRfqCycle (regla interna: emisión de token) | — | E1 |
| SRS-MAGIC-002 | Validez | RFQ & Offers | getMagicLinkForm (regla interna: validez del token) | — | E1 |
| SRS-MAGIC-003 | Uso único | RFQ & Offers | submitMagicLinkResponse | MagicLinkConsumed | E1 |
| SRS-MAGIC-004 | Protección | RFQ & Offers | — (regla interna: HTTPS, rate limiting y cabeceras) | — | E1 |
| SRS-MAGIC-005 | Formulario móvil | RFQ & Offers | getMagicLinkForm, submitMagicLinkResponse | — | E1 |
| SRS-MAGIC-006 | Notificación de respuesta | RFQ & Offers | submitMagicLinkResponse | OfferReceived | E1 |
| SRS-WA-001 | Plantillas | Taxonomy & Templates | listWhatsappTemplates, createWhatsappTemplate, updateWhatsappTemplate, listOrganizationWhatsappTemplates, createOrganizationWhatsappTemplate, updateOrganizationWhatsappTemplate, listAvailableWhatsappTemplates | — | E2 (adelantable a E1 si hay capacidad) |
| SRS-WA-002 | Renderizado determinista | RFQ & Offers | buildWhatsappClickToChat (regla interna: renderizado determinista) | — | E2 |
| SRS-WA-003 | Click-to-Chat | RFQ & Offers | buildWhatsappClickToChat | — | E2 |
| SRS-WA-004 | Limitación de recepción | RFQ & Offers | — (regla interna: sin webhook de recepción en MVP) | — | E2 |
| SRS-WA-005 | Asistente IA asistido | Assisted Response | createAssistedResponsePrompt, getAssistedResponseSchema | — | E2 |
| SRS-WA-006 | Validación del JSON | Assisted Response | validateAssistedResponse | AssistedResponseImported | E2 |
| SRS-WA-007 | Revisión humana | Assisted Response | confirmAssistedResponse | AssistedResponseConfirmed | E2 |
| SRS-WA-008 | Trazabilidad de origen | Assisted Response | confirmAssistedResponse (regla interna: origen WHATSAPP_IA_ASISTIDO) | AssistedResponseImported | E2 |
| SRS-WA-009 | Adaptador futuro | Assisted Response | — (regla interna: interfaz desacoplada de normalización) | — | E2 |
| SRS-TRK-001 | Seguimiento por ítem | Quotation | getItemTracking | — | E1 |
| SRS-TRK-002 | Estados del ítem | Quotation | getItemTracking | — | E1 |
| SRS-TRK-003 | Transiciones | Quotation | transitionItemTracking | — | E1 |
| SRS-TRK-004 | Vista MVP | Quotation | getItemTracking | — | E1 |
| SRS-REV-001 | Elegibilidad | Reviews | createReview | ReviewSubmitted | E1 |
| SRS-REV-002 | Dimensiones | Reviews | createReview | ReviewSubmitted | E1 |
| SRS-REV-003 | Promedio | Reviews | listProviderReviews (regla interna: promedio) | — | E1 |
| SRS-REV-004 | Una reseña por contratación | Reviews | createReview | ReviewSubmitted | E1 |
| SRS-REV-005 | Texto | Reviews | createReview, respondToReview | ReviewSubmitted, ReviewResponded | E1 |
| SRS-REV-006 | Respuesta del proveedor | Reviews | respondToReview | ReviewResponded | E1 |
| SRS-REV-007 | Moderación | Reviews | listReviewReports, resolveReviewReport | ReviewModerated | E1 |
| SRS-REV-008 | Ventana, visibilidad y reporte | Reviews | createReview, reportReview (job: Aviso de calificación) | — | E1 |
| SRS-ADM-001 | Verificación de proveedores | Administration & Audit | submitProviderForReview, listProvidersForAdmin, updateProviderVerification, getProviderForAdmin | ProviderProfileSubmitted, ProviderVerified, ProviderRejected | E1 (niveles 1–2) / E2 (nivel 3) |
| SRS-ADM-002 | Taxonomía | Taxonomy & Templates | createCategory, updateCategory, createSubtype, updateSubtype, listCategoriesForAdmin | — | E1 |
| SRS-ADM-003 | Plantillas de eventos | Taxonomy & Templates | createGlobalEventTemplate, updateGlobalEventTemplate, listGlobalEventTemplates | — | E1 |
| SRS-ADM-004 | Plantillas WhatsApp | Taxonomy & Templates | listWhatsappTemplates, createWhatsappTemplate, updateWhatsappTemplate | — | E2 (adelantable a E1 si hay capacidad) |
| SRS-ADM-005 | Suspensión | Administration & Audit | setProviderSuspension, setUserSuspension | ProviderSuspended | E1 |
| SRS-ADM-006 | Moderación | Administration & Audit | listReviewReports, resolveReviewReport | ReviewModerated | E1 |
| SRS-ADM-007 | Dashboard | Administration & Audit | getAdminDashboard | — | E1 |
| SRS-ADM-008 | Exportación de comisiones y suscripciones | Administration & Audit | exportCommissions, listCommissions, updateCommissionReferences, exportSubscriptions | — | E1 |
| SRS-ADM-009 | Gestión de planes | Administration & Audit | setOrganizationPlan, listPlans, createPlanVersion, updatePlan, listOrganizationsForAdmin, getOrganizationForAdmin | — | E1 |
| SRS-ADM-010 | Resolución de disputas | Administration & Audit | listDisputes, resolveBookingDispute, reverseCommission, updateProviderVerification | BookingNotDelivered, BookingCancelled, CommissionReversed | E1 |
| SRS-ADM-011 | Consulta de auditoría | Administration & Audit | searchAuditLogs | — | E1 |
| SRS-ADM-012 | Solicitudes de titulares y retención legal | Administration & Audit | createDataSubjectRequest, listMyDataRequests, listDataSubjectRequests, resolveDataSubjectRequest, setLegalHold, releaseLegalHold, listLegalHolds (job: Purga por retención) | — | E1 |
| SRS-ADM-013 | Suspensión de proveedor con contrataciones futuras | Administration & Audit | setProviderSuspension, decideSuspensionReview, resolveBookingDispute (regla interna: revisión de contrataciones futuras, DEC-034; operación de la decisión, DEC-036) (job: Plazo de revisión por suspensión) | ProviderSuspended, RfqRequestCancelled, BookingPlacedUnderPlatformReview, BookingReviewDecisionRecorded, BookingCancelled | E1 |
| SRS-NOT-001 | Email transaccional | Messaging & Notifications | — (proceso asíncrono: despacho de email desde el outbox) (job: Recordatorio de evento próximo) | BookingPlacedUnderPlatformReview, OrganizationCreated, MembershipInvited, RfqRequestSent, RfqRequestExpired, OfferReceived, OfferAwarded, OfferNotAwarded, BookingConfirmed, ProviderVerified, ProviderRejected, ProviderSuspended, ReviewSubmitted | E1 |
| SRS-NOT-002 | Notificación in-app | Messaging & Notifications | listNotifications, markNotificationRead | — | E1 |
| SRS-NOT-003 | Preferencias | Messaging & Notifications | updateMyPreferences | — | E1 |
| SRS-NOT-004 | Tiempo de despacho | Messaging & Notifications | — (proceso asíncrono: despacho dentro de 5 minutos desde el outbox) | — | E1 |
| SRS-NOT-005 | Reintentos | Messaging & Notifications | — (proceso asíncrono: reintentos con backoff) | NotificationDeliveryFailed | E1 |
| SRS-NOT-006 | Estado de entrega de email | Messaging & Notifications | receiveSendgridEvents | NotificationDeliveryFailed | E1 |

Entregas según DEC-021.

## Huecos

Verificado con python3 -I Tools/check_package.py --only 3,4,5,6,8 (24-11-2026): cada operationId del contrato aparece en una fila, cada requisito funcional del SRS tiene fila, cada evento del catálogo DDD §8.1 aparece al menos una vez, la entrega coincide con la línea **Entrega:** del SRS y cada job programado de SAD §8.2 está anotado. Los chequeos comprueban presencia; que cada operación, evento o job esté en la fila correcta se revisa al editar la matriz. Las filas con "—" en operationId llevan entre paréntesis su justificación (regla interna, job o solo frontend).
