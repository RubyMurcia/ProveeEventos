# ProveeEventos — DevOps, CI/CD y Despliegue (`ProveeEventos_CICD.md`)

| Campo | Valor |
|---|---|
| Documento | `ProveeEventos_CICD.md` |
| Versión | 1.0 |
| Fecha | 2026-11-25 |
| Alcance | `Etapa 1 — Local (Docker/Docker Compose) + CI (GitHub Actions)` |
| Estado de Etapa 2 | `Diferido por decisiones de infraestructura pendientes` (§11) |
| Lector principal | Agente de IA que creará `Dockerfile`, `docker-compose.yml`, `.env.example`, scripts y `.github/workflows/*.yml` |
| Estado del repositorio | No existe código de aplicación: todo lo descrito está por implementar |

### Historial de versiones

| Versión | Fecha | Cambios |
|---|---|---|
| 1.0 | 2026-11-25 | Primera versión: ambientes, configuración, secretos, Docker Compose local, migraciones, CI, rollback local, exclusiones y decisiones pendientes. Generada según `Plans/Plan0001_CICDs.md` |

Convenciones: `DC-nn` decisión autónoma de DevOps (§12); `INFRA-P-nn` decisión de infraestructura pendiente (§11); `DISC-nn` discrepancia entre fuentes (§1.4). Las fuentes prevalecen sobre este documento (PRD > SRS > SAD > DDD > API Spec > `Decisiones.md`; el TDD manda en persistencia; `ADR-GOV-004`).

---

## Sección 1 — Propósito, Alcance de Etapa 1 e Inventario de Documentos Fuente

### 1.1 Propósito

Definir de forma ejecutable cómo se levanta ProveeEventos en un equipo de desarrollo con Docker Compose, cómo se configura sin secretos versionados, cómo se migran sus datos y qué debe verificar GitHub Actions antes de integrar un Pull Request.

### 1.2 Alcance actual frente a lo diferido

| Bloque | Etapa 1 (este documento) | Diferido |
|---|---|---|
| Ambiente `development` | Especificado y ejecutable | — |
| Ambientes `staging` y `production` | Modelo lógico, convenciones y contrato de despliegue | Infraestructura y ejecución (`INFRA-P-01`–`07`, `11`, `16`) |
| Contenedores | Dockerfiles y Compose local | Registro, orquestador, promoción de imágenes |
| Configuración y secretos | `.env` local, Compose, GitHub | Gestor de secretos productivo (`INFRA-P-08`) |
| Migraciones | Local y validación en CI | Ejecución en ambientes remotos |
| CI | Tres workflows | — |
| CD | Solo contrato (§7.7) | Workflows de despliegue (`INFRA-P-11`) |
| Rollback | Local (§8) | Remoto y productivo (`INFRA-P-11`) |
| Backups y recuperación | **No aplica en Etapa 1** (§9) | `INFRA-P-12` |
| Monitoreo y alertas | **No aplica en Etapa 1** (§10) | `INFRA-P-13` |

### 1.3 Inventario de documentos fuente

| Archivo | Versión | Qué aporta aquí | Lectura |
|---|---|---|---|
| `ProveeEventos_ADRs.md` | 1.0 | Stack, rutas, checks, workflows, protecciones, secretos, salud, pruebas | Dirigida: §1–§2, §5–§6 y ADRs de STACK, DATA-009/014/020, SEC-005, OBS, TEST, GOV, ARCH-002/008 |
| `ProveeEventos_TESTs.md` | 1.0 | Suites, herramientas, matriz por etapa, entornos de prueba, *quality gates* y handoff | §0–§3, §10–§12, §14–§15 |
| `ProveeEventos_TDD.md` | vigente | Migraciones, roles, pool, seeds, conexión Prisma, datos no productivos | Dirigida: §4.4, §4.5, §7.2–§7.6, §10.1, §10.3 |
| `ProveeEventos_SAD.md` | 1.4 | Unidades desplegables, colas y jobs, integraciones, salud, ambientes, pipeline | Dirigida: §3.2, §8, §9, §10.8, §11.1, §12.1, §13 |
| `ProveeEventos_SRS.md` | 1.3 | Requisitos no funcionales y plazos configurables | Dirigida (leído en trabajos previos de la sesión: §2–§10) |
| `ProveeEventos_PRD.md` | 2.4 | Stack de referencia y alcance | Dirigida |
| `ProveeEventos_DDD.md` | 1.4 (rev.) | Módulos y eventos | Por referencia desde SAD y ADRs |
| `ProveeEventos_API_Spec.yaml` | 1.4.0 (TEC-013, pendiente de aprobación) | Prefijo `/api/v1`, servidor local `:4000`, operaciones públicas | Análisis estructurado |
| `ProveeEventos_UXUI.md` | 1.1 | Frontend tras BFF, `/r`, cabeceras, navegadores | Por referencia (§11 del documento) |
| `proveeeventos.prisma` | sin versión | Generador, `datasource` | Cabecera |
| `proveeeventos.sql` | sin versión | Migración `00`, roles, tiempos límite, `20_rls` | Dirigida: bloques SQL-001..008 y encabezados de migración |
| `Decisiones.md` | 1.6 | DEC-007, 012, 013, 014, 016, 017; TEC-013 | Por referencia |
| `Glosario.md`, `Trazabilidad.md`, `CLAUDE.md`, `.gitignore` | — | Convenciones, validadores, exclusiones de versionado | `CLAUDE.md` y `.gitignore` completos; los otros dos, por búsqueda |
| `Tools/check_package.py`, `Tools/check_openapi.py` | — | Validadores obligatorios en CI | Completos |
| `Reviews/`, `Plans/Plan0002.md` | — | Contexto | Búsqueda de temas de despliegue: sin requisitos operativos adicionales |

No existe contrato AsyncAPI.

### 1.4 Discrepancias entre fuentes y su tratamiento

| ID | Discrepancia | Tratamiento en este documento |
|---|---|---|
| DISC-01 | `ProveeEventos_TESTs.md` se escribió en paralelo a este documento | Conciliado al cierre con sus §2, §3, §10–§12 y §15; las diferencias quedan en `DISC-08`–`DISC-12`. Si TESTs cambia después, volver a conciliar |
| DISC-02 | `TDD §4.5` exige semillas de referencia en todo ambiente; el encargo pide sembrar solo en `development` | Dos clases separadas (§6.5): referencia (versionada, necesaria en todo ambiente) y sintéticas (solo `development` y pruebas) |
| DISC-03 | `ADR §2.5` enumera cinco carpetas de prueba; `TESTs` añade multi-tenant, seguridad y carga | Se añaden como proyectos del mismo `backend/vitest.config.ts` (`DC-20`); requiere aprobación humana (`ADR-GOV-002`) |
| DISC-04 | `ADR-GOV-006` exige un Environment `human-approval`; en GitHub, los revisores obligatorios de un Environment en repositorios privados parecen exigir plan Enterprise | `INFRA-P-14`; §7.5 define la configuración principal y la condición para usarla. Verificar en la documentación vigente de GitHub |
| DISC-05 | SAD §9.7 exige servir PDF desde URL protegida, sin definir dónde se almacenan | Local: volumen de documentos (`DC-12`); productivo: `INFRA-P-09` |
| DISC-06 | `ADR-GOV-001`/`002` no listan `ProveeEventos_UXUI.md`, `ProveeEventos_TESTs.md` ni este documento | Se protegen por igual en el borrador de rutas (§7.4) y se propone enmendar el ADR |
| DISC-07 | Los ADRs citan el contrato 1.3.0; el vigente es 1.4.0 (TEC-013, pendiente) | El CI valida el archivo presente en el repositorio |
| DISC-08 | TESTs §3.3 admite limpiar o sembrar los datos E2E mediante un endpoint interno de pruebas; el contrato no lo define y PostgreSQL no se publica en Compose | Semillas por el servicio `seed` y datos por *worker* a través de la API pública (`DC-32`) |
| DISC-09 | TESTs (G-08, TC-SEC-026) pide `npm audit --audit-level=high`; `ADR-STACK-003` lo fija con `--omit=dev` | El check bloqueante usa el comando del ADR (prevalece); la auditoría completa corre en `nightly` |
| DISC-10 | TESTs G-12 exige la carga *smoke* en `staging-perf`, ambiente que no existe | Se ejecuta contra el perfil `test` como señal temprana; G-12 queda parcial hasta `INFRA-P-16` |
| DISC-11 | TESTs §15.1 y §15.3 sitúa las pruebas en `backend/tests/` (con `api/`), las migraciones en `backend/prisma/` y la guarda en `tools/adr-guard.mjs`, y redefine `verify:adrs` | Prevalecen los ADR: `backend/src/tests/` (con `contract/` para `TC-API`), `backend/src/prisma/`, `Tools/adr-guard/` y `verify:adrs` literal de `ADR §6.1`. Los nombres de scripts `test:*` se conservan |
| DISC-12 | TESTs §15.3 define `test:sec` con `semgrep ci` (reglas descargadas), `npm audit` y gitleaks, que requieren red; §15.4 nombra los jobs de otra forma | `test:sec` se limita a Vitest; Semgrep (reglas versionadas), `npm audit` y gitleaks corren en `security-scan`, `adr-guard-runtime` y `adr-guard`. Los checks obligatorios conservan los nombres del ADR (correspondencia en §7.3) |

---
## Sección 2 — Ambientes (`development`, `staging` y `production`)

### 2.1 Matriz de ambientes

| Atributo | `development` (local) | `staging` | `production` |
|---|---|---|---|
| **Estado en Etapa 1** | **Especificado y ejecutable (Docker + Docker Compose)** | **Modelo lógico reservado — implementación diferida hasta definir infraestructura** | **Modelo lógico reservado — implementación diferida hasta definir infraestructura** |
| Propósito | Desarrollo de agentes y personas; pruebas locales | Validación integrada y UAT (SAD §13.2) | Operación real |
| Rama o disparador | Cualquier rama de trabajo | Integración en `main` (hook diferido, §7.7) | Promoción manual con aprobación humana desde `main` (`ADR-GOV-006 R6`) |
| `APP_ENV` | `development` | `staging` | `production` |
| `NODE_ENV` | `development` (hot reload) o `production` (perfil `prodlike`) | `production` | `production` |
| Datos | Sintéticos y semillas de referencia | Sintéticos o anonimizados (SAD §13.2; TDD §7.6) | Personales y transaccionales |
| Semillas sintéticas | Permitidas | Prohibidas por este documento; los datos sintéticos de volumen se definirán en Etapa 2 | Prohibidas |
| Externos | Dobles locales (Auth0, SendGrid, Cloudinary) o cuentas de desarrollo propias | Cuentas de prueba separadas (`INFRA-P-10`) | Cuentas productivas (`INFRA-P-10`) |
| Correo | Mailpit (no entrega) | Adaptador sin entrega a destinatarios reales (TDD §7.6) | SendGrid con SPF, DKIM y DMARC (SRS-NOT-006) |
| `20_rls` | Opcional (`DB_APPLY_RLS`); `true` en pruebas | **No se aplica** antes de la etapa J (`ADR-DATA-009 R4`) | **No se aplica** antes de la etapa J |
| Secretos | `.env` local generado | Gestor de secretos (`INFRA-P-08`) | Gestor de secretos (`INFRA-P-08`) |

`Test/CI` (SAD §13.2) no es un cuarto ambiente desplegable: es el contexto efímero de GitHub Actions (§7), con `APP_ENV=test`, datos creados por las pruebas y contenedores desechables.

### 2.2 Reglas de separación (vinculantes en las tres)

1. Un mismo artefacto de imagen sirve a todos los ambientes: **ninguna** configuración de ambiente se compila en la imagen (`DC-06`).
2. Cada ambiente tiene credenciales, claves de derivación, claves de sesión y cuentas externas propias; jamás se reutilizan.
3. Prohibido copiar datos de producción a ambientes inferiores sin anonimización y autorización previas dentro de producción (SAD §13.2; `ADR-SEC-005 R4`).
4. Las opciones solo locales (`EMAIL_PROVIDER=smtp`, URLs `http://`, URLs de canal interno, `DOCUMENT_STORAGE_DRIVER=local`, semillas sintéticas) hacen fallar el arranque fuera de `development` y `test` (§3.4).

### 2.3 Contrato de despliegue para Etapa 2 (independiente del proveedor)

Cualquier plataforma que se elija debe cumplir:

| Paso | Contrato |
|---|---|
| Artefactos | Imágenes `api`/`worker` (misma imagen, distinto comando), `web` y `migrate`, construidas una vez por commit y promovidas por digest |
| Configuración | Variables de §3.2 inyectadas en ejecución; secretos desde un gestor |
| Orden | 1) bootstrap de base por administrador (una vez); 2) paso único de migración con `pe_migrator` y `DIRECT_URL`; 3) semillas de referencia; 4) `api` y `worker`; 5) `web` |
| Compatibilidad | Esquema compatible con la versión anterior y la nueva durante el cambio (*expand-and-contract*, `ADR-DATA-014 R7`) |
| Salud | `GET /health/live` para vida; `GET /health/ready` para recibir tráfico (SAD §10.8) |
| Aprobación | Producción requiere aprobación humana |

---
## Sección 3 — Estructura de Configuración

### 3.1 Jerarquía de archivos y precedencia

| Orden (el posterior gana) | Origen | Versionado | Contenido |
|---|---|---|---|
| 1 | Valores por defecto del esquema de validación (§3.4) | Sí (código) | Solo configuración no sensible |
| 2 | `docker/images.env` | Sí | Imágenes base y de servicios fijadas por etiqueta y digest (§5.2) |
| 3 | `.env.example` | Sí | Plantilla completa con valores ficticios y marcadores `__GENERATE_*__` |
| 4 | `.env` en la raíz | **No** (`.gitignore`) | Copia generada por `scripts/dev/gen-env.sh` |
| 5 | Variables del shell o del job de CI | No | Prevalecen sobre `.env` en la interpolación de Compose |
| 6 | Bloque `environment:` de cada servicio en `docker-compose.yml` | Sí | Lista explícita por servicio y valores derivados (URLs de conexión) |

Reglas:

1. Compose se invoca **siempre** con ambos archivos: `docker compose --env-file docker/images.env --env-file .env …` (script `npm run dc -- …`).
2. Prohibido `env_file:` global: cada servicio recibe solo sus variables (`DC-05`). `web` no recibe credenciales de base ni de Redis.
3. Toda variable obligatoria se interpola como `${VAR:?mensaje}`: Compose falla antes de crear contenedores.
4. Prohibidas las variables `NEXT_PUBLIC_*`: no se compila configuración en la imagen (`DC-06`; `ADR-SEC-005 R3`).
5. Solo `shared/config` (backend) y `lib/config` (frontend) leen `process.env`; el resto recibe un objeto tipado (`DC-07`). `prisma.config.ts` es la excepción que fija `ADR-STACK-004`.

### 3.2 Catálogo completo de variables de entorno

"En .env = no" significa que la fija o la deriva `docker-compose.yml` (o el job de CI), no el archivo del desarrollador. En los ejemplos, `CLAVE` representa la contraseña correspondiente.

#### Comunes

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `APP_ENV` | api, worker, web, migrate, seed | enum development, test, staging, production | Sí | `development` | Config | sí |
| `NODE_ENV` | api, worker, web | enum development, production, test | Sí | `development` | Config | no |
| `LOG_LEVEL` | api, worker, web | enum fatal, error, warn, info, debug, trace | No (info) | `debug` | Config | sí |
| `TZ` | api, worker, web, migrate, seed | constante UTC | Sí | `UTC` | Config | no |
| `FEATURE_E2_ENABLED` | api, worker, web | booleano true, false | No (false) | `false` | Config | sí |

#### Puertos locales publicados en 127.0.0.1

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `WEB_PORT` | web | entero 1024-65535 | No (3000) | `3000` | Config | sí |
| `API_PORT` | api | entero 1024-65535 | No (4000) | `4000` | Config | sí |
| `WORKER_HEALTH_PORT` | worker | entero 1024-65535 | No (4001) | `4001` | Config | no |
| `MAILPIT_UI_PORT` | mailpit | entero 1024-65535 | No (8025) | `8025` | Config | sí |
| `DEV_STUBS_PORT` | dev-stubs | entero 1024-65535 | No (4010) | `4010` | Config | sí |

#### Base de datos

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `POSTGRES_DB` | postgres, db-bootstrap | identificador SQL | Sí | `proveeeventos` | Config | sí |
| `POSTGRES_USER` | postgres, db-bootstrap | identificador SQL distinto de pe_* | Sí | `pe_admin` | Config | sí |
| `POSTGRES_PASSWORD` | postgres, db-bootstrap | secreto de 32 caracteres o más, alfanumérico | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `PE_MIGRATOR_PASSWORD` | db-bootstrap, migrate, seed, db-rls | secreto alfanumérico de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `PE_API_PASSWORD` | db-bootstrap, pgbouncer, api | secreto alfanumérico de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `PE_WORKER_PASSWORD` | db-bootstrap, pgbouncer, worker | secreto alfanumérico de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `PE_RETENTION_PASSWORD` | db-bootstrap, pgbouncer, worker | secreto alfanumérico de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `PE_READONLY_PASSWORD` | db-bootstrap, psql | secreto alfanumérico de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `DATABASE_URL` | api, worker | URL postgresql por el pooler; usuario pe_api o pe_worker | Sí | `postgresql://pe_api:CLAVE@pgbouncer:5432/proveeeventos` | Secreto | no |
| `RETENTION_DATABASE_URL` | worker | URL postgresql por el pooler; usuario pe_retention | Sí | `postgresql://pe_retention:CLAVE@pgbouncer:5432/proveeeventos` | Secreto | no |
| `DIRECT_URL` | migrate, seed | URL postgresql directa; usuario pe_migrator | Sí | `postgresql://pe_migrator:CLAVE@postgres:5432/proveeeventos` | Secreto | no |
| `SHADOW_DATABASE_URL` | db-authoring | URL postgresql directa a la base sombra | No (solo autoría de migraciones) | `postgresql://pe_migrator:CLAVE@postgres:5432/proveeeventos_shadow` | Secreto | no |
| `DB_POOL_MAX` | api, worker | entero 1-50 | No (10) | `10` | Config | sí |
| `DB_APPLY_RLS` | db-rls | booleano true, false | No (false) | `false` | Config | sí |

#### Redis

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `REDIS_PASSWORD` | redis, api, worker | secreto alfanumérico de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `REDIS_URL` | api, worker | URL redis con contraseña | Sí | `redis://:CLAVE@redis:6379/0` | Secreto | no |

#### Identidad, sesión y enlaces

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `AUTH0_ISSUER_BASE_URL` | api, web, dev-stubs | URL del emisor; https salvo development y test | Sí | `http://localhost:4010` | Config | sí |
| `AUTH0_BACKCHANNEL_BASE_URL` | api, web | URL interna para JWKS y token; solo development y test | No | `http://dev-stubs:4010` | Config | sí |
| `AUTH0_AUDIENCE` | api, web, dev-stubs | identificador de API | Sí | `https://api.proveeeventos.test` | Config | sí |
| `AUTH0_CLIENT_ID` | web, dev-stubs | texto | Sí | `pe-web-local` | Config | sí |
| `AUTH0_CLIENT_SECRET` | web, dev-stubs | secreto de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `SESSION_COOKIE_KEYS` | web | lista version:base64 de 32 bytes; 1 o 2 versiones; la primera cifra | Sí | `1:__GENERATE_B64__` | Secreto | sí |
| `SESSION_IDLE_TIMEOUT_SECONDS` | web | entero 300-86400 | No (86400) | `86400` | Config | sí |
| `APP_BASE_URL` | web, worker, api | URL pública de la web; https salvo development y test | Sí | `http://localhost:3000` | Config | sí |
| `API_BASE_URL` | web | URL de la API usada solo en servidor | Sí | `http://api:4000` | Config | no |
| `TOKEN_DERIVATION_KEYS` | api, worker | lista version:base64 de 32 bytes | Sí | `1:__GENERATE_B64__` | Secreto | sí |
| `TOKEN_DERIVATION_ACTIVE_VERSION` | api, worker | entero presente en TOKEN_DERIVATION_KEYS | Sí | `1` | Config | sí |
| `TRUSTED_PROXY_CIDRS` | api | lista CIDR de proxies que fijan la IP del cliente | Sí | `172.16.0.0/12,192.168.0.0/16` | Config | sí |

#### Correo

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `EMAIL_PROVIDER` | worker | enum sendgrid, smtp; smtp solo development y test | Sí | `smtp` | Config | sí |
| `EMAIL_FROM_ADDRESS` | worker | correo | Sí | `no-reply@proveeeventos.test` | Config | sí |
| `EMAIL_FROM_NAME` | worker | texto | No | `ProveeEventos local` | Config | sí |
| `SMTP_HOST` | worker | host | Si smtp | `mailpit` | Config | sí |
| `SMTP_PORT` | worker | entero | Si smtp | `1025` | Config | sí |
| `SENDGRID_API_KEY` | worker | secreto | Si sendgrid | (vacío) | Secreto | sí |
| `SENDGRID_API_BASE_URL` | worker | URL; solo para dobles en development y test | No | (vacío) | Config | sí |
| `SENDGRID_WEBHOOK_PUBLIC_KEY` | api | clave pública ECDSA en base64 | Sí | `__GENERATE_EC_PUBLIC__` | Config | sí |
| `DEV_SENDGRID_WEBHOOK_PRIVATE_KEY` | dev-stubs | clave privada ECDSA en base64; solo development | No | `__GENERATE_EC_PRIVATE__` | Secreto | sí |

#### Medios y documentos

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `CLOUDINARY_CLOUD_NAME` | api, dev-stubs | texto | Sí | `pe-local` | Config | sí |
| `CLOUDINARY_API_KEY` | api, dev-stubs | texto | Sí | `pe-local-key` | Config | sí |
| `CLOUDINARY_API_SECRET` | api, dev-stubs | secreto de 32 o más | Sí | `__GENERATE_HEX__` | Secreto | sí |
| `CLOUDINARY_UPLOAD_BASE_URL` | api, web | URL pública de carga usada por el navegador y la CSP | Sí | `http://localhost:4010/cloudinary` | Config | sí |
| `CLOUDINARY_API_BASE_URL` | api | URL de la API de verificación | Sí | `http://dev-stubs:4010/cloudinary` | Config | sí |
| `MEDIA_ALLOWED_IMAGE_TYPES` | api | lista MIME separada por comas | No | `image/jpeg,image/png,image/webp` | Config | sí |
| `MEDIA_ALLOWED_VIDEO_TYPES` | api | lista MIME separada por comas | No | `video/mp4` | Config | sí |
| `MEDIA_MAX_IMAGE_BYTES` | api | entero mayor que 0 | Sí | `10485760` | Config | sí |
| `MEDIA_MAX_VIDEO_BYTES` | api | entero mayor que 0 | Sí | `104857600` | Config | sí |
| `MEDIA_MAX_VIDEO_SECONDS` | api | entero mayor que 0 | Sí | `60` | Config | sí |
| `DOCUMENT_STORAGE_DRIVER` | api, worker | enum local; solo development y test hasta Etapa 2 | Sí | `local` | Config | sí |
| `DOCUMENT_STORAGE_PATH` | api, worker | ruta absoluta dentro del contenedor | Si local | `/var/lib/pe/documents` | Config | no |
| `DOCUMENT_URL_SIGNING_KEY` | api | secreto de 32 o más | Si local | `__GENERATE_HEX__` | Secreto | sí |
| `DOCUMENT_URL_TTL_SECONDS` | api | entero 30-900 | No (300) | `300` | Config | sí |

#### Mapas (opcional)

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `MAPS_PROVIDER` | api, web | enum disabled, google | No (disabled) | `disabled` | Config | sí |
| `GOOGLE_MAPS_SERVER_KEY` | api | secreto | Si google | (vacío) | Secreto | sí |
| `MAPS_BROWSER_KEY` | web | clave pública restringida por dominio y API, entregada en ejecución | Si google | (vacío) | Config | sí |

#### Límites, plazos y procesamiento

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `RATE_LIMIT_CATALOG_PER_MINUTE` | api | entero | No (120) | `120` | Config | sí |
| `RATE_LIMIT_MAGIC_FAILURES_PER_10_MINUTES` | api | entero | No (10) | `10` | Config | sí |
| `RATE_LIMIT_MAGIC_TOKEN_PER_HOUR` | api | entero | No (20) | `20` | Config | sí |
| `RATE_LIMIT_ASSISTED_IMPORT_PER_HOUR` | api | entero | No (30) | `30` | Config | sí |
| `RATE_LIMIT_REGISTRATION_PER_HOUR` | api | entero | No (5) | `5` | Config | sí |
| `RATE_LIMIT_WRITES_PER_MINUTE` | api | entero | No (300) | `300` | Config | sí |
| `CANCELLATION_RESPONSE_HOURS` | api, worker | entero mayor que 0 | No (72) | `72` | Config | sí |
| `COMPLETION_WINDOW_DAYS` | api, worker | entero mayor que 0 | No (5) | `5` | Config | sí |
| `WORKER_CONCURRENCY` | worker | entero menor o igual que DB_POOL_MAX | No (10) | `10` | Config | sí |
| `OUTBOX_POLL_INTERVAL_MS` | worker | entero 1000-60000 | No (5000) | `5000` | Config | sí |
| `SEED_SYNTHETIC` | seed | booleano; solo development y test | No (false) | `true` | Config | sí |

#### Construcción y herramientas

| Variable | Servicio | Tipo/Formato | Obligatoria | Ejemplo seguro local | Clasificación: Config vs. Secreto | En .env |
|---|---|---|---|---|---|---|
| `NODE_IMAGE` | build | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `PG_IMAGE` | postgres, db-bootstrap, db-rls, psql, CI | imagen@digest PostgreSQL 16 | Sí | `(docker/images.env)` | Config | no |
| `PG_IMAGE_MIN` | CI y pruebas con PostgreSQL 15 | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `PGBOUNCER_IMAGE` | pgbouncer | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `REDIS_IMAGE` | redis, CI | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `MAILPIT_IMAGE` | mailpit | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `GITLEAKS_IMAGE` | secrets-scan, CI | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `SEMGREP_IMAGE` | CI | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `OASDIFF_IMAGE` | CI | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `HADOLINT_IMAGE` | CI | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `K6_IMAGE` | CI (carga *smoke*) | imagen@digest | Sí | `(docker/images.env)` | Config | no |
| `HOST_UID` | db-authoring | entero | No (1000) | `1000` | Config | no |
| `HOST_GID` | db-authoring | entero | No (1000) | `1000` | Config | no |
| `HEALTH_PORT` | api, worker (HEALTHCHECK de la imagen) | entero fijado por Compose | Sí | `4000` | Config | no |

### 3.3 Plantilla `.env.example`

Archivo versionado en la raíz. Los marcadores `__GENERATE_*__` los sustituye `scripts/dev/gen-env.sh` (§4.1).

```dotenv
# --- Comunes ---
APP_ENV=development
LOG_LEVEL=debug
FEATURE_E2_ENABLED=false

# --- Puertos locales publicados en 127.0.0.1 ---
WEB_PORT=3000
API_PORT=4000
MAILPIT_UI_PORT=8025
DEV_STUBS_PORT=4010

# --- Base de datos ---
POSTGRES_DB=proveeeventos
POSTGRES_USER=pe_admin
POSTGRES_PASSWORD=__GENERATE_HEX__
PE_MIGRATOR_PASSWORD=__GENERATE_HEX__
PE_API_PASSWORD=__GENERATE_HEX__
PE_WORKER_PASSWORD=__GENERATE_HEX__
PE_RETENTION_PASSWORD=__GENERATE_HEX__
PE_READONLY_PASSWORD=__GENERATE_HEX__
DB_POOL_MAX=10
DB_APPLY_RLS=false

# --- Redis ---
REDIS_PASSWORD=__GENERATE_HEX__

# --- Identidad, sesión y enlaces ---
AUTH0_ISSUER_BASE_URL=http://localhost:4010
AUTH0_BACKCHANNEL_BASE_URL=http://dev-stubs:4010
AUTH0_AUDIENCE=https://api.proveeeventos.test
AUTH0_CLIENT_ID=pe-web-local
AUTH0_CLIENT_SECRET=__GENERATE_HEX__
SESSION_COOKIE_KEYS=1:__GENERATE_B64__
SESSION_IDLE_TIMEOUT_SECONDS=86400
APP_BASE_URL=http://localhost:3000
TOKEN_DERIVATION_KEYS=1:__GENERATE_B64__
TOKEN_DERIVATION_ACTIVE_VERSION=1
TRUSTED_PROXY_CIDRS=172.16.0.0/12,192.168.0.0/16

# --- Correo ---
EMAIL_PROVIDER=smtp
EMAIL_FROM_ADDRESS=no-reply@proveeeventos.test
EMAIL_FROM_NAME="ProveeEventos local"
SMTP_HOST=mailpit
SMTP_PORT=1025
SENDGRID_API_KEY=
SENDGRID_API_BASE_URL=
SENDGRID_WEBHOOK_PUBLIC_KEY=__GENERATE_EC_PUBLIC__
DEV_SENDGRID_WEBHOOK_PRIVATE_KEY=__GENERATE_EC_PRIVATE__

# --- Medios y documentos ---
CLOUDINARY_CLOUD_NAME=pe-local
CLOUDINARY_API_KEY=pe-local-key
CLOUDINARY_API_SECRET=__GENERATE_HEX__
CLOUDINARY_UPLOAD_BASE_URL=http://localhost:4010/cloudinary
CLOUDINARY_API_BASE_URL=http://dev-stubs:4010/cloudinary
MEDIA_ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/webp
MEDIA_ALLOWED_VIDEO_TYPES=video/mp4
MEDIA_MAX_IMAGE_BYTES=10485760
MEDIA_MAX_VIDEO_BYTES=104857600
MEDIA_MAX_VIDEO_SECONDS=60
DOCUMENT_STORAGE_DRIVER=local
DOCUMENT_URL_SIGNING_KEY=__GENERATE_HEX__
DOCUMENT_URL_TTL_SECONDS=300

# --- Mapas (opcional) ---
MAPS_PROVIDER=disabled
GOOGLE_MAPS_SERVER_KEY=
MAPS_BROWSER_KEY=

# --- Límites, plazos y procesamiento ---
RATE_LIMIT_CATALOG_PER_MINUTE=120
RATE_LIMIT_MAGIC_FAILURES_PER_10_MINUTES=10
RATE_LIMIT_MAGIC_TOKEN_PER_HOUR=20
RATE_LIMIT_ASSISTED_IMPORT_PER_HOUR=30
RATE_LIMIT_REGISTRATION_PER_HOUR=5
RATE_LIMIT_WRITES_PER_MINUTE=300
CANCELLATION_RESPONSE_HOURS=72
COMPLETION_WINDOW_DAYS=5
WORKER_CONCURRENCY=10
OUTBOX_POLL_INTERVAL_MS=5000
SEED_SYNTHETIC=true
```

### 3.4 Validación estricta al arranque (*fail-fast*)

**Regla:** ningún proceso (`api`, `worker`, `web`, `migrate`, `seed`) abre puertos, consume colas ni se conecta a la base antes de validar su configuración. Ante cualquier variable faltante o inválida termina con código **78** y registra solo **nombres y motivos, nunca valores**.

| Proceso | Ubicación del esquema | Punto de validación |
|---|---|---|
| `api` | `backend/src/shared/config/env.ts` (`apiEnvSchema`) | Primera instrucción de `backend/src/bootstrap/server.ts` |
| `worker` | mismo archivo (`workerEnvSchema`) | Primera instrucción de `backend/src/bootstrap/worker.ts` |
| `seed` | mismo archivo (`seedEnvSchema`) | Primera instrucción de `backend/src/prisma/seed/index.ts` |
| `web` | `frontend/src/lib/config/env.ts` (`server-only`) | `register()` de `frontend/src/instrumentation.ts`; no se valida durante `next build` |
| `migrate` | Prisma CLI | `env("DIRECT_URL")` en `prisma.config.ts` |

```ts
// backend/src/shared/config/env.ts — contrato; completar con todas las variables de §3.2
import { z } from 'zod';

const flag = z.enum(['true', 'false']).transform((v) => v === 'true');
const int = (min: number, max: number) => z.coerce.number().int().min(min).max(max);
const secret = z.string().min(32).refine((v) => !v.includes('__GENERATE'), 'marcador sin generar');
const keyList = z
  .string()
  .regex(/^\d+:[A-Za-z0-9+/]{43}=(,\d+:[A-Za-z0-9+/]{43}=)?$/, 'formato version:base64 de 32 bytes');
const pgUrl = (user: string) =>
  z.url().refine((v) => v.startsWith('postgresql://') && new URL(v).username === user, `usuario ${user}`);

const base = z.object({
  APP_ENV: z.enum(['development', 'test', 'staging', 'production']),
  NODE_ENV: z.enum(['development', 'production', 'test']),
  TZ: z.literal('UTC'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
});

export const apiEnvSchema = base
  .extend({
    API_PORT: int(1024, 65535).default(4000),
    DATABASE_URL: pgUrl('pe_api'),
    DB_POOL_MAX: int(1, 50).default(10),
    REDIS_URL: z.url(),
    AUTH0_ISSUER_BASE_URL: z.url(),
    AUTH0_BACKCHANNEL_BASE_URL: z.url().optional(),
    AUTH0_AUDIENCE: z.string().min(1),
    TOKEN_DERIVATION_KEYS: keyList,
    TOKEN_DERIVATION_ACTIVE_VERSION: int(1, 999),
    DOCUMENT_URL_SIGNING_KEY: secret,
    CLOUDINARY_API_SECRET: secret,
    FEATURE_E2_ENABLED: flag.default(false),
    // …resto de variables cuyo servicio incluye `api`
  })
  .superRefine(applyCrossRules);

export function loadEnv<T>(
  schema: z.ZodType<T>,
  source: Readonly<Record<string, string | undefined>>,
  fail: (problems: readonly string[]) => never,
): Readonly<T> {
  const cleaned = Object.fromEntries(Object.entries(source).filter(([, v]) => v !== ''));
  const result = schema.safeParse(cleaned);
  if (!result.success) {
    return fail(result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`));
  }
  return Object.freeze(result.data);
}
```

`applyCrossRules` implementa la tabla siguiente. `fail` registra con el logger Pino de arranque (`ADR-OBS-001`: sin `console`) y llama `process.exit(78)`. Los mensajes de Zod no deben incluir el valor recibido.

| Regla | Condición | Error si no se cumple |
|---|---|---|
| ENV-01 | `APP_ENV` en `staging` o `production` ⇒ `NODE_ENV=production`, `EMAIL_PROVIDER=sendgrid`, toda URL pública `https://`, sin `AUTH0_BACKCHANNEL_BASE_URL`, `SENDGRID_API_BASE_URL` ni `DEV_*`, `SEED_SYNTHETIC` distinto de `true` | opción solo local |
| ENV-02 | Ningún valor contiene `__GENERATE` | marcador sin generar |
| ENV-03 | `EMAIL_PROVIDER=smtp` ⇒ `SMTP_HOST` y `SMTP_PORT`; `sendgrid` ⇒ `SENDGRID_API_KEY` | variable condicional ausente |
| ENV-04 | `MAPS_PROVIDER=google` ⇒ `GOOGLE_MAPS_SERVER_KEY` (api) y `MAPS_BROWSER_KEY` (web) | variable condicional ausente |
| ENV-05 | `DATABASE_URL` con usuario `pe_api` en `api` y `pe_worker` en `worker`; `RETENTION_DATABASE_URL` con `pe_retention`; `DIRECT_URL` con `pe_migrator`. Nunca `pe_owner` ni el administrador (`ADR-DATA-009 R1`) | rol no permitido |
| ENV-06 | `TOKEN_DERIVATION_ACTIVE_VERSION` existe en `TOKEN_DERIVATION_KEYS`; `SESSION_COOKIE_KEYS` admite 1 o 2 versiones (`ADR-SEC-002 R7`) | versión de clave inexistente |
| ENV-07 | `WORKER_CONCURRENCY ≤ DB_POOL_MAX` (TDD §7.3) | pool insuficiente |
| ENV-08 | `DOCUMENT_STORAGE_DRIVER=local` solo en `development` y `test` | almacenamiento no definido para el ambiente |

**Pruebas obligatorias:** por cada regla, un caso válido y uno inválido en `backend/src/tests/unit/config/env.spec.ts`; además una prueba que compara las claves de los esquemas con las variables de `.env.example` y falla si difieren (`DC-08`).

---
---

## Sección 4 — Gestión de Secretos

Normativa: `ADR-SEC-005`, `ADR-STACK-004`, SAD §9.1 y §11.1.

### 4.1 Local

1. `.env` está excluido de Git por `.gitignore` (`.env`, `.env.*`, salvo `.env.example`). También `*.pem`.
2. Las credenciales son **sintéticas, aleatorias y exclusivas de la máquina**. No se copian entre desarrolladores ni se usan en GitHub ni en ambientes remotos.
3. Se generan con un único script reproducible; nadie escribe contraseñas a mano.
4. Regenerar secretos con la base ya creada exige reaplicar `db-bootstrap` (cambia las contraseñas de los roles) y reiniciar los servicios. `POSTGRES_PASSWORD` solo se aplica al crear el volumen: cambiarla exige reset (§8.4).
5. Rotar `TOKEN_DERIVATION_KEYS` o `SESSION_COOKIE_KEYS` se hace **añadiendo** una versión nueva, nunca sustituyendo la anterior mientras haya enlaces o sesiones vigentes.

`scripts/dev/gen-env.sh` (modo `0755`):

```bash
#!/usr/bin/env bash
# Genera .env a partir de .env.example con secretos sintéticos. Solo desarrollo local.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
template="$root/.env.example"
target="$root/.env"
if [[ -e "$target" && "${1:-}" != "--force" ]]; then
  echo ".env ya existe; usa --force para regenerarlo" >&2
  exit 1
fi
umask 077

private_key="$(openssl ecparam -name prime256v1 -genkey -noout | openssl ec -outform DER 2>/dev/null | base64 | tr -d '\n')"
public_key="$(printf '%s' "$private_key" | base64 -d | openssl ec -inform DER -pubout -outform DER 2>/dev/null | base64 | tr -d '\n')"

tmp="$(mktemp "$target.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
while IFS= read -r line || [[ -n "$line" ]]; do
  while [[ "$line" == *__GENERATE_HEX__* ]]; do line="${line/__GENERATE_HEX__/$(openssl rand -hex 32)}"; done
  while [[ "$line" == *__GENERATE_B64__* ]]; do line="${line/__GENERATE_B64__/$(openssl rand -base64 32)}"; done
  line="${line/__GENERATE_EC_PUBLIC__/$public_key}"
  line="${line/__GENERATE_EC_PRIVATE__/$private_key}"
  printf '%s\n' "$line"
done <"$template" >"$tmp"
mv "$tmp" "$target"
trap - EXIT
echo "Generado $target"
```

Quien quiera usar cuentas de desarrollo reales (Auth0, SendGrid, Cloudinary, Maps) sustituye las variables correspondientes **solo en su `.env`**, con cuentas distintas de cualquier otro ambiente.

### 4.2 GitHub Actions

#### Configuración no sensible: *Repository variables*

| Nombre | Uso |
|---|---|
| `AI_REVIEWER_PROVIDER` | Identificador del adaptador del revisor (`INFRA-P-15`) |
| `AI_REVIEWER_MODEL` | Modelo fijado; un cambio es una decisión humana |
| `AI_REVIEWER_BASE_URL` | URL del servicio del revisor, si el adaptador la requiere |

La lista de aprobadores humanos **no** es una variable: es el archivo protegido `.github/adr-guard/approvers.yml`, leído de la rama base (`ADR-GOV-006`).

#### Datos sensibles: *Secrets*

| Nombre | Alcance | Consumidor | Notas |
|---|---|---|---|
| `AI_REVIEWER_API_KEY` | Environment `ai-reviewer`, limitado a la rama `main` | Job `ai-review` de `ai-reviewer.yml` | Clave con cuota y permisos mínimos; nunca disponible para código del PR |
| `GOVERNANCE_READ_TOKEN` | Environment `governance`, limitado a `main` | Job programado de comparación del Ruleset (`ADR-GOV-007`) | Solo lectura de administración del repositorio |

- Las pruebas de CI **no usan secretos almacenados**: cada job genera valores sintéticos con `gen-env.sh` (`APP_ENV=test`).
- No existen secretos de despliegue en Etapa 1.

#### Mínimo privilegio de `GITHUB_TOKEN`

1. Ajuste del repositorio: permisos por defecto de solo lectura y **desactivado** "permitir que GitHub Actions cree y apruebe Pull Requests".
2. Cada workflow declara `permissions: {}` en la raíz y concede por job:

| Job | Permisos |
|---|---|
| Jobs de `ci-quality-and-tests.yml` | `contents: read` (`actions: read` solo donde se descarga la cobertura de `main`) |
| `adr-guard` | `contents: read`, `pull-requests: read` |
| `ai-review` | `contents: read`, `pull-requests: write` (comentar), `checks: read` |
| `human-approval`, `ai-reviewer` | ninguno |

3. `actions/checkout` siempre con `persist-credentials: false`.
4. **Jobs que ejecutan código del PR** (`pull_request`) no reciben secretos ni permisos de escritura. **Jobs con privilegios** (`pull_request_target`) nunca instalan dependencias, ejecutan scripts ni construyen desde la cabecera del PR: la tratan como datos.
5. Los PR desde forks requieren aprobación manual para ejecutar workflows.
6. Todas las acciones se fijan por SHA de commit (§7.1).

### 4.3 Prevención de fugas

| Control | Dónde | Comportamiento |
|---|---|---|
| `gitleaks` sobre el rango de commits del PR | `adr-guard` (imagen fijada, configuración de la rama base en `Tools/adr-guard/gitleaks.toml`) | Cualquier hallazgo falla el check (`ADR-SEC-005 R5`) |
| `gitleaks` sobre el árbol de trabajo | Local: `npm run secrets:scan` | Recomendado antes de cada push |
| Veto de rutas | `adr-guard` | Falla ante `.env*` distinto de `.env.example`, `*.pem` y nombres `NEXT_PUBLIC_*(SECRET\|TOKEN\|PRIVATE)*` |
| Sin excepciones en línea | `adr-guard` | `gitleaks:allow` está prohibido (`ADR-GOV-003`) |
| *Secret scanning* y *push protection* de GitHub | Repositorio | Activar si el plan los ofrece (`INFRA-P-14`); no sustituyen a `gitleaks` |
| Registros | Aplicación y CI | Sin valores de configuración en logs; prohibido `set -x` en pasos que manejen secretos; redacción en el logger (`ADR-OBS-002`) |
| Imágenes | Build | Sin secretos en `ARG`, `ENV` ni capas; `.dockerignore` excluye `.env*` y `*.pem` |

**Respuesta ante una fuga:** revocar y rotar el secreto de inmediato, eliminar su uso, registrar el incidente en el PR y reescribir historial solo con aprobación humana. Un secreto publicado se considera comprometido aunque se borre.

### 4.4 Diferido

La selección de un gestor de secretos productivo, la inyección en ambientes remotos, la identidad federada de CI hacia la nube y el calendario operativo de rotación quedan **diferidos por infraestructura pendiente** (`INFRA-P-08`). Se mantienen los requisitos ya fijados: secretos fuera del repositorio, rotación al menos anual de secreto de cliente de Auth0 y clave de sesión (SAD §9.1) y dos versiones de clave de sesión activas.

---
## Sección 5 — Entorno y Despliegue Local con Docker y Docker Compose

Requisitos del equipo: Docker Engine con Compose v2.24 o superior (necesario para `--env-file` múltiple y `up --watch`), Node.js 26.x y npm (para pruebas y scripts), `openssl` y `bash`.

### 5.1 Topología local

```mermaid
flowchart LR
  subgraph HOST["Equipo del desarrollador (puertos solo en 127.0.0.1)"]
    B["Navegador"]
  end
  subgraph EDGE["Red edge"]
    W["web :3000<br/>Next.js BFF"]
    A["api :4000<br/>Express"]
    K["worker :4001<br/>BullMQ"]
    S["dev-stubs :4010<br/>Auth0, Cloudinary, webhook"]
    M["mailpit :8025 / :1025"]
  end
  subgraph DATA["Red data (internal, sin salida)"]
    P[("postgres :5432")]
    PB["pgbouncer :5432<br/>transaction"]
    R[("redis :6379")]
    BS["db-bootstrap (una vez)"] --> MG["migrate (una vez)"] --> RL["db-rls (una vez)"] --> SD["seed (una vez)"]
  end
  B --> W
  B -->|login y carga de medios| S
  B -->|webhooks y pruebas manuales| A
  W -->|API_BASE_URL| A
  W --> S
  A --> S
  A --> PB
  A --> R
  K --> PB
  K --> R
  K --> M
  PB --> P
  BS --> P
  MG --> P
  RL --> P
  SD --> P
```

`web` no pertenece a la red `data`: no puede alcanzar PostgreSQL ni Redis, coherente con `ADR-ARCH-008 R1`.

### 5.2 Imágenes base fijadas

**`docker/images.env`**

```dotenv
# Imágenes fijadas por etiqueta y digest (verificadas en el registro el 2026-11-25).
# Cambiar una línea es un cambio de dependencia: exige PR y aprobación humana.
NODE_IMAGE=node:26.13.1-bookworm-slim@sha256:0042e17d232a87a2cd485be1da7900fca4d10a4ad11b29e9285da1d2e54798c9
PG_IMAGE=postgres:16.16-bookworm@sha256:cd0e9518bda5f2ea667ff84d22795d089720c883f288e215d97ce57437e8ef37
PG_IMAGE_MIN=postgres:15.20-bookworm@sha256:0cb925629e7eb35c77276f3165440d1670c35c2ddbe92b346c579299b75a520f
PGBOUNCER_IMAGE=edoburu/pgbouncer:v1.26.1-p0@sha256:488422e38cff912895d0d65d8963fcd306e6ac589a724398b6eb8e294e94d624
REDIS_IMAGE=redis:7.4.12-bookworm@sha256:6b645a37f49b0546582468706b32e71a8b7fbb5ba4583d0f9e27a8004716b738
MAILPIT_IMAGE=axllent/mailpit:v1.34.0@sha256:23a2ef85bc50853ab3093645d1d64679afd8887e89da5e48a88940c172591a4e
GITLEAKS_IMAGE=zricethezav/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f
SEMGREP_IMAGE=semgrep/semgrep:1.187.0@sha256:0c8dfa7aa1ca8c50233ec9110e8cd88d139dedd603d56507493f74c6f4b3e062
OASDIFF_IMAGE=tufin/oasdiff:v1.39.0@sha256:004bef22058ace818b61f0eb2f05efb89fc6a3882f68bf4db0b6a86f40723fe0
K6_IMAGE=grafana/k6:2.4.0@sha256:d41bb79cd8de5a7ad619b53570e3712633e8bff0937010a5c6c57a4747e7a276
HADOLINT_IMAGE=hadolint/hadolint:v2.15.1@sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d
```

### 5.3 Dockerfiles *multi-stage* y `.dockerignore`

| Etapa | `backend/Dockerfile` | `frontend/Dockerfile` | Uso |
|---|---|---|---|
| `base` | Node fijado, `openssl` | Node fijado | Común |
| `deps` | `npm ci` del workspace | `npm ci` del workspace | Dependencias reproducibles (`ADR-STACK-003 R2`) |
| `builder` | `prisma generate`, `tsc`, `npm prune --omit=dev` | `next build` (salida `standalone`) | Compilación |
| `dev` | Código y recarga | `next dev` | Perfil `dev` |
| `migrate` | CLI de Prisma y migraciones | — | Servicio `migrate` |
| `runner` | Solo `dist` y dependencias de ejecución | Salida `standalone` | Perfil `test` y futuro despliegue |

Reglas obligatorias: usuario `node` (no root) en todas las etapas ejecutables; `HEALTHCHECK` en `runner`; ningún secreto en `ARG`, `ENV` o capas (la URL de `build` es ficticia y sin contraseña); contexto de build en la raíz; sin etiqueta `latest`.

**`backend/Dockerfile`**

```dockerfile
# Contexto de build: raíz del repositorio. NODE_IMAGE viene de docker/images.env.
# Mismo valor que docker/images.env (única fuente; el CI verifica la igualdad).
ARG NODE_IMAGE=node:26.13.1-bookworm-slim@sha256:0042e17d232a87a2cd485be1da7900fca4d10a4ad11b29e9285da1d2e54798c9

FROM ${NODE_IMAGE} AS base
ENV TZ=UTC NPM_CONFIG_UPDATE_NOTIFIER=false NPM_CONFIG_FUND=false
WORKDIR /app
# openssl lo requiere el motor de migraciones de Prisma.
RUN apt-get update \
  && apt-get install --yes --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

FROM base AS deps
COPY package.json package-lock.json .npmrc ./
COPY backend/package.json backend/
COPY frontend/package.json frontend/
RUN npm ci --workspace backend --include-workspace-root

FROM deps AS builder
COPY tsconfig.base.json ./
COPY backend backend
# URL ficticia: generate no se conecta, pero prisma.config.ts exige la variable.
RUN DIRECT_URL=postgresql://build@127.0.0.1:5432/build npm run prisma:generate --workspace backend \
  && npm run build --workspace backend \
  && npm prune --omit=dev --workspace backend --include-workspace-root \
  && mkdir -p backend/node_modules

FROM deps AS dev
ENV NODE_ENV=development HEALTH_PORT=4000
COPY --chown=node:node tsconfig.base.json ./
COPY --chown=node:node backend backend
RUN DIRECT_URL=postgresql://build@127.0.0.1:5432/build npm run prisma:generate --workspace backend \
  && npm run build --workspace backend \
  && mkdir -p /var/lib/pe/documents \
  && chown -R node:node /app/backend /var/lib/pe
USER node
CMD ["npm", "run", "dev:api", "--workspace", "backend"]

FROM deps AS migrate
ENV NODE_ENV=production
COPY --chown=node:node backend/prisma.config.ts backend/
COPY --chown=node:node backend/src/prisma backend/src/prisma
USER node
WORKDIR /app/backend
CMD ["npx", "--no-install", "prisma", "migrate", "deploy"]

FROM base AS runner
ENV NODE_ENV=production HEALTH_PORT=4000
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/backend/package.json backend/
COPY --from=builder /app/backend/node_modules backend/node_modules
COPY --from=builder /app/backend/dist backend/dist
RUN mkdir -p /var/lib/pe/documents && chown node:node /var/lib/pe/documents
USER node
WORKDIR /app/backend
EXPOSE 4000 4001
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:'+process.env.HEALTH_PORT+'/health/live').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
CMD ["node", "--enable-source-maps", "dist/bootstrap/server.js"]
```

**`frontend/Dockerfile`**

```dockerfile
# Contexto de build: raíz del repositorio. NODE_IMAGE viene de docker/images.env.
# Mismo valor que docker/images.env (única fuente; el CI verifica la igualdad).
ARG NODE_IMAGE=node:26.13.1-bookworm-slim@sha256:0042e17d232a87a2cd485be1da7900fca4d10a4ad11b29e9285da1d2e54798c9

FROM ${NODE_IMAGE} AS base
ENV TZ=UTC NPM_CONFIG_UPDATE_NOTIFIER=false NPM_CONFIG_FUND=false NEXT_TELEMETRY_DISABLED=1
WORKDIR /app

FROM base AS deps
COPY package.json package-lock.json .npmrc ./
COPY backend/package.json backend/
COPY frontend/package.json frontend/
RUN npm ci --workspace frontend --include-workspace-root

FROM deps AS builder
COPY tsconfig.base.json ./
COPY frontend frontend
RUN mkdir -p frontend/public && npm run build --workspace frontend

FROM deps AS dev
ENV NODE_ENV=development
COPY --chown=node:node tsconfig.base.json ./
COPY --chown=node:node frontend frontend
RUN mkdir -p frontend/.next && chown -R node:node /app/frontend
USER node
CMD ["npm", "run", "dev", "--workspace", "frontend", "--", "--hostname", "0.0.0.0", "--port", "3000"]

FROM base AS runner
ENV NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3000
COPY --from=builder /app/frontend/.next/standalone ./
COPY --from=builder /app/frontend/.next/static frontend/.next/static
COPY --from=builder /app/frontend/public frontend/public
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health/live').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
CMD ["node", "frontend/server.js"]
```

**`Tools/dev-stubs/Dockerfile`**

```dockerfile
# Dobles locales de Auth0, SendGrid (webhook) y Cloudinary. Sin dependencias: Node ejecuta TypeScript directamente.
# Mismo valor que docker/images.env (única fuente; el CI verifica la igualdad).
ARG NODE_IMAGE=node:26.13.1-bookworm-slim@sha256:0042e17d232a87a2cd485be1da7900fca4d10a4ad11b29e9285da1d2e54798c9
FROM ${NODE_IMAGE} AS runner
ENV NODE_ENV=development TZ=UTC
WORKDIR /app
COPY --chown=node:node Tools/dev-stubs/ ./
USER node
EXPOSE 4010
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:4010/health/live').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
CMD ["node", "server.ts"]
```

**`.dockerignore`**

```text
# Lista de permitidos: todo queda fuera salvo lo declarado.
**
!package.json
!package-lock.json
!.npmrc
!tsconfig.base.json
!backend
!frontend
!Tools/dev-stubs
**/node_modules
**/dist
**/.next
**/coverage
**/generated/prisma
**/.env
**/.env.*
**/*.pem
**/*.log
**/.git
backend/src/tests
frontend/tests
```

**Requisitos que los Dockerfiles imponen al código** (parte del handoff):

| Requisito | Detalle |
|---|---|
| Workspaces npm | `package.json` raíz con `workspaces: ["backend","frontend"]`, un solo `package-lock.json` (`DC-02`) |
| Entradas del backend | `backend/src/bootstrap/server.ts` y `worker.ts` compilan a `dist/bootstrap/*.js` (`ADR-ARCH-001`) |
| Scripts del backend | `prisma:generate`, `build`, `dev:api`, `dev:worker` (`tsc --watch` junto a `node --watch` sobre `dist`; sin dependencias nuevas) |
| Salud | `/health/live` y `/health/ready` en API (`:4000`) y worker (`:4001`) (SAD §10.8); `web` expone `/health/live` sin dependencias (`DC-11`) |
| Next.js | `output: 'standalone'` y `outputFileTracingRoot` en la raíz del monorepositorio |
| Prisma | `backend/prisma.config.ts` con `schema: 'src/prisma/schema.prisma'`, `datasource.url` desde `DIRECT_URL` y `shadowDatabaseUrl` solo si `SHADOW_DATABASE_URL` existe |
| Apagado | `api` y `worker` atienden `SIGTERM`: dejan de aceptar trabajo, terminan lo en curso y cierran conexiones en menos de 30 s |

### 5.4 `docker-compose.yml`

#### 5.4.1 Servicios, perfiles y dependencias

| Servicio | Perfil | Puerto en el equipo | Redes | Volumen | Salud | Arranca tras |
|---|---|---|---|---|---|---|
| `postgres` | siempre | ninguno | data | `pgdata` | `pg_isready -h 127.0.0.1` | — |
| `db-bootstrap` | siempre (una vez) | — | data | — | código de salida 0 | `postgres` sano |
| `pgbouncer` | siempre | ninguno | data | — | `pg_isready` | `db-bootstrap` completado |
| `redis` | siempre | ninguno | data | `redisdata` | `redis-cli ping` | — |
| `migrate` | siempre (una vez) | — | data | — | código 0 | `db-bootstrap` completado |
| `db-rls` | siempre (una vez) | — | data | — | código 0 | `migrate` completado |
| `seed` | `dev`, `test` (una vez) | — | data | — | código 0 | `db-rls` completado |
| `mailpit` | `dev`, `test` | 8025 (interfaz) | edge, data | — | `/mailpit readyz` | — |
| `dev-stubs` | `dev`, `test` | 4010 | edge | — | `HEALTHCHECK` de la imagen | — |
| `api` | `dev` | 4000 | edge, data | `documents` | `/health/ready` | `seed`, `pgbouncer`, `redis`, `dev-stubs` |
| `worker` | `dev` | ninguno | edge, data | `documents` | `/health/ready` | `seed`, `pgbouncer`, `redis`, `mailpit` |
| `web` | `dev` | 3000 | edge | — | `/health/live` | `api`, `dev-stubs` |
| `api-test` (alias `api`) | `test` | 4000 | edge, data | `documents` | `/health/ready` | como `api` |
| `worker-test` | `test` | ninguno | edge, data | `documents` | `/health/ready` | como `worker` |
| `web-test` | `test` | 3000 | edge | — | `/health/live` | `api-test`, `dev-stubs` |
| `psql` | `tools` | — | data | — | — | `postgres` |
| `db-authoring` | `tools` | — | data | monta `backend/src/prisma` | — | `db-bootstrap` |
| `secrets-scan` | `tools` | — | ninguna | repositorio en solo lectura | — | — |

Sin perfil se levanta solo la infraestructura; `migrate` necesita el código para construirse. PostgreSQL y Redis **no publican puertos**: se accede con `npm run db:psql`. Los perfiles `dev` y `test` comparten puertos: no se levantan a la vez en el mismo equipo; `test` usa el proyecto `pe-test`, con volúmenes propios y desechables.

**`docker-compose.yml`**

```yaml
# Entorno local de ProveeEventos (Etapa 1). Las imágenes proveeeventos/* son locales: pull_policy impide
# buscarlas en un registro público. Se invoca siempre con:
#   docker compose --env-file docker/images.env --env-file .env ...
name: proveeeventos

x-backend-build: &backend-build
  context: .
  dockerfile: backend/Dockerfile
  args:
    NODE_IMAGE: ${NODE_IMAGE:?falta docker/images.env}

x-hardening: &hardening
  security_opt: ["no-new-privileges:true"]
  cap_drop: ["ALL"]
  init: true

x-common-env: &common-env
  APP_ENV: ${APP_ENV:?define APP_ENV}
  TZ: UTC
  LOG_LEVEL: ${LOG_LEVEL:-info}
  FEATURE_E2_ENABLED: ${FEATURE_E2_ENABLED:-false}

x-redis-env: &redis-env
  REDIS_URL: redis://:${REDIS_PASSWORD:?}@redis:6379/0

x-token-env: &token-env
  APP_BASE_URL: ${APP_BASE_URL:?}
  TOKEN_DERIVATION_KEYS: ${TOKEN_DERIVATION_KEYS:?}
  TOKEN_DERIVATION_ACTIVE_VERSION: ${TOKEN_DERIVATION_ACTIVE_VERSION:?}

x-documents-env: &documents-env
  DOCUMENT_STORAGE_DRIVER: ${DOCUMENT_STORAGE_DRIVER:?}
  DOCUMENT_STORAGE_PATH: /var/lib/pe/documents

x-deadlines-env: &deadlines-env
  CANCELLATION_RESPONSE_HOURS: ${CANCELLATION_RESPONSE_HOURS:-72}
  COMPLETION_WINDOW_DAYS: ${COMPLETION_WINDOW_DAYS:-5}

x-api-env: &api-env
  <<: [*common-env, *redis-env, *token-env, *documents-env, *deadlines-env]
  API_PORT: "4000"
  HEALTH_PORT: "4000"
  DATABASE_URL: postgresql://pe_api:${PE_API_PASSWORD:?}@pgbouncer:5432/${POSTGRES_DB:?}
  DB_POOL_MAX: ${DB_POOL_MAX:-10}
  AUTH0_ISSUER_BASE_URL: ${AUTH0_ISSUER_BASE_URL:?}
  AUTH0_BACKCHANNEL_BASE_URL: ${AUTH0_BACKCHANNEL_BASE_URL:-}
  AUTH0_AUDIENCE: ${AUTH0_AUDIENCE:?}
  TRUSTED_PROXY_CIDRS: ${TRUSTED_PROXY_CIDRS:?}
  SENDGRID_WEBHOOK_PUBLIC_KEY: ${SENDGRID_WEBHOOK_PUBLIC_KEY:?}
  CLOUDINARY_CLOUD_NAME: ${CLOUDINARY_CLOUD_NAME:?}
  CLOUDINARY_API_KEY: ${CLOUDINARY_API_KEY:?}
  CLOUDINARY_API_SECRET: ${CLOUDINARY_API_SECRET:?}
  CLOUDINARY_UPLOAD_BASE_URL: ${CLOUDINARY_UPLOAD_BASE_URL:?}
  CLOUDINARY_API_BASE_URL: ${CLOUDINARY_API_BASE_URL:?}
  MEDIA_ALLOWED_IMAGE_TYPES: ${MEDIA_ALLOWED_IMAGE_TYPES:-image/jpeg,image/png,image/webp}
  MEDIA_ALLOWED_VIDEO_TYPES: ${MEDIA_ALLOWED_VIDEO_TYPES:-video/mp4}
  MEDIA_MAX_IMAGE_BYTES: ${MEDIA_MAX_IMAGE_BYTES:?}
  MEDIA_MAX_VIDEO_BYTES: ${MEDIA_MAX_VIDEO_BYTES:?}
  MEDIA_MAX_VIDEO_SECONDS: ${MEDIA_MAX_VIDEO_SECONDS:?}
  DOCUMENT_URL_SIGNING_KEY: ${DOCUMENT_URL_SIGNING_KEY:?}
  DOCUMENT_URL_TTL_SECONDS: ${DOCUMENT_URL_TTL_SECONDS:-300}
  MAPS_PROVIDER: ${MAPS_PROVIDER:-disabled}
  GOOGLE_MAPS_SERVER_KEY: ${GOOGLE_MAPS_SERVER_KEY:-}
  RATE_LIMIT_CATALOG_PER_MINUTE: ${RATE_LIMIT_CATALOG_PER_MINUTE:-120}
  RATE_LIMIT_MAGIC_FAILURES_PER_10_MINUTES: ${RATE_LIMIT_MAGIC_FAILURES_PER_10_MINUTES:-10}
  RATE_LIMIT_MAGIC_TOKEN_PER_HOUR: ${RATE_LIMIT_MAGIC_TOKEN_PER_HOUR:-20}
  RATE_LIMIT_ASSISTED_IMPORT_PER_HOUR: ${RATE_LIMIT_ASSISTED_IMPORT_PER_HOUR:-30}
  RATE_LIMIT_REGISTRATION_PER_HOUR: ${RATE_LIMIT_REGISTRATION_PER_HOUR:-5}
  RATE_LIMIT_WRITES_PER_MINUTE: ${RATE_LIMIT_WRITES_PER_MINUTE:-300}

x-worker-env: &worker-env
  <<: [*common-env, *redis-env, *token-env, *documents-env, *deadlines-env]
  WORKER_HEALTH_PORT: "4001"
  HEALTH_PORT: "4001"
  DATABASE_URL: postgresql://pe_worker:${PE_WORKER_PASSWORD:?}@pgbouncer:5432/${POSTGRES_DB:?}
  RETENTION_DATABASE_URL: postgresql://pe_retention:${PE_RETENTION_PASSWORD:?}@pgbouncer:5432/${POSTGRES_DB:?}
  DB_POOL_MAX: ${DB_POOL_MAX:-10}
  EMAIL_PROVIDER: ${EMAIL_PROVIDER:?}
  EMAIL_FROM_ADDRESS: ${EMAIL_FROM_ADDRESS:?}
  EMAIL_FROM_NAME: ${EMAIL_FROM_NAME:-ProveeEventos}
  SMTP_HOST: ${SMTP_HOST:-}
  SMTP_PORT: ${SMTP_PORT:-}
  SENDGRID_API_KEY: ${SENDGRID_API_KEY:-}
  SENDGRID_API_BASE_URL: ${SENDGRID_API_BASE_URL:-}
  WORKER_CONCURRENCY: ${WORKER_CONCURRENCY:-10}
  OUTBOX_POLL_INTERVAL_MS: ${OUTBOX_POLL_INTERVAL_MS:-5000}

x-web-env: &web-env
  <<: *common-env
  AUTH0_ISSUER_BASE_URL: ${AUTH0_ISSUER_BASE_URL:?}
  AUTH0_BACKCHANNEL_BASE_URL: ${AUTH0_BACKCHANNEL_BASE_URL:-}
  AUTH0_AUDIENCE: ${AUTH0_AUDIENCE:?}
  AUTH0_CLIENT_ID: ${AUTH0_CLIENT_ID:?}
  AUTH0_CLIENT_SECRET: ${AUTH0_CLIENT_SECRET:?}
  SESSION_COOKIE_KEYS: ${SESSION_COOKIE_KEYS:?}
  SESSION_IDLE_TIMEOUT_SECONDS: ${SESSION_IDLE_TIMEOUT_SECONDS:-86400}
  APP_BASE_URL: ${APP_BASE_URL:?}
  API_BASE_URL: http://api:4000
  CLOUDINARY_UPLOAD_BASE_URL: ${CLOUDINARY_UPLOAD_BASE_URL:?}
  MAPS_PROVIDER: ${MAPS_PROVIDER:-disabled}
  MAPS_BROWSER_KEY: ${MAPS_BROWSER_KEY:-}

x-api-healthcheck: &api-healthcheck
  test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:4000/health/ready').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
  interval: 5s
  timeout: 3s
  retries: 30
  start_period: 20s

x-worker-healthcheck: &worker-healthcheck
  test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:4001/health/ready').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
  interval: 5s
  timeout: 3s
  retries: 30
  start_period: 20s

x-web-healthcheck: &web-healthcheck
  test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:3000/health/live').then((r)=>process.exit(r.ok?0:1),()=>process.exit(1))"]
  interval: 5s
  timeout: 3s
  retries: 30
  start_period: 30s

x-app-depends: &app-depends
  seed: { condition: service_completed_successfully }
  pgbouncer: { condition: service_healthy }
  redis: { condition: service_healthy }

services:
  # ---------- Infraestructura (sin perfil: siempre disponible) ----------
  postgres:
    image: ${PG_IMAGE:?}
    command: ["postgres", "-c", "max_connections=100"]
    environment:
      POSTGRES_DB: ${POSTGRES_DB:?}
      POSTGRES_USER: ${POSTGRES_USER:?}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?}
      POSTGRES_INITDB_ARGS: --encoding=UTF8 --auth-host=scram-sha-256
      TZ: UTC
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      # -h 127.0.0.1 evita el falso positivo del servidor temporal de inicialización.
      test: ["CMD-SHELL", 'pg_isready -h 127.0.0.1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"']
      interval: 5s
      timeout: 3s
      retries: 30
    networks: [data]
    restart: unless-stopped

  db-bootstrap:
    image: ${PG_IMAGE:?}
    user: postgres
    entrypoint: ["sh", "/scripts/bootstrap.sh"]
    environment:
      APP_ENV: ${APP_ENV:?}
      PGHOST: postgres
      PGUSER: ${POSTGRES_USER:?}
      PGPASSWORD: ${POSTGRES_PASSWORD:?}
      PGDATABASE: ${POSTGRES_DB:?}
      PE_MIGRATOR_PASSWORD: ${PE_MIGRATOR_PASSWORD:?}
      PE_API_PASSWORD: ${PE_API_PASSWORD:?}
      PE_WORKER_PASSWORD: ${PE_WORKER_PASSWORD:?}
      PE_RETENTION_PASSWORD: ${PE_RETENTION_PASSWORD:?}
      PE_READONLY_PASSWORD: ${PE_READONLY_PASSWORD:?}
    volumes:
      - ./backend/src/prisma/bootstrap:/bootstrap:ro
      - ./scripts/db:/scripts:ro
    depends_on:
      postgres: { condition: service_healthy }
    networks: [data]
    restart: "no"

  pgbouncer:
    <<: *hardening
    image: ${PGBOUNCER_IMAGE:?}
    entrypoint: ["sh", "/etc/pe/start.sh"]
    environment:
      POSTGRES_DB: ${POSTGRES_DB:?}
      PE_API_PASSWORD: ${PE_API_PASSWORD:?}
      PE_WORKER_PASSWORD: ${PE_WORKER_PASSWORD:?}
      PE_RETENTION_PASSWORD: ${PE_RETENTION_PASSWORD:?}
    volumes:
      - ./docker/pgbouncer:/etc/pe:ro
    tmpfs:
      - /tmp
    depends_on:
      db-bootstrap: { condition: service_completed_successfully }
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-p", "5432"]
      interval: 5s
      timeout: 3s
      retries: 20
    networks: [data]
    restart: unless-stopped

  redis:
    <<: *hardening
    image: ${REDIS_IMAGE:?}
    user: "999:999"
    command: ["sh", "-c", 'exec redis-server --appendonly yes --maxmemory-policy noeviction --requirepass "$$REDIS_PASSWORD"']
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD:?}
      REDISCLI_AUTH: ${REDIS_PASSWORD:?}
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD-SHELL", "redis-cli ping | grep -q PONG"]
      interval: 5s
      timeout: 3s
      retries: 20
    networks: [data]
    restart: unless-stopped

  migrate:
    <<: *hardening
    image: proveeeventos/migrate:local
    pull_policy: build
    build:
      <<: *backend-build
      target: migrate
    environment:
      APP_ENV: ${APP_ENV:?}
      TZ: UTC
      DIRECT_URL: postgresql://pe_migrator:${PE_MIGRATOR_PASSWORD:?}@postgres:5432/${POSTGRES_DB:?}
    depends_on:
      db-bootstrap: { condition: service_completed_successfully }
    networks: [data]
    restart: "no"

  db-rls:
    image: ${PG_IMAGE:?}
    user: postgres
    entrypoint: ["sh", "/scripts/apply-rls.sh"]
    environment:
      APP_ENV: ${APP_ENV:?}
      DB_APPLY_RLS: ${DB_APPLY_RLS:-false}
      PGHOST: postgres
      PGUSER: pe_migrator
      PGPASSWORD: ${PE_MIGRATOR_PASSWORD:?}
      PGDATABASE: ${POSTGRES_DB:?}
    volumes:
      - ./backend/src/prisma/rls:/rls:ro
      - ./scripts/db:/scripts:ro
    depends_on:
      migrate: { condition: service_completed_successfully }
    networks: [data]
    restart: "no"

  seed:
    <<: *hardening
    profiles: [dev, test]
    image: proveeeventos/backend:local
    pull_policy: build
    build:
      <<: *backend-build
      target: runner
    command: ["node", "dist/prisma/seed/index.js"]
    healthcheck:
      disable: true
    environment:
      <<: *common-env
      NODE_ENV: production
      SEED_SYNTHETIC: ${SEED_SYNTHETIC:-false}
      DIRECT_URL: postgresql://pe_migrator:${PE_MIGRATOR_PASSWORD:?}@postgres:5432/${POSTGRES_DB:?}
    depends_on:
      db-rls: { condition: service_completed_successfully }
    networks: [data]
    restart: "no"

  # ---------- Dobles locales ----------
  mailpit:
    <<: *hardening
    profiles: [dev, test]
    image: ${MAILPIT_IMAGE:?}
    ports:
      - "127.0.0.1:${MAILPIT_UI_PORT:-8025}:8025"
    healthcheck:
      test: ["CMD", "/mailpit", "readyz"]
      interval: 5s
      timeout: 3s
      retries: 20
    networks: [edge, data]

  dev-stubs:
    <<: *hardening
    profiles: [dev, test]
    image: proveeeventos/dev-stubs:local
    pull_policy: build
    build:
      context: .
      dockerfile: Tools/dev-stubs/Dockerfile
      args:
        NODE_IMAGE: ${NODE_IMAGE:?}
    environment:
      APP_ENV: ${APP_ENV:?}
      AUTH0_ISSUER_BASE_URL: ${AUTH0_ISSUER_BASE_URL:?}
      AUTH0_AUDIENCE: ${AUTH0_AUDIENCE:?}
      AUTH0_CLIENT_ID: ${AUTH0_CLIENT_ID:?}
      AUTH0_CLIENT_SECRET: ${AUTH0_CLIENT_SECRET:?}
      APP_BASE_URL: ${APP_BASE_URL:?}
      CLOUDINARY_CLOUD_NAME: ${CLOUDINARY_CLOUD_NAME:?}
      CLOUDINARY_API_KEY: ${CLOUDINARY_API_KEY:?}
      CLOUDINARY_API_SECRET: ${CLOUDINARY_API_SECRET:?}
      DEV_SENDGRID_WEBHOOK_PRIVATE_KEY: ${DEV_SENDGRID_WEBHOOK_PRIVATE_KEY:-}
    ports:
      - "127.0.0.1:${DEV_STUBS_PORT:-4010}:4010"
    networks: [edge]

  # ---------- Aplicación en modo desarrollo (hot reload) ----------
  api:
    <<: *hardening
    profiles: [dev]
    image: proveeeventos/backend-dev:local
    pull_policy: build
    build:
      <<: *backend-build
      target: dev
    command: ["npm", "run", "dev:api", "--workspace", "backend"]
    environment:
      <<: *api-env
      NODE_ENV: development
    ports:
      - "127.0.0.1:${API_PORT:-4000}:4000"
    volumes:
      - documents:/var/lib/pe/documents
    healthcheck: *api-healthcheck
    depends_on:
      <<: *app-depends
      dev-stubs: { condition: service_healthy }
    networks: [edge, data]
    develop:
      watch:
        - { action: sync, path: ./backend/src, target: /app/backend/src, ignore: [tests/, prisma/generated/] }
        - { action: rebuild, path: ./backend/src/prisma/schema.prisma }
        - { action: rebuild, path: ./backend/package.json }
        - { action: rebuild, path: ./package-lock.json }

  worker:
    <<: *hardening
    profiles: [dev]
    image: proveeeventos/backend-dev:local
    pull_policy: build
    build:
      <<: *backend-build
      target: dev
    command: ["npm", "run", "dev:worker", "--workspace", "backend"]
    environment:
      <<: *worker-env
      NODE_ENV: development
    volumes:
      - documents:/var/lib/pe/documents
    healthcheck: *worker-healthcheck
    stop_grace_period: 30s
    depends_on:
      <<: *app-depends
      mailpit: { condition: service_healthy }
    networks: [edge, data]
    develop:
      watch:
        - { action: sync, path: ./backend/src, target: /app/backend/src, ignore: [tests/, prisma/generated/] }
        - { action: rebuild, path: ./backend/src/prisma/schema.prisma }
        - { action: rebuild, path: ./backend/package.json }
        - { action: rebuild, path: ./package-lock.json }

  web:
    <<: *hardening
    profiles: [dev]
    image: proveeeventos/web-dev:local
    pull_policy: build
    build:
      context: .
      dockerfile: frontend/Dockerfile
      target: dev
      args:
        NODE_IMAGE: ${NODE_IMAGE:?}
    environment:
      <<: *web-env
      NODE_ENV: development
    ports:
      - "127.0.0.1:${WEB_PORT:-3000}:3000"
    healthcheck: *web-healthcheck
    depends_on:
      api: { condition: service_healthy }
      dev-stubs: { condition: service_healthy }
    networks: [edge]
    develop:
      watch:
        - { action: sync, path: ./frontend/src, target: /app/frontend/src }
        - { action: rebuild, path: ./frontend/package.json }
        - { action: rebuild, path: ./package-lock.json }

  # ---------- Aplicación con imágenes de ejecución (smoke y E2E) ----------
  api-test:
    <<: *hardening
    profiles: [test]
    image: proveeeventos/backend:local
    pull_policy: build
    build:
      <<: *backend-build
      target: runner
    environment:
      <<: *api-env
      NODE_ENV: production
    ports:
      - "127.0.0.1:${API_PORT:-4000}:4000"
    volumes:
      - documents:/var/lib/pe/documents
    healthcheck: *api-healthcheck
    read_only: true
    tmpfs: [/tmp]
    depends_on:
      <<: *app-depends
      dev-stubs: { condition: service_healthy }
    networks:
      edge:
        aliases: [api]
      data:

  worker-test:
    <<: *hardening
    profiles: [test]
    image: proveeeventos/backend:local
    pull_policy: never
    command: ["node", "--enable-source-maps", "dist/bootstrap/worker.js"]
    environment:
      <<: *worker-env
      NODE_ENV: production
    volumes:
      - documents:/var/lib/pe/documents
    healthcheck: *worker-healthcheck
    stop_grace_period: 30s
    read_only: true
    tmpfs: [/tmp]
    depends_on:
      <<: *app-depends
      mailpit: { condition: service_healthy }
    networks: [edge, data]

  web-test:
    <<: *hardening
    profiles: [test]
    image: proveeeventos/web:local
    pull_policy: build
    build:
      context: .
      dockerfile: frontend/Dockerfile
      target: runner
      args:
        NODE_IMAGE: ${NODE_IMAGE:?}
    environment:
      <<: *web-env
      NODE_ENV: production
    ports:
      - "127.0.0.1:${WEB_PORT:-3000}:3000"
    healthcheck: *web-healthcheck
    depends_on:
      api-test: { condition: service_healthy }
      dev-stubs: { condition: service_healthy }
    networks: [edge]

  # ---------- Herramientas puntuales ----------
  psql:
    profiles: [tools]
    image: ${PG_IMAGE:?}
    user: postgres
    entrypoint: ["psql"]
    environment:
      PGHOST: postgres
      PGUSER: pe_readonly
      PGPASSWORD: ${PE_READONLY_PASSWORD:?}
      PGDATABASE: ${POSTGRES_DB:?}
    depends_on:
      postgres: { condition: service_healthy }
    networks: [data]

  db-authoring:
    profiles: [tools]
    image: proveeeventos/migrate:local
    pull_policy: build
    build:
      <<: *backend-build
      target: migrate
    user: ${HOST_UID:-1000}:${HOST_GID:-1000}
    environment:
      APP_ENV: ${APP_ENV:?}
      TZ: UTC
      DIRECT_URL: postgresql://pe_migrator:${PE_MIGRATOR_PASSWORD:?}@postgres:5432/${POSTGRES_DB:?}
      SHADOW_DATABASE_URL: postgresql://pe_migrator:${PE_MIGRATOR_PASSWORD:?}@postgres:5432/${POSTGRES_DB:?}_shadow
    volumes:
      - ./backend/src/prisma:/app/backend/src/prisma
    depends_on:
      db-bootstrap: { condition: service_completed_successfully }
    networks: [data]

  secrets-scan:
    profiles: [tools]
    image: ${GITLEAKS_IMAGE:?}
    command: ["dir", "/repo", "--redact", "--exit-code", "1", "--config", "/repo/Tools/adr-guard/gitleaks.toml"]
    volumes:
      - .:/repo:ro
    network_mode: none

volumes:
  pgdata:
  redisdata:
  documents:

networks:
  edge:
  data:
    internal: true
```

### 5.5 Archivos auxiliares

**`docker/pgbouncer/pgbouncer.ini`**

```ini
[databases]
@POSTGRES_DB@ = host=postgres port=5432 dbname=@POSTGRES_DB@

[users]
pe_api = pool_size=20
pe_worker = pool_size=15
pe_retention = pool_size=5

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 5432
auth_type = scram-sha-256
auth_file = /tmp/pgbouncer/userlist.txt
pool_mode = transaction
default_pool_size = 5
max_client_conn = 200
max_db_connections = 40
max_prepared_statements = 200
ignore_startup_parameters = extra_float_digits
```

**`docker/pgbouncer/start.sh`**

```bash
#!/bin/sh
# Genera la lista de usuarios en memoria (tmpfs) y arranca PgBouncer en modo transacción.
set -eu
: "${POSTGRES_DB:?}" "${PE_API_PASSWORD:?}" "${PE_WORKER_PASSWORD:?}" "${PE_RETENTION_PASSWORD:?}"
umask 077
dir=/tmp/pgbouncer
mkdir -p "$dir"
{
  printf '"pe_api" "%s"\n' "$PE_API_PASSWORD"
  printf '"pe_worker" "%s"\n' "$PE_WORKER_PASSWORD"
  printf '"pe_retention" "%s"\n' "$PE_RETENTION_PASSWORD"
} >"$dir/userlist.txt"
sed "s/@POSTGRES_DB@/$POSTGRES_DB/g" /etc/pe/pgbouncer.ini >"$dir/pgbouncer.ini"
exec pgbouncer "$dir/pgbouncer.ini"
```

**`scripts/db/bootstrap.sh`**

```bash
#!/bin/sh
# Migración 00 y contraseñas de los roles. Se ejecuta con el administrador de la base y es idempotente.
set -eu
: "${PGHOST:?}" "${PGUSER:?}" "${PGPASSWORD:?}" "${PGDATABASE:?}" "${APP_ENV:?}"

bootstrap_database() {
  psql -X -q -v ON_ERROR_STOP=1 -d "$1" -f /bootstrap/00_extensiones_roles.sql
}

bootstrap_database "$PGDATABASE"

psql -X -q -v ON_ERROR_STOP=1 <<'SQL'
\getenv migrator PE_MIGRATOR_PASSWORD
\getenv api PE_API_PASSWORD
\getenv worker PE_WORKER_PASSWORD
\getenv retention PE_RETENTION_PASSWORD
\getenv readonly PE_READONLY_PASSWORD
ALTER ROLE pe_migrator PASSWORD :'migrator';
ALTER ROLE pe_api PASSWORD :'api';
ALTER ROLE pe_worker PASSWORD :'worker';
ALTER ROLE pe_retention PASSWORD :'retention';
ALTER ROLE pe_readonly PASSWORD :'readonly';
SQL

# Base sombra solo para la autoría local de migraciones.
if [ "$APP_ENV" = "development" ]; then
  shadow="${PGDATABASE}_shadow"
  psql -X -q -v ON_ERROR_STOP=1 -v shadow="$shadow" <<'SQL'
SELECT format('CREATE DATABASE %I OWNER pe_owner', :'shadow')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'shadow') \gexec
SQL
  bootstrap_database "$shadow"
fi
echo "db-bootstrap: completado"
```

**`scripts/db/apply-rls.sh`**

```bash
#!/bin/sh
# Aplica 20_rls solo si se pide. Prohibido fuera de development y test (ADR-DATA-009 R4).
set -eu
: "${APP_ENV:?}" "${DB_APPLY_RLS:?}"
if [ "$DB_APPLY_RLS" != "true" ]; then
  echo "db-rls: omitido (DB_APPLY_RLS=$DB_APPLY_RLS)"
  exit 0
fi
case "$APP_ENV" in
  development | test) ;;
  *)
    echo "db-rls: no se permite en APP_ENV=$APP_ENV" >&2
    exit 78
    ;;
esac
: "${PGHOST:?}" "${PGUSER:?}" "${PGPASSWORD:?}" "${PGDATABASE:?}"
psql -X -q -v ON_ERROR_STOP=1 --single-transaction -f /rls/20_rls.sql
echo "db-rls: aplicado"
```

**`Tools/adr-guard/gitleaks.toml`**

```toml
title = "ProveeEventos"

[extend]
useDefault = true

# Solo afecta al escaneo local del árbol de trabajo: .env nunca se versiona y adr-guard lo veta.
[[allowlists]]
description = "Archivos locales ignorados por Git"
paths = ['''(^|/)\.env$''', '''(^|/)node_modules/''']
```

### 5.6 Dobles locales (`Tools/dev-stubs/server.ts`)

Servidor HTTP en TypeScript sin dependencias, que **se niega a arrancar** si `APP_ENV` no es `development` o `test`.

| Ruta | Función |
|---|---|
| `GET /health/live` | Salud |
| `GET /.well-known/openid-configuration`, `GET /.well-known/jwks.json` | Metadatos y claves RS256 generadas al arrancar |
| `GET /authorize`, `POST /oauth/token`, `GET /v2/logout` | Authorization Code con PKCE y refresh rotatorio, con una lista de usuarios sintéticos que coincide con las semillas (un usuario por rol) |
| `POST /cloudinary/...` y consulta del recurso | Verifica la firma de carga y responde los metadatos del archivo |
| `POST /dev/sendgrid/event` | Envía a la API un evento de entrega firmado con `DEV_SENDGRID_WEBHOOK_PRIVATE_KEY` |

El correo saliente usa el adaptador SMTP hacia Mailpit. Google Maps queda deshabilitado (captura manual, DEC-015). WhatsApp no necesita simulador: solo se construye el enlace `wa.me`. Los dobles de las **pruebas** son los de `ProveeEventos_TESTs.md` (MSW), no estos.

El emisor público es `http://localhost:4010`; los contenedores consultan las claves por `AUTH0_BACKCHANNEL_BASE_URL` y validan el emisor público (`DC-10`).

### 5.7 Comandos operativos

`package.json` raíz:

```json
{
  "workspaces": ["backend", "frontend"],
  "scripts": {
    "env:init": "bash scripts/dev/gen-env.sh",
    "dc": "docker compose --env-file docker/images.env --env-file .env",
    "dev:up": "npm run dc -- --profile dev up -d --build --wait",
    "dev:watch": "npm run dc -- --profile dev up --build --watch",
    "dev:ps": "npm run dc -- --profile dev ps -a",
    "dev:logs": "npm run dc -- --profile dev logs -f --tail=200",
    "dev:down": "npm run dc -- --profile dev down",
    "dev:reset": "npm run dc -- --profile dev --profile test --profile tools down -v --remove-orphans",
    "test:stack:up": "npm run dc -- -p pe-test --profile test up -d --build --wait",
    "test:stack:down": "npm run dc -- -p pe-test --profile test down -v --remove-orphans",
    "db:migrate": "npm run dc -- run --rm --build migrate",
    "db:migrate:status": "npm run dc -- run --rm migrate npx --no-install prisma migrate status",
    "db:migrate:create": "npm run dc -- --profile tools run --rm --build db-authoring npx --no-install prisma migrate dev --create-only --name",
    "db:seed": "npm run dc -- --profile dev run --rm --build seed",
    "db:psql": "npm run dc -- --profile tools run --rm psql",
    "secrets:scan": "npm run dc -- --profile tools run --rm secrets-scan"
  }
}
```

Primer arranque:

```bash
npm ci
npm run env:init
npm run dev:up        # construye, migra, siembra y espera a que todo esté sano
npm run dev:ps
```

Aplicación en `http://localhost:3000`, API en `http://localhost:4000/api/v1`, correos en `http://localhost:8025`.

### 5.8 Qué se ha comprobado de esta sección

El 2026-11-25, con Docker 29.9.3 y Compose 5.7.1:

- `docker compose config` termina en 0 para los perfiles por defecto, `dev`, `test` y `tools`.
- `docker buildx build --check` no reporta advertencias en los tres Dockerfiles.
- La infraestructura (`postgres`, `db-bootstrap`, `pgbouncer`, `redis`, `mailpit`) se levantó y quedó sana usando **imágenes locales no fijadas** (`postgres:15-alpine`, `redis:7-alpine`, `edoburu/pgbouncer:latest`, `axllent/mailpit:latest`): conexión por el pooler con los tiempos límite de cada rol, `pe_api` sin DDL, contraseña errónea rechazada, bootstrap repetible, base sombra creada, red `data` sin salida y `db-rls` bloqueado en `production`.

**No comprobado:** construcción de las imágenes y arranque de `migrate`, `seed`, `api`, `worker`, `web` y `dev-stubs` (no hay código), la aplicación de las migraciones `01`–`11` y `20`, y las imágenes fijadas por digest.

---
## Sección 6 — Migraciones Automatizadas

Normativa: `ADR-DATA-009`, `ADR-DATA-011`, `ADR-DATA-014`, `ADR-STACK-004`; TDD §4.4, §4.5, §7.2, §10.1.

### 6.1 Disposición en el repositorio

```text
backend/
  prisma.config.ts                      # CLI: DIRECT_URL (pe_migrator); shadowDatabaseUrl opcional
  src/prisma/
    schema.prisma                       # inicial: copia de proveeeventos.prisma
    bootstrap/00_extensiones_roles.sql  # bloques SQL-001..008 del anexo; los ejecuta el administrador
    migrations/
      <timestamp>_inicial_01_11/
        migration.sql                   # SQL base de Prisma + bloques del anexo 01..11, en orden
        down.sql                        # reversión (líneas "--|" en orden inverso + SQL base inverso)
      <timestamp>_<nombre>/{migration.sql,down.sql}
    rls/20_rls.sql                      # bloques de la migración 20; fuera de "migrate deploy"
    seed/{index.ts,reference/,synthetic/}
scripts/db/{bootstrap.sh,apply-rls.sh,check-annex.ts,check-catalog.ts}
```

- La base inicial se genera con `prisma migrate diff --from-empty --to-schema src/prisma/schema.prisma --script` y se le añaden los bloques `01`–`11` del anexo; TDD §10.1 admite una sola migración inicial en un proyecto nuevo (`DC-13`).
- `00` no es una migración de Prisma: exige privilegios de administrador (`ADR-DATA-014 R3`). `20` no entra en `migrate deploy` para que no pueda aplicarse por accidente antes de la etapa J (`ADR-DATA-009 R4`, `DC-14`).
- `scripts/db/check-annex.ts` falla si algún bloque `SQL-nnn` de `proveeeventos.sql` falta, aparece dos veces o difiere entre el anexo y `bootstrap/`, `migrations/` o `rls/`.

### 6.2 Flujo determinista en local

```mermaid
flowchart LR
  PG["postgres sano"] --> BS["db-bootstrap<br/>administrador: 00 + contraseñas"]
  BS -->|"exit 0"| MG["migrate<br/>pe_migrator: prisma migrate deploy"]
  MG -->|"exit 0"| RLS["db-rls<br/>solo si DB_APPLY_RLS=true"]
  RLS -->|"exit 0"| SD["seed<br/>referencia y, en dev, sintéticos"]
  SD -->|"exit 0"| APP["api y worker"]
  BS -->|"exit 0"| PB["pgbouncer"] --> APP
```

- Cada paso es un servicio de una sola ejecución; el siguiente declara `condition: service_completed_successfully`. Un código distinto de 0 impide arrancar la API.
- La aplicación **nunca** migra al arrancar.
- `migrate` usa conexión directa (`DIRECT_URL`); `api` y `worker`, el pooler con su rol.
- Todo es repetible: `db-bootstrap` es idempotente, `migrate deploy` no hace nada sin migraciones pendientes, las semillas usan inserción o actualización por código natural.

Comandos manuales:

| Acción | Comando |
|---|---|
| Aplicar pendientes | `npm run db:migrate` |
| Estado | `npm run db:migrate:status` |
| Crear una migración (sin aplicarla) | `npm run db:migrate:create -- <nombre>` |
| Aplicar RLS localmente | `DB_APPLY_RLS=true npm run dc -- run --rm db-rls` |
| Sembrar | `npm run db:seed` |

### 6.3 Autoría de una migración

1. Cambiar `schema.prisma` y ejecutar `db:migrate:create` (usa la base sombra `<POSTGRES_DB>_shadow`, creada por `db-bootstrap` solo en `development`).
2. Añadir al `migration.sql` los objetos que Prisma no administra y comenzar el archivo con `SET lock_timeout = '2s';` (`ADR-DATA-014 R4`).
3. Índices sobre tablas con datos: `CONCURRENTLY`, solos en su archivo (R5). `CHECK` y claves foráneas sobre datos existentes: `NOT VALID` y validación posterior (R6). Sin `RENAME` en caliente; cambios incompatibles por *expand-and-contract*; valor de enum nuevo en migración propia anterior al código (R7). Sin borrar objetos del anexo (R8). *Backfills* fuera de la migración, por lotes reanudables (R11).
4. Escribir `down.sql`, o un `IRREVERSIBLE.md` que lo justifique según TDD §7.5 (R9).
5. Probar desde cero: `npm run dev:reset && npm run dev:up`.
6. El cambio de esquema y su migración van en el mismo PR (R1). Toda migración exige aprobación humana (`ADR-GOV-006` E3).

### 6.4 Inmutabilidad y validación en CI

| Control | Job | Regla |
|---|---|---|
| Ningún archivo bajo `backend/src/prisma/migrations/**` presente en la rama base se modifica, renombra o borra | `adr-guard` (`git diff --name-status`, estados `M`, `R`, `D`) | `ADR-DATA-014 R2`. **No admite aprobación ni excepción** |
| `bootstrap/` y `rls/` solo cambian con aprobación humana y coincidiendo con el anexo | `adr-guard` + `check-annex.ts` | `DC-14` |
| Análisis del SQL añadido con un analizador sintáctico: `DROP`, `RENAME`, `UPDATE` masivo, índice sin `CONCURRENTLY`, falta de `lock_timeout`, falta de reversión | `adr-guard` | R4–R9, R11 |
| `prisma validate` y `prisma format --check` | `adr-guard-runtime` | `ADR-STACK-004` |
| Base creada desde cero en PostgreSQL **15 y 16**: bootstrap → `migrate deploy` → `20_rls` | `db-migrations` (matriz) | R10, `ADR-DATA-009 R5` |
| Sin deriva: `prisma migrate diff --from-config-datasource --to-schema src/prisma/schema.prisma --exit-code` | `db-migrations` | R10 |
| Segunda ejecución de bootstrap y `migrate deploy` sin cambios | `db-migrations` | Idempotencia |
| Catálogo resultante: roles sin `BYPASSRLS`, `FORCE ROW LEVEL SECURITY` en las tablas de tenant, privilegios (incluido `_prisma_migrations` revocado a roles de ejecución), índices de ganador único, triggers | `db-migrations` (`check-catalog.ts` de la rama base) | `ADR-DATA-004/009/011/015` |
| Compatibilidad N-1: pruebas de integración de la rama base contra el esquema nuevo | `post-merge` en `main` | `ADR-DATA-014 R7`; TESTs §2.3 |

La comparación de deriva puede señalar objetos del anexo que Prisma no modela; la lista de diferencias esperadas se fija al implementar la primera migración en un archivo protegido y cualquier otra diferencia falla.

### 6.5 Semillas

Dos clases separadas (`DISC-02`):

| Clase | Contenido | Dónde se ejecuta | Reglas |
|---|---|---|---|
| **Referencia** | Categorías y subtipos, plantillas globales de evento y de WhatsApp, planes, tasa de comisión, configuración de ranking, plantillas de mensajes, festivos (TDD §4.5) | `seed` en `development` y `test`; en ambientes remotos, paso controlado posterior a `migrate` (diferido) | Idempotente por código natural, versionada, sin datos de personas ni empresas |
| **Sintética** | Empresas, usuarios por rol (incluido un administrador de plataforma de desarrollo), proveedores, eventos, solicitudes y contrataciones de ejemplo | **Solo `development` y `test`**, con `SEED_SYNTHETIC=true` | Prohibida en `staging` y `production`: el proceso termina con código 78 |

Determinismo: identificadores UUIDv5 derivados de un espacio de nombres fijo, fechas absolutas declaradas en el repositorio (sin "hoy" ni aleatoriedad sin semilla), correos `@test.proveeeventos.co` y teléfonos de prueba (TESTs §3.1). Las pruebas automatizadas **no** dependen de estas semillas: usan sus propios constructores (TESTs §3.2). El primer `ADMIN_PLATAFORMA` real se crea con un procedimiento operativo auditado, nunca con una semilla (TDD §4.5).

---
## Sección 7 — Pipeline CI/CD en GitHub Actions

Normativa: `ADR-GOV-001`–`007`, `ADR-STACK-003`, `ADR-TEST-002`–`006`, `ADR-SEC-005`; SAD §13.3; `ProveeEventos_TESTs.md` §2.3–§2.4. Esta sección define **CI**; el CD es solo un contrato (§7.7).

### 7.1 Principios del pipeline

1. Toda acción de terceros se fija por **SHA de commit** con su versión en comentario; toda imagen, por digest (`docker/images.env`).
2. `permissions: {}` en la raíz; permisos mínimos por job (§4.2).
3. Ninguna expresión `${{ … }}` dentro de `run`: los datos del evento entran por `env` (evita inyección desde títulos o cuerpos de PR).
4. Los workflows obligatorios no tienen filtros de ruta ni condiciones dependientes del contenido del PR (`ADR-GOV-007 R3`).
5. `retry: 0` en pruebas; ningún `continue-on-error` en jobs obligatorios.
6. Los controles que juzgan el PR se ejecutan con **definición y scripts de la rama base**.
7. Solo se admiten ramas del propio repositorio. `actions/checkout` v7 rechaza descargar código de forks bajo `pull_request_target`; no se usa la opción que lo desactiva (`DC-18`).

### 7.2 Flujo de CI de un Pull Request

```mermaid
flowchart TD
  PR["Pull Request a main"] --> CQ
  PR --> AG
  PR --> AR
  subgraph CQ["ci-quality-and-tests.yml · pull_request · sin secretos"]
    V["verify-adrs"]
    RT["adr-guard-runtime"]
    SS["security-scan"]
    BU["build (sin push)"]
    DB["db-migrations PG15/16"]
    IS["integration-suite<br/>int · mt · conc · api · sec"] --> IT["integration-tests"]
    E2E["e2e-smoke"]
    RT --> G["ci-gate"]
    SS --> G
    BU --> G
    DB --> G
    E2E --> G
  end
  subgraph AG["adr-guard.yml · pull_request_target · rama base"]
    AD["adr-guard<br/>diff, secretos, contrato, validadores, E1-E4"]
  end
  subgraph AR["ai-reviewer.yml · pull_request_target · rama base"]
    W["ai-review: espera checks verdes y revisa"] -->|auto-aprobar| F["ai-reviewer"]
    W -->|E1-E7| H["human-approval (Environment)"] --> F
  end
  V --> W
  IT --> W
  G --> W
  AD --> W
  V --> M{"Ruleset: todos en verde"}
  IT --> M
  G --> M
  AD --> M
  F --> M
  M --> MERGE["Integración en main"] --> PM["post-merge-e2e<br/>N-1, E2E completa, carga de humo"]
  PM -. "hook diferido" .-> CD["CD a staging / production<br/>(no implementado)"]
```

### 7.3 Workflow `ci-quality-and-tests.yml` (checks obligatorios del PR)

| Job | Contenido | Límite | Obligatorio en el Ruleset |
|---|---|---|---|
| `verify-adrs` | `npm run verify:adrs` (formato, tipos, lint, dependencias, arquitectura y unitarias con cobertura) y cobertura sin descenso | 15 min | **Sí** (ADR) |
| `integration-suite` → `integration-tests` | `test:int`, `test:mt`, `test:conc` en PostgreSQL 15 y 16; `test:api` y `test:sec` en 16; Redis real; sin red externa | 12–22 min | **`integration-tests`** (ADR) |
| `adr-guard-runtime` | `npm audit`, `prisma validate` y `format --check`, severidades de lint, scripts protegidos, `.env.example` frente a esquemas | 10 min | vía `ci-gate` |
| `security-scan` | Semgrep y hadolint | 10 min | vía `ci-gate` |
| `build` | `npm run build` y construcción de imágenes **sin publicarlas**; usuario no root | 20 min | vía `ci-gate` |
| `db-migrations` | §6.4 en PostgreSQL 15 y 16 | 15 min | vía `ci-gate` |
| `e2e-smoke` | Perfil `test` de Compose y `test:e2e:smoke` (los 12 escenarios de SRS §8 en Chromium, TESTs §2.3) | 25 min | vía `ci-gate` |
| `ci-gate` | Agregador; un job omitido o fallido lo hace fallar | 2 min | **Sí** |
| `post-merge-e2e` | Solo en `push` a `main`: compatibilidad N-1, E2E completa y accesibilidad, carga de humo | 60 min | No (posterior) |
| `nightly` | Solo programado: mezcla de concurrencia de 10 minutos y reauditoría de dependencias | 60 min | No |

**Correspondencia con los *quality gates* de TESTs §12.2:**

| Gate | Cubierto por | Estado en Etapa 1 |
|---|---|---|
| G-01–G-03 | `verify-adrs`, `adr-guard`, `adr-guard-runtime` | Especificado |
| G-04–G-07 | `integration-suite` (`api`, `int`, `mt`, `conc`) | Especificado |
| G-08 | `security-scan` (Semgrep), `adr-guard` (gitleaks), `adr-guard-runtime` (`npm audit`, `DISC-09`) | Especificado |
| G-09 | `e2e-smoke` | Especificado |
| G-10 | `adr-guard` (supresiones, pruebas, número de `TC-*`) y `CODEOWNERS` | Especificado |
| G-11, G-13 | `post-merge-e2e` | Especificado |
| G-12 | `post-merge-e2e`, contra el perfil `test` | **Parcial:** TESTs lo exige en `staging-perf` (`DISC-10`) |
| G-14–G-16, G-18 | — | Diferidos: ambiente remoto (`INFRA-P-16`) o verificación humana |
| G-17, G-19 | — | Diferidos: dependen de lo excluido en §9 y §10 |

**`.github/workflows/ci-quality-and-tests.yml`**

```yaml
name: ci-quality-and-tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  schedule:
    - cron: "0 7 * * *" # 02:00 en America/Bogota

permissions: {}

concurrency:
  group: ci-${{ github.event.pull_request.number || github.ref }}-${{ github.event_name }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

defaults:
  run:
    shell: bash

jobs:
  verify-adrs:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    permissions:
      contents: read
      actions: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
          fetch-depth: 0
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - name: Capa 1 (formato, tipos, lint, dependencias, arquitectura y unitarias con cobertura)
        run: npm run verify:adrs
      - name: Controles de la rama base
        env:
          BASE_SHA: ${{ github.event.pull_request.base.sha || github.sha }}
        run: git worktree add --detach .base "$BASE_SHA"
      - name: Cobertura sin descenso respecto a main (ADR-TEST-006 R4)
        env:
          GH_TOKEN: ${{ github.token }}
          BASE_SHA: ${{ github.event.pull_request.base.sha || github.event.before }}
        run: node .base/Tools/adr-guard/coverage-ratchet.ts --summary coverage/coverage-summary.json --base-sha "$BASE_SHA"
      - uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        with:
          name: coverage-summary
          path: coverage/coverage-summary.json
          if-no-files-found: error
          retention-days: 30

  adr-guard-runtime:
    # Parte de la Capa 2 que ejecuta código del PR: sin secretos ni permisos de escritura.
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
          fetch-depth: 0
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npm audit --omit=dev --audit-level=high
      - name: Esquema Prisma válido y formateado
        env:
          DIRECT_URL: postgresql://build@127.0.0.1:5432/build
        run: |
          npm exec --workspace backend -- prisma validate
          npm exec --workspace backend -- prisma format --check
      - name: Controles de la rama base
        env:
          BASE_SHA: ${{ github.event.pull_request.base.sha || github.sha }}
        run: git worktree add --detach .base "$BASE_SHA"
      - name: Severidades, scripts protegidos y coherencia de imágenes
        run: node .base/Tools/adr-guard/cli.ts runtime --head .
      - name: Esquemas de entorno frente a .env.example
        run: npm run verify:env

  security-scan:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - name: Semgrep (reglas versionadas, sin telemetría ni red)
        run: |
          set -a; . docker/images.env; set +a
          docker run --rm --network none -v "$PWD:/src:ro" "$SEMGREP_IMAGE" \
            semgrep scan --config /src/Tools/adr-guard/semgrep --config /src/backend/src/tests/security/rules --error --metrics=off --disable-version-check /src
      - name: Dockerfiles
        run: |
          set -a; . docker/images.env; set +a
          for file in backend/Dockerfile frontend/Dockerfile Tools/dev-stubs/Dockerfile; do
            docker run --rm -i "$HADOLINT_IMAGE" hadolint --failure-threshold error - < "$file"
          done

  build:
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npm run build
      - uses: docker/setup-buildx-action@f87e5991a6d7451dcb8d9637bfbc97413f497069 # v4.4.1
      - name: Construir imágenes sin publicarlas
        run: |
          bash scripts/ci/prepare-env.sh
          npm run dc -- --profile test --profile dev build migrate api-test web-test dev-stubs
      - name: Las imágenes no se ejecutan como root
        run: |
          for image in migrate backend web dev-stubs; do
            user="$(docker image inspect --format '{{.Config.User}}' "proveeeventos/$image:local")"
            test "$user" = "node"
          done

  db-migrations:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    permissions:
      contents: read
    strategy:
      fail-fast: false
      matrix:
        pg: [PG_IMAGE, PG_IMAGE_MIN]
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
          fetch-depth: 0
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - name: Entorno efímero y versión de PostgreSQL
        env:
          PG_VAR: ${{ matrix.pg }}
        run: |
          bash scripts/ci/prepare-env.sh
          echo "PG_IMAGE=$(grep "^${PG_VAR}=" docker/images.env | cut -d= -f2-)" >> "$GITHUB_ENV"
      - name: Controles de la rama base
        env:
          BASE_SHA: ${{ github.event.pull_request.base.sha || github.sha }}
        run: git worktree add --detach .base "$BASE_SHA"
      - name: Anexo SQL repartido sin pérdidas
        run: node .base/scripts/db/check-annex.ts --head .
      - name: Base desde cero (00, 01-11 y 20_rls)
        run: npm run dc -- run --rm --build db-rls
      - name: Sin deriva respecto al esquema
        run: >-
          npm run dc -- run --rm migrate npx --no-install prisma migrate diff
          --from-config-datasource --to-schema src/prisma/schema.prisma --exit-code
      - name: Catálogo resultante
        run: node .base/scripts/db/check-catalog.ts
      - name: Segunda ejecución sin cambios
        run: npm run dc -- run --rm db-rls
      - name: Registros y limpieza
        if: always()
        run: |
          npm run dc -- logs --no-color db-bootstrap postgres | tail -n 200
          npm run dc -- down -v --remove-orphans

  integration-suite:
    runs-on: ubuntu-24.04
    timeout-minutes: ${{ matrix.minutes }}
    permissions:
      contents: read
    strategy:
      fail-fast: false
      matrix:
        include:
          - { suite: int, pg: PG_IMAGE, minutes: 18 }
          - { suite: int, pg: PG_IMAGE_MIN, minutes: 18 }
          - { suite: mt, pg: PG_IMAGE, minutes: 18 }
          - { suite: mt, pg: PG_IMAGE_MIN, minutes: 18 }
          - { suite: conc, pg: PG_IMAGE, minutes: 22 }
          - { suite: conc, pg: PG_IMAGE_MIN, minutes: 22 }
          - { suite: api, pg: PG_IMAGE, minutes: 12 }
          - { suite: sec, pg: PG_IMAGE, minutes: 15 }
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - name: Descargar imágenes antes de cortar la red
        env:
          PG_VAR: ${{ matrix.pg }}
        run: |
          set -a; . docker/images.env; set +a
          pg_image="${!PG_VAR}"
          docker pull "$pg_image"
          docker pull "$REDIS_IMAGE"
          ryuk_image="$(node scripts/ci/testcontainers-reaper-image.ts)"
          docker pull "$ryuk_image"
          {
            echo "PE_TEST_POSTGRES_IMAGE=$pg_image"
            echo "PE_TEST_REDIS_IMAGE=$REDIS_IMAGE"
          } >> "$GITHUB_ENV"
      - name: Suite sin red externa
        env:
          SUITE: ${{ matrix.suite }}
        run: bash scripts/ci/run-offline.sh npm run "test:$SUITE"
      - uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        if: always()
        with:
          name: report-${{ matrix.suite }}-${{ matrix.pg }}
          path: reports/
          if-no-files-found: warn
          retention-days: 14

  integration-tests:
    # Check obligatorio (ADR-GOV-007 R1): agrega la matriz; un resultado omitido también falla.
    needs: [integration-suite]
    if: ${{ always() }}
    runs-on: ubuntu-24.04
    timeout-minutes: 2
    steps:
      - env:
          RESULT: ${{ needs.integration-suite.result }}
        run: test "$RESULT" = "success"

  e2e-smoke:
    runs-on: ubuntu-24.04
    timeout-minutes: 25
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: bash scripts/ci/prepare-env.sh
      - run: npm run test:stack:up
      - run: npm exec -- playwright install --with-deps chromium
      - run: npm run test:e2e:smoke
      - uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
          if-no-files-found: warn
          retention-days: 7
      - name: Registros y limpieza
        if: always()
        run: |
          npm run dc -- -p pe-test --profile test logs --no-color | tail -n 300
          npm run test:stack:down

  ci-gate:
    # Segundo agregador: resume los jobs obligatorios que no cubren los cuatro checks del ADR.
    needs: [adr-guard-runtime, security-scan, build, db-migrations, e2e-smoke]
    if: ${{ always() }}
    runs-on: ubuntu-24.04
    timeout-minutes: 2
    steps:
      - env:
          RESULTS: ${{ join(needs.*.result, ' ') }}
        run: |
          for result in $RESULTS; do test "$result" = "success"; done

  post-merge-e2e:
    if: ${{ github.event_name == 'push' }}
    needs: [ci-gate, integration-tests]
    runs-on: ubuntu-24.04
    timeout-minutes: 60
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
          fetch-depth: 0
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - name: Compatibilidad N-1 (pruebas del commit anterior contra el esquema nuevo)
        env:
          PREVIOUS_SHA: ${{ github.event.before }}
        run: bash scripts/ci/compat-n1.sh "$PREVIOUS_SHA"
      - run: bash scripts/ci/prepare-env.sh
      - run: npm run test:stack:up
      - run: npm exec -- playwright install --with-deps chromium webkit
      - name: E2E completa y accesibilidad
        run: npm run test:e2e
      - name: Carga de humo (TC-LOAD-001)
        run: |
          set -a; . docker/images.env; set +a
          docker run --rm --network host -e BASE_URL=http://127.0.0.1:4000 \
            -v "$PWD/backend/src/tests/load:/scripts:ro" "$K6_IMAGE" run /scripts/smoke.js
      - if: always()
        run: npm run test:stack:down

  nightly:
    if: ${{ github.event_name == 'schedule' }}
    runs-on: ubuntu-24.04
    timeout-minutes: 60
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - name: Mezcla aleatoria de concurrencia sin interbloqueos (ADR-TEST-003 R4)
        env:
          PE_TEST_CONCURRENCY_MIX_MINUTES: "10"
        run: npm run test:conc
      - run: npm audit --audit-level=high
```

**`scripts/ci/prepare-env.sh`**

```bash
#!/usr/bin/env bash
# .env efímero para un job de CI: secretos sintéticos nuevos en cada ejecución.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$root/scripts/dev/gen-env.sh" --force
sed -i \
  -e 's/^APP_ENV=.*/APP_ENV=test/' \
  -e 's/^SEED_SYNTHETIC=.*/SEED_SYNTHETIC=true/' \
  -e 's/^DB_APPLY_RLS=.*/DB_APPLY_RLS=true/' \
  "$root/.env"
```

**`scripts/ci/run-offline.sh`**

```bash
#!/usr/bin/env bash
# Ejecuta un comando sin salida a Internet (ADR-TEST-002 R3). Solo en runners efímeros de CI.
# Permite loopback y las redes de Docker; las imágenes deben descargarse antes.
set -euo pipefail
[[ "${CI:-}" == "true" ]] || { echo "run-offline.sh solo se ejecuta en CI" >&2; exit 64; }
getent group pe-offline >/dev/null || sudo groupadd pe-offline
sudo iptables -A OUTPUT -m owner --gid-owner pe-offline -o lo -j ACCEPT
sudo iptables -A OUTPUT -m owner --gid-owner pe-offline -d 172.16.0.0/12 -j ACCEPT
sudo iptables -A OUTPUT -m owner --gid-owner pe-offline -j REJECT
sudo ip6tables -A OUTPUT -m owner --gid-owner pe-offline -o lo -j ACCEPT
sudo ip6tables -A OUTPUT -m owner --gid-owner pe-offline -j REJECT
if sudo setpriv --reuid="$(id -u)" --regid=pe-offline --init-groups \
    curl --silent --max-time 5 https://registry.npmjs.org >/dev/null; then
  echo "el aislamiento de red no funciona" >&2
  exit 1
fi
# setpriv conserva el usuario y sus grupos (incluido docker) y cambia solo el grupo efectivo.
exec sudo --preserve-env setpriv --reuid="$(id -u)" --regid=pe-offline --init-groups \
  env "PATH=$PATH" "HOME=$HOME" "$@"
```

Contratos de los scripts que el workflow invoca y que el implementador debe crear:

| Script | Contrato |
|---|---|
| `scripts/ci/testcontainers-reaper-image.ts` | Imprime la imagen auxiliar que usa la versión instalada de Testcontainers, para descargarla antes de cortar la red |
| `scripts/ci/compat-n1.sh <sha>` | Obtiene el commit anterior en un `worktree`, aplica las migraciones **nuevas** y ejecuta sus `test:int` contra ese esquema |
| `scripts/db/check-annex.ts --head <ruta>` | §6.1 |
| `scripts/db/check-catalog.ts` | §6.4, conectado a la base del job |
| `Tools/adr-guard/coverage-ratchet.ts` | Compara líneas y ramas de `domain` y `application` con el artefacto `coverage-summary` de la última ejecución correcta de `main`; falla si descienden. Sin línea base (primer commit) lo informa y pasa |
| `backend/src/tests/load/smoke.js` | Script k6 de TC-LOAD-001; lee la URL de la API en `BASE_URL` |
| `backend/src/tests/security/rules/` | Reglas Semgrep propias (TESTs §2.4), junto a las reglas OWASP versionadas en `Tools/adr-guard/semgrep/` |
| Variables para pruebas | `PE_TEST_POSTGRES_IMAGE`, `PE_TEST_REDIS_IMAGE`, `PE_TEST_CONCURRENCY_MIX_MINUTES`; los informes y el resumen de conteos por categoría (TESTs §15.4) se escriben en `reports/` |

La prueba de aislamiento de red de `run-offline.sh` (reglas `iptables` por grupo) **no se ha ejecutado** en un runner; debe validarse en el primer PR y, si el runner no lo permite, sustituirse por un mecanismo equivalente aprobado por una persona (`ADR-TEST-002 R3` no se puede omitir).

### 7.4 Workflow `adr-guard.yml` (check obligatorio — Capa 2)

**`.github/workflows/adr-guard.yml`**

```yaml
name: adr-guard

# Capa 2. pull_request_target ejecuta ESTA definición desde la rama base.
# La cabecera del PR se descarga solo como datos: no se instala, construye ni ejecuta.
on:
  pull_request_target:
    branches: [main]
    types: [opened, synchronize, reopened, edited, ready_for_review]
  schedule:
    - cron: "30 7 * * *"

permissions: {}

concurrency:
  group: adr-guard-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

defaults:
  run:
    shell: bash

jobs:
  adr-guard:
    if: ${{ github.event_name == 'pull_request_target' }}
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    permissions:
      contents: read
      pull-requests: read
    env:
      BASE_SHA: ${{ github.event.pull_request.base.sha }}
      HEAD_SHA: ${{ github.event.pull_request.head.sha }}
      PR_NUMBER: ${{ github.event.pull_request.number }}
    steps:
      - name: Rechazar Pull Requests desde forks
        env:
          HEAD_REPO: ${{ github.event.pull_request.head.repo.full_name }}
          BASE_REPO: ${{ github.repository }}
        run: |
          if [[ "$HEAD_REPO" != "$BASE_REPO" ]]; then
            echo "Solo se admiten ramas del propio repositorio" >&2
            exit 1
          fi
      - name: Rama base (código de confianza)
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.event.pull_request.base.sha }}
          path: base
          persist-credentials: false
      - name: Cabecera del PR (solo datos)
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.event.pull_request.head.sha }}
          path: head
          fetch-depth: 0
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: base/.nvmrc
      - name: Dependencias de la herramienta (lockfile de la rama base)
        working-directory: base
        run: npm ci
      - name: Guardar el cuerpo del PR como dato
        env:
          PR_BODY: ${{ github.event.pull_request.body }}
        run: printf '%s' "$PR_BODY" > "$RUNNER_TEMP/pr-body.md"
      - name: Rutas protegidas, supresiones, dependencias, migraciones, pruebas y plantilla del PR
        run: >-
          node base/Tools/adr-guard/cli.ts static --base base --head head
          --base-sha "$BASE_SHA" --head-sha "$HEAD_SHA" --pr-body "$RUNNER_TEMP/pr-body.md"
      - name: Secretos en los commits del PR
        run: |
          set -a; . base/docker/images.env; set +a
          docker run --rm --network none --user "$(id -u):$(id -g)" \
            -v "$PWD/head:/repo:ro" -v "$PWD/base/Tools/adr-guard:/config:ro" \
            "$GITLEAKS_IMAGE" git /repo --log-opts="$BASE_SHA..$HEAD_SHA" \
            --redact --exit-code 1 --config /config/gitleaks.toml
      - name: Cambios incompatibles del contrato
        run: |
          set -a; . base/docker/images.env; set +a
          docker run --rm --network none -v "$PWD/base:/base:ro" -v "$PWD/head:/head:ro" \
            "$OASDIFF_IMAGE" breaking /base/ProveeEventos_API_Spec.yaml /head/ProveeEventos_API_Spec.yaml --fail-on ERR
      - name: Validadores del paquete (scripts de la base sobre documentos de la cabecera)
        run: |
          python3 -m venv "$RUNNER_TEMP/venv"
          "$RUNNER_TEMP/venv/bin/pip" install --quiet 'PyYAML==6.0.2'
          cp -r head "$RUNNER_TEMP/package"
          rm -rf "$RUNNER_TEMP/package/Tools"
          cp -r base/Tools "$RUNNER_TEMP/package/Tools"
          cd "$RUNNER_TEMP/package"
          "$RUNNER_TEMP/venv/bin/python" -I Tools/check_package.py
          "$RUNNER_TEMP/venv/bin/python" -I Tools/check_openapi.py ProveeEventos_API_Spec.yaml
      - name: Escalamiento E1-E4 y aprobación humana sobre el último commit
        env:
          GH_TOKEN: ${{ github.token }}
        run: >-
          node base/Tools/adr-guard/cli.ts approval --base base --head head
          --base-sha "$BASE_SHA" --head-sha "$HEAD_SHA" --pr "$PR_NUMBER"

  ruleset-drift:
    if: ${{ github.event_name == 'schedule' }}
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    environment: governance
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
      - run: npm ci
      - name: Configuración remota frente a la declarada (ADR-GOV-007)
        env:
          GH_TOKEN: ${{ secrets.GOVERNANCE_READ_TOKEN }}
        run: node Tools/adr-guard/cli.ts ruleset --declared .github/adr-guard/ruleset.json
```

Contrato de `Tools/adr-guard/cli.ts` (código protegido; se ejecuta desde la rama base):

| Subcomando | Comprueba |
|---|---|
| `static` | Rutas protegidas de `ADR-GOV-001` (`ProveeEventos_{PRD,SRS,SAD,DDD,TDD,ADRs}.md`, contrato, `Decisiones.md`, `Trazabilidad.md`, `Glosario.md`, `proveeeventos.prisma`, `proveeeventos.sql`, `docs/**`) y, por `DC-19`, `ProveeEventos_UXUI.md`, `ProveeEventos_TESTs.md`, `ProveeEventos_CICD.md`; sin mezcla de documentación y código; configuración protegida de `ADR-GOV-002 R1` (incluye `.github/**`, `Tools/**`, `package.json`, `tsconfig*`, `vitest*`, `playwright.config.*`, `docker/**`, `**/Dockerfile`, `docker-compose.yml`, `scripts/**`, `backend/src/prisma/{bootstrap,rls}/**`); `eslint-disable`, `eslint-enable`, `/* eslint`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `prettier-ignore`, `v8\|c8\|istanbul ignore`, `gitleaks:allow`, `.skip`, `.only`, `.todo`, `.skipIf`, `.runIf`, `.fails`, `xit`, `xdescribe` (la búsqueda excluye `Tools/adr-guard/**` y `backend/src/tests/architecture/fixtures/**`, `ADR §6.2`); excepciones vigentes de `.github/adr-guard/suppressions.yml`; dependencias nuevas, vetadas o con origen prohibido y lockfiles ajenos; `.env*` y claves; migraciones (§6.4); reducción de archivos o casos de prueba, incluido el número de identificadores `TC-*` (TESTs AS-08); cambios de `domain` o `application` sin pruebas; plantilla del PR con Issue, `SRS-*`, `operationId` y ADRs existentes; enlaces simbólicos nuevos |
| `approval` | Calcula E1–E4 de `ADR-GOV-006`. Si hay escalamiento, exige una revisión `APPROVED` de una persona de `.github/adr-guard/approvers.yml`, distinta del autor y del último `push`, sobre `HEAD_SHA`. Sin ella falla |
| `runtime` | Severidades efectivas (`eslint --print-config`), configuraciones anidadas, scripts `verify:*` literales, igualdad entre `docker/images.env` y los `ARG NODE_IMAGE` |
| `ruleset` | Compara el Ruleset remoto con `.github/adr-guard/ruleset.json` |

El agente codificador ejecuta el mismo `cli.ts static` en local contra `main` antes de abrir el PR (TESTs §2.3).

Después de una aprobación humana se **vuelve a ejecutar** el job fallido (`DC-17`): no se usa el evento `pull_request_review`, cuyo workflow no proviene necesariamente de la rama base.

### 7.5 Workflow `ai-reviewer.yml` (check obligatorio — Capa 3)

**`.github/workflows/ai-reviewer.yml`**

```yaml
name: ai-reviewer

# Capa 3. Definición, prompt y clasificador se leen de la rama base; el PR es solo datos.
on:
  pull_request_target:
    branches: [main]
    types: [opened, synchronize, reopened, edited, ready_for_review]

permissions: {}

concurrency:
  group: ai-reviewer-${{ github.event.pull_request.number }}
  cancel-in-progress: true

defaults:
  run:
    shell: bash

jobs:
  ai-review:
    runs-on: ubuntu-24.04
    timeout-minutes: 45
    environment: ai-reviewer
    permissions:
      contents: read
      pull-requests: write
      checks: read
    outputs:
      verdict: ${{ steps.review.outputs.verdict }}
    env:
      HEAD_SHA: ${{ github.event.pull_request.head.sha }}
      BASE_SHA: ${{ github.event.pull_request.base.sha }}
      PR_NUMBER: ${{ github.event.pull_request.number }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.event.pull_request.base.sha }}
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version-file: .nvmrc
      - name: Esperar a los demás checks obligatorios en verde (ADR-GOV-006 R1)
        env:
          GH_TOKEN: ${{ github.token }}
        run: >-
          node Tools/ai-reviewer/cli.ts wait-checks --sha "$HEAD_SHA"
          --checks verify-adrs,adr-guard,integration-tests,ci-gate --timeout-minutes 40
      - name: Revisión semántica de las reglas de Capa 3
        id: review
        env:
          GH_TOKEN: ${{ github.token }}
          AI_REVIEWER_PROVIDER: ${{ vars.AI_REVIEWER_PROVIDER }}
          AI_REVIEWER_MODEL: ${{ vars.AI_REVIEWER_MODEL }}
          AI_REVIEWER_BASE_URL: ${{ vars.AI_REVIEWER_BASE_URL }}
          AI_REVIEWER_API_KEY: ${{ secrets.AI_REVIEWER_API_KEY }}
        run: >-
          node Tools/ai-reviewer/cli.ts review --pr "$PR_NUMBER"
          --base-sha "$BASE_SHA" --head-sha "$HEAD_SHA" --github-output "$GITHUB_OUTPUT"

  human-approval:
    needs: [ai-review]
    if: ${{ needs.ai-review.outputs.verdict == 'human-approval' }}
    runs-on: ubuntu-24.04
    environment: human-approval
    steps:
      - run: echo "Aprobación humana registrada por el Environment"

  ai-reviewer:
    # Check obligatorio: solo pasa con auto-aprobación o con aprobación humana efectiva.
    needs: [ai-review, human-approval]
    if: ${{ always() }}
    runs-on: ubuntu-24.04
    timeout-minutes: 2
    steps:
      - env:
          REVIEW: ${{ needs.ai-review.result }}
          VERDICT: ${{ needs.ai-review.outputs.verdict }}
          HUMAN: ${{ needs.human-approval.result }}
        run: |
          test "$REVIEW" = "success"
          case "$VERDICT" in
            auto-aprobar) test "$HUMAN" = "skipped" ;;
            human-approval) test "$HUMAN" = "success" ;;
            *) echo "veredicto ausente o desconocido" >&2; exit 1 ;;
          esac
```

| Aspecto | Especificación |
|---|---|
| Entrada | Diff completo por la API de GitHub, cuerpo del PR, **solo** las 50 reglas de Capa 3 de `ADR §6.3` y las fuentes que citan, leídas de la rama base. Todo contenido del PR es dato, nunca instrucción |
| Salida | Veredicto estructurado: por hallazgo, ADR y regla, archivo y línea, explicación; `verdict` = `auto-aprobar` o `human-approval` |
| Auto-aprobación | Solo con checks en verde, sin E1–E7 y sin hallazgos (`ADR-GOV-006 R1`). El revisor no aprueba revisiones ni integra |
| Escalamiento | E1–E4 se calculan con el clasificador de `adr-guard` (el modelo no puede anularlos); E5–E7 los evalúa el modelo |
| Fallo cerrado | Proveedor sin configurar, error, tiempo agotado o diff no analizable → el check falla (`ADR-GOV-006 R3`) |
| Proveedor | Adaptador en `Tools/ai-reviewer/`, sin dependencias externas; proveedor y modelo por variables (`INFRA-P-15`). **Mientras no se configure, ningún PR puede integrarse** |
| Reejecución | Tras corregir o aprobar `adr-guard`, volver a ejecutar `ai-reviewer` |

**Environment `human-approval`:** revisores obligatorios (las mismas personas de `approvers.yml`), "impedir autoaprobación" activado, rama de despliegue `main`. **Condición:** en repositorios privados, los revisores obligatorios de Environments parecen requerir GitHub Enterprise (`DISC-04`). Antes de activar el Ruleset, una persona debe comprobar que su plan lo permite (`INFRA-P-14`). Si no lo permite, `human-approval` pasaría sin pedir aprobación: en ese caso **no se activa la auto-integración** y se requiere una decisión humana documentada que enmiende `ADR-GOV-006`; el control de `adr-guard approval` sigue exigiendo la revisión para E1–E4, pero no cubre E5–E7.

### 7.6 Configuración del repositorio (declarada en `.github/adr-guard/ruleset.json`)

| Ajuste | Valor |
|---|---|
| Rama protegida | `main`; solo por Pull Request |
| Checks obligatorios | `verify-adrs`, `adr-guard`, `integration-tests`, `ai-reviewer` (`ADR-GOV-007 R1`) y `ci-gate` (`DC-16`), fijados a la aplicación GitHub Actions |
| Ramas actualizadas | Obligatorio; descartar aprobaciones obsoletas |
| Prohibido | Push forzado, borrado de `main`, listas de exención para agentes y automatismos |
| `CODEOWNERS` | Las rutas protegidas de §7.4 y las de TESTs §2.4 (AS-04, AS-10) |
| Environments | `ai-reviewer`, `governance`, `human-approval`, limitados a `main` |
| Actions | Permisos por defecto de solo lectura; sin crear ni aprobar PR; solo acciones fijadas por SHA |

**Orden de arranque (una sola vez):** el primer PR que crea `.github/`, `Tools/` y los controles lo revisa e integra una persona; el Ruleset se activa **después**, porque los workflows `pull_request_target` y los scripts de la rama base aún no existen en ese primer PR. Se activa cuando los cinco checks obligatorios pasen en verde sobre `main`, lo que exige al menos una prueba real en cada suite (`passWithNoTests: false`); hasta entonces todo Pull Request a `main` lo revisa e integra una persona (secuencia en `ProveeEventos_ImplBacklog.md` §4.8).

### 7.7 Contrato diferido de CD

No se crea ningún workflow de despliegue en Etapa 1. Cuando se resuelvan `INFRA-P-01`–`11`, el CD deberá cumplir:

| Elemento | Contrato |
|---|---|
| Disparador `staging` | Integración en `main` con `post-merge-e2e` correcto |
| Disparador `production` | Promoción manual del mismo digest, con aprobación humana (`ADR-GOV-006 R6`) |
| Entrada | Digests de `web`, `api`/`worker` y `migrate` construidos una sola vez |
| Secuencia | §2.3: migración como paso único y compatible → semillas de referencia → API y worker → web → *smoke* y E2E |
| Fallo | Detener la promoción; la estrategia de reversión remota está por definir (`INFRA-P-11`) |
| Identidad | Credenciales de vida corta; sin secretos de larga duración si la plataforma lo permite |

---
## Sección 8 — Estrategia de Despliegue y Rollback (Local — Etapa 1)

> **Límite:** todo lo de esta sección aplica **solo** al entorno local con Docker Compose y a sus datos sintéticos. La estrategia de despliegue remoto (Blue-Green, Canary o Rolling) y el rollback productivo quedan **diferidos hasta definir infraestructura** (`INFRA-P-11`).

### 8.1 Levantar

| Paso | Comando | Resultado esperado |
|---|---|---|
| 1 | `npm ci` | Dependencias según `package-lock.json` |
| 2 | `npm run env:init` (solo la primera vez) | `.env` con permisos 600 |
| 3 | `npm run dev:up` | Código de salida 0: infraestructura sana, `db-bootstrap`, `migrate`, `db-rls` y `seed` completados, aplicación sana |
| 4 | Verificar (§8.3) | Todo en verde |

Desarrollo con recarga: `npm run dev:watch` (sincroniza `backend/src` y `frontend/src`; reconstruye ante cambios de dependencias o del esquema).

### 8.2 Actualizar y reconstruir

| Situación | Procedimiento |
|---|---|
| Cambios de código | Ninguno con `dev:watch`; si no, `npm run dev:up` |
| `git pull` con dependencias nuevas | `npm ci && npm run dev:up` |
| `git pull` con migraciones nuevas | `npm run dev:up` (el servicio `migrate` las aplica antes de la aplicación) |
| Cambio de `.env` | `npm run dev:up` (Compose recrea los servicios afectados) |
| Cambio de `docker/images.env` | `npm run dc -- --profile dev pull postgres pgbouncer redis mailpit` y `npm run dev:up`. Un cambio de **versión mayor** de PostgreSQL exige reset (§8.4) |
| Imagen sospechosa o caché corrupta | `npm run dc -- --profile dev build --no-cache <servicio>` y `npm run dev:up` |

### 8.3 Verificar salud

```bash
npm run dev:ps                                                   # servicios "healthy"; los de una vez, "exited (0)"
curl --fail --silent http://localhost:4000/health/ready
curl --fail --silent http://localhost:3000/health/live
npm run dc -- --profile dev exec worker node -e "fetch('http://127.0.0.1:4001/health/ready').then(r=>process.exit(r.ok?0:1))"
npm run db:migrate:status                                        # sin migraciones pendientes ni fallidas
npm run dev:logs                                                 # revisar errores de arranque
```

| Síntoma | Causa probable | Acción |
|---|---|---|
| Compose indica "define VAR" | `.env` incompleto o plantilla nueva | Comparar con `.env.example`; `env:init -- --force` regenera todo (exige reset si cambian claves de base) |
| Servicio sale con código 78 | Validación de entorno (§3.4) | Leer el nombre de la variable en el log |
| `db-bootstrap` falla por autenticación | `POSTGRES_PASSWORD` distinta de la del volumen | Reset (§8.4) |
| `migrate` falla | Migración con error | §8.6 |
| Puerto ocupado | Otro proceso o el perfil `test` levantado | `npm run test:stack:down` o cambiar `*_PORT` en `.env` |

### 8.4 Reset controlado del estado local

```bash
npm run dev:reset     # DESTRUCTIVO: elimina contenedores, redes y volúmenes del proyecto local
npm run dev:up        # base desde cero, migraciones y semillas deterministas
```

- Elimina **todos** los datos locales (base, colas y documentos). Solo afecta al proyecto Compose `proveeeventos` del equipo; confirmar antes con `npm run dev:ps` que se está en el proyecto correcto.
- El stack de pruebas se limpia aparte: `npm run test:stack:down`.
- Es el camino **preferido** ante cualquier estado local inconsistente: los datos son sintéticos y reproducibles.

### 8.5 Rollback determinista

#### Código y contenedores

| Caso | Procedimiento |
|---|---|
| Volver a un commit anterior (reconstrucción) | `git switch --detach <sha>` → `npm ci` → comprobar migraciones (fila siguiente) → `npm run dev:up` |
| El commit destino tiene **menos** migraciones que la base local | `npm run dev:reset` antes de `dev:up`: `migrate deploy` no revierte |
| Volver a imágenes ya construidas (perfil `test`) | Antes de actualizar, etiquetar; para revertir, reetiquetar y levantar sin construir |

```bash
# Antes de actualizar: conservar las imágenes actuales con el commit del que salieron
sha="$(git rev-parse --short HEAD)"
for image in backend web migrate dev-stubs; do
  docker tag "proveeeventos/$image:local" "proveeeventos/$image:sha-$sha"
done

# Rollback a las imágenes de <sha-anterior> (el esquema debe ser compatible)
for image in backend web migrate dev-stubs; do
  docker tag "proveeeventos/$image:sha-<sha-anterior>" "proveeeventos/$image:local"
done
npm run dc -- -p pe-test --profile test up -d --no-build --wait
```

El etiquetado debe hacerse con el árbol en el mismo commit con el que se construyeron las imágenes. Las etiquetas son locales: no se publican (`INFRA-P-06`).

#### Configuración

`.env` no se versiona: ante un cambio que rompa el arranque, regenerar desde la plantilla del commit destino (`npm run env:init -- --force`) y aplicar reset si cambiaron las credenciales de base.

### 8.6 Fallos de migración en desarrollo

| Situación | Estrategia |
|---|---|
| Migración **aún no integrada** en `main` falla o es incorrecta | Corregirla en la rama y `npm run dev:reset && npm run dev:up` |
| Migración **ya integrada** es incorrecta | ***Roll-forward***: nueva migración correctiva. La anterior es inmutable (§6.4) |
| Migración quedó marcada como fallida y se quiere conservar el estado local | 1) ejecutar su `down.sql` para limpiar lo aplicado a medias; 2) `npm run dc -- run --rm migrate npx --no-install prisma migrate resolve --rolled-back <nombre>`; 3) corregir y `npm run db:migrate`. Si hay duda, reset |
| Falla `20_rls` | Se aplica en una sola transacción: no deja cambios parciales. Corregir y repetir |
| `lock_timeout` agotado | Detener `api` y `worker` (`npm run dc -- --profile dev stop api worker`) y repetir |

Nunca se edita a mano el historial de migraciones ni el esquema de la base (`ADR-DATA-014 R1`).

### 8.7 Criterios de un rollback local correcto

1. `npm run dev:ps` sin servicios no sanos.
2. `db:migrate:status` coherente con el commit activo.
3. `/health/ready` en 200 para API y worker.
4. Cuando el rollback afecte a la aplicación, `npm run test:e2e:smoke` en verde sobre el perfil `test`:
   - tras un rollback **por reconstrucción**, levantarlo con `npm run test:stack:up`;
   - tras un rollback **por reetiquetado**, usar el comando `up -d --no-build --wait` de §8.5. **No** usar `test:stack:up`: reconstruye desde el árbol actual y deshace el reetiquetado.

---
## Sección 9 — Backups y Recuperación `[NO APLICA EN ETAPA 1 — DIFERIDO]`

**`[NO APLICA EN ETAPA 1 — DIFERIDO]`**

Este documento no define diseño, políticas ni procedimientos de backups y recuperación. Su definición depende de decisiones de infraestructura pendientes: motor o servicio administrado de base de datos (`INFRA-P-04`), almacenamiento de respaldos y objetivos de recuperación aplicables a ese servicio (`INFRA-P-12`), región y residencia (`INFRA-P-02`) y presupuesto (`INFRA-P-17`).

Los requisitos de negocio ya aprobados en las fuentes siguen vigentes y no se modifican ni se desarrollan aquí. Alcance previsto: `Plan0003_Cloud_Infra_CD_Observability.md`.

---

## Sección 10 — Monitoreo y Alertas `[NO APLICA EN ETAPA 1 — DIFERIDO]`

**`[NO APLICA EN ETAPA 1 — DIFERIDO]`**

Este documento no define diseño ni stack de monitoreo y alertas. Su definición depende de decisiones de infraestructura pendientes: plataforma de hosting (`INFRA-P-01`), agregación de logs, APM y canales de alertamiento (`INFRA-P-13`).

La aplicación mantiene el contrato de logging estructurado y los endpoints `/health/live` y `/health/ready` definidos en SAD §10.8 y §12.1 y en `ADR-OBS-001` y `ADR-OBS-004`, para facilitar su conexión futura.

---

## Sección 11 — Decisiones de Infraestructura Pendientes (`INFRA-P-nn`)

Estas decisiones pendientes impiden avanzar hacia `staging` y `production`, el despliegue remoto, los backups y el monitoreo. Ninguna bloquea la ejecución local. `INFRA-P-14` e `INFRA-P-15` **sí condicionan la integración de Pull Requests** en CI.

| ID | Decisión pendiente | Qué fijan ya las fuentes | Desbloquea en Etapa 2 |
|---|---|---|---|
| INFRA-P-01 | Proveedor y modelo de hosting (cloud, VPS o PaaS) | Vercel + Railway es **candidato**, sujeto a prueba de aceptación técnica ponderada frente a una alternativa (SAD §13.1, DEC-013). No está decidido | §2, §7.7, §10 |
| INFRA-P-02 | Región y residencia de datos | Preferencia por Colombia o región cercana; análisis legal (DEC-014) | §2, §9 |
| INFRA-P-03 | Hosting de contenedores, orquestación, réplicas y recursos | API y worker como procesos separados y sin estado (SAD §3.2; SRS-NFR-SCAL-001) | §2.3, §7.7 |
| INFRA-P-04 | PostgreSQL administrado o autogestionado; extensiones, roles propios y PgBouncer o equivalente | PostgreSQL 15+, extensiones y roles del anexo, pooler en modo transacción (TDD §7.3; pregunta Q-11 abierta) | §5, §6, §9 |
| INFRA-P-05 | Redis administrado y su persistencia | Colas persistentes (`ADR-OBS-005 R6`) | §2.3 |
| INFRA-P-06 | Registro de imágenes, firma y promoción | Sin publicación en Etapa 1 | §7.3, §7.7, §8.5 |
| INFRA-P-07 | DNS, TLS, CDN y exposición de red (incluida la red privada de métricas) | TLS 1.2+ (SRS-NFR-SEC-001) | §2, §3.2 |
| INFRA-P-08 | Gestor de secretos productivo, inyección y rotación | Secretos fuera del repositorio (`ADR-SEC-005`) | §4.4 |
| INFRA-P-09 | Almacenamiento productivo de documentos PDF | Acceso protegido o URL firmada (SAD §9.7; `ADR-SEC-009 R4`); servicio sin definir | §3.2 (`DOCUMENT_STORAGE_DRIVER`) |
| INFRA-P-10 | Cuentas y tenants por ambiente de Auth0, SendGrid (dominio con SPF, DKIM y DMARC), Cloudinary y Google Maps | Proveedores fijados por el stack; cuentas no creadas | §2.1, §3.2 |
| INFRA-P-11 | CD: estrategia de despliegue (Blue-Green, Canary, Rolling), rollback remoto y migración en producción | Aprobación humana para producción; esquema compatible durante el cambio | §7.7, §8 |
| INFRA-P-12 | Política e implementación de backups y recuperación (incluidos objetivos RPO y RTO sobre la plataforma elegida) | Objetivos aprobados en las fuentes (DEC-012) | §9 |
| INFRA-P-13 | Plataforma de observabilidad, APM, agregación de logs y canales de alerta | Contrato de logs y salud (SAD §10.8, §12.1) | §10 |
| INFRA-P-14 | Plan de GitHub y visibilidad del repositorio: Rulesets, secretos de Environment, revisores obligatorios y *secret scanning* | `ADR-GOV-006`/`007` los suponen | §4.2, §7.5, §7.6 |
| INFRA-P-15 | Proveedor, modelo y presupuesto del agente `ai-reviewer` | Reglas, entradas, salida y fallo cerrado (`ADR §6.3`) | §7.5 |
| INFRA-P-16 | Ambiente `staging-perf` para carga, DAST y verificaciones nocturnas | TESTs §2.3 y §3.4 | §7.3 |
| INFRA-P-17 | Presupuesto de infraestructura y de terceros | — | §2, §9, §10 |

---
## Sección 12 — Registro de Decisiones Autónomas de DevOps (`DC-nn`)

Decisiones tomadas sin consulta, dentro de la Etapa 1. No sustituyen a `DEC-*`, `TEC-*` ni ADR; si una fuente dice otra cosa, prevalece la fuente.

| ID | Decisión | Justificación |
|---|---|---|
| DC-01 | Imágenes fijadas por etiqueta y digest en `docker/images.env`; los `ARG NODE_IMAGE` repiten ese valor y el CI verifica la igualdad | Reproducibilidad, una fuente y `docker build` usable por sí solo |
| DC-02 | Workspaces npm `backend` y `frontend` con un solo `package-lock.json` | `ADR-STACK-001`/`003`: npm y lockfile versionado |
| DC-03 | Un Dockerfile para backend (API y worker comparten imagen), otro para web y otro para los dobles | SAD §3.2: mismos módulos, procesos separados |
| DC-04 | Un solo `docker-compose.yml` con perfiles; sin `override` versionado | `.gitignore` excluye `docker-compose.override.yml`, reservado a ajustes personales |
| DC-05 | Variables explícitas por servicio, sin `env_file` global | Mínimo privilegio: `web` no ve credenciales de datos |
| DC-06 | Ninguna configuración compilada en imágenes; sin `NEXT_PUBLIC_*` | Mismo artefacto en todos los ambientes |
| DC-07 | `process.env` solo en los módulos de configuración (y `prisma.config.ts`) | Validación única y tipada |
| DC-08 | Prueba que iguala esquemas de entorno y `.env.example` | Evita deriva |
| DC-09 | Recarga con `compose watch` (sincronización) en lugar de montar el código | Evita problemas de permisos y de ocultar el cliente Prisma generado |
| DC-10 | Dobles de Auth0 con emisor público y canal interno separado, solo `development`/`test` | El navegador y los contenedores resuelven direcciones distintas |
| DC-11 | `web` expone `/health/live` | El SAD solo define salud de API y worker; Compose y la imagen necesitan comprobarlo |
| DC-12 | PDF local en volumen compartido por API y worker con URL firmada | Cumple SAD §9.7 sin elegir proveedor; se descarta añadir un almacén S3 no documentado |
| DC-13 | Una migración inicial para `01`–`11` | TDD §10.1 lo admite; menos manipulación manual del SQL base |
| DC-14 | `00` y `20_rls` como pasos propios (`db-bootstrap`, `db-rls`), con archivos protegidos | `00` exige administrador; `20` no debe aplicarse por accidente |
| DC-15 | PgBouncer también en local | Detecta incompatibilidades con modo transacción antes de producción (TDD §7.3) |
| DC-16 | Agregador `ci-gate` obligatorio además de los cuatro checks del ADR | Evita que un job omitido cuente como superado |
| DC-17 | Tras una aprobación humana se reejecuta el job; sin disparador `pull_request_review` | La definición debe provenir de la rama base |
| DC-18 | Solo ramas del propio repositorio; no se activa la descarga de forks en `pull_request_target` | Los agentes trabajan en el repositorio; evita ejecutar código no confiable con privilegios |
| DC-19 | `ProveeEventos_UXUI.md`, `ProveeEventos_TESTs.md` y este documento se protegen como normativos | Cierra `DISC-06` hasta enmendar el ADR |
| DC-20 | Proyectos Vitest `multi-tenant` y `security` en el mismo `vitest.config.ts` | Compatibiliza TESTs con `ADR-GOV-002 R2` |
| DC-21 | PostgreSQL 16 por defecto en local; 15 en la matriz de CI | `ADR-TEST-002 R1` exige ambas |
| DC-22 | Los controles que ejecutan código del PR corren sin privilegios (`adr-guard-runtime`) con scripts de la rama base | Separa ejecución no confiable y credenciales (`ADR §6.2`) |
| DC-23 | Dobles locales propios sin dependencias en `Tools/dev-stubs`; correo por SMTP a Mailpit solo en `development`/`test` | Entorno funcional sin cuentas externas |
| DC-24 | Puertos solo en `127.0.0.1`; PostgreSQL y Redis sin publicar; red `data` interna | Reduce exposición |
| DC-25 | El perfil `test` usa imágenes `runner` en un proyecto `pe-test`; la integración usa Testcontainers | Un solo Compose y datos de prueba desechables |
| DC-26 | CI sin secretos almacenados para pruebas | Menor superficie de fuga |
| DC-27 | Cobertura comparada contra el artefacto de `main` | Implementa `ADR-TEST-006 R4` sin ejecutar dos veces las pruebas |
| DC-28 | Aislamiento de red de las suites con reglas por grupo en el runner | Implementa `ADR-TEST-002 R3`; pendiente de validar en ejecución real |
| DC-29 | Semillas separadas en referencia y sintéticas, con bloqueo por `APP_ENV` | Resuelve `DISC-02` |
| DC-30 | Nombres de variables definidos aquí; solo `DATABASE_URL` y `DIRECT_URL` venían de las fuentes | Contrato necesario para implementar |
| DC-31 | Imágenes propias con `pull_policy: build` (o `never` en el servicio que las reutiliza) | Evita que Compose descargue de un registro público una imagen con nombre local (riesgo de suplantación) |
| DC-32 | Los datos E2E se preparan con el servicio `seed` y por la API pública; no hay endpoint interno de pruebas ni se publica PostgreSQL | Resuelve `DISC-08` sin ampliar la superficie |
| DC-33 | El *smoke* E2E se invoca con `test:e2e:smoke` (TESTs §15.3), con los 12 escenarios de SRS §8 en `backend/src/tests/e2e/srs-section-8/` | Selección determinista del gate G-09 por carpeta y navegador |
| DC-34 | En CI, k6 se ejecuta desde `K6_IMAGE` fijada por digest, no desde un binario instalado | Versión reproducible; k6 no es una dependencia npm |

---

## Sección 13 — Guía de Handoff para el Agente Implementador (Etapa 1)

Plan receptor: `Plan0002_Local_Docker_CI_Implementation.md`. Requisitos previos: estructura de código de `ADR §2.5` y los archivos de Capa 1 de `ADR §6.1` (`.nvmrc` = `26`, `.npmrc`, `package.json`, `tsconfig*`, `eslint.config.mjs`, `.dependency-cruiser.cjs`, `backend/vitest.config.ts`, `.prettierrc.json`, `Tools/eslint-plugin-pe/`).

### 13.1 Archivos a crear

| Orden | Archivo | Origen en este documento |
|---|---|---|
| 1 | `.env.example` | §3.3 (copia literal) |
| 1 | `scripts/dev/gen-env.sh` | §4.1 (copia literal) |
| 1 | `docker/images.env` | §5.2 |
| 1 | `.dockerignore` | §5.3 |
| 1 | `playwright.config.ts` (raíz) | §13.4 |
| 2 | `backend/Dockerfile`, `frontend/Dockerfile`, `Tools/dev-stubs/Dockerfile` | §5.3 |
| 2 | `docker-compose.yml` | §5.4 |
| 2 | `docker/pgbouncer/pgbouncer.ini`, `docker/pgbouncer/start.sh` | §5.5 |
| 2 | `scripts/db/bootstrap.sh`, `scripts/db/apply-rls.sh` | §5.5 |
| 2 | `Tools/adr-guard/gitleaks.toml` | §5.5 |
| 2 | `Tools/dev-stubs/server.ts` | §5.6 |
| 3 | `backend/src/shared/config/env.ts`, `frontend/src/lib/config/env.ts`, `frontend/src/instrumentation.ts` y sus pruebas | §3.4 |
| 3 | `backend/prisma.config.ts`, `backend/src/prisma/{schema.prisma,bootstrap,migrations,rls,seed}` | §6 |
| 3 | `scripts/db/check-annex.ts`, `scripts/db/check-catalog.ts` | §6.4, §7.3 |
| 3 | Scripts de `package.json` | §5.7 y §13.2 |
| 4 | `scripts/ci/{prepare-env.sh,run-offline.sh,testcontainers-reaper-image.ts,compat-n1.sh}` | §7.3 |
| 4 | `Tools/adr-guard/{cli.ts,coverage-ratchet.ts,semgrep/,banned-packages.json}` | §7.4; `ADR §6.2` |
| 4 | `Tools/ai-reviewer/{cli.ts,…}` | §7.5; `ADR §6.3` |
| 4 | `.github/workflows/{ci-quality-and-tests,adr-guard,ai-reviewer}.yml` | §7.3–§7.5 |
| 4 | `.github/adr-guard/{approvers.yml,suppressions.yml,ruleset.json}`, `.github/CODEOWNERS`, plantilla de Pull Request | §7.4, §7.6; `ADR-GOV-005` |
| 5 | Configuración remota (persona): Environments, variables, secreto, Ruleset | §4.2, §7.6 |

Los scripts `.sh` se crean con modo `0755`.

### 13.2 Scripts npm requeridos además de §5.7

| Script | Debe ejecutar |
|---|---|
| `verify:adrs` y `verify:{format,types,lint,deps,arch}` | Literal de `ADR §6.1` |
| `verify:env` | Prueba de `DC-08` |
| `build` | Compilación de `backend` y `frontend` |
| `test:unit`, `test:int`, `test:api`, `test:mt`, `test:conc` | Suites `TC-UNIT`, `TC-INT`, `TC-API`, `TC-MT`, `TC-CONC` según TESTs §15.3, con las rutas de `ADR §2.5` (`DISC-11`). El arnés de Testcontainers aplica `bootstrap/` (administrador), `migrate deploy` y `rls/` antes de las pruebas |
| `test:sec` | **Solo** las pruebas Vitest de `TC-SEC`, ejecutables sin red; el análisis estático corre en sus propios jobs (`DISC-12`) |
| `test:e2e`, `test:e2e:smoke` | Playwright (`TC-E2E`): suite completa y *smoke* (`DC-33`) |
| `test:arch` | Solo `backend/src/tests/architecture` (TESTs §15.3); no sustituye a `verify:arch` |
| `test:infra` | Comprobaciones de `backend/src/tests/infra` contra el stack Compose levantado; queda fuera de `test:int` y de `integration-suite` |
| `test:load`, `test:load:full` | Uso fuera de CI, según TESTs §15.3; CI ejecuta k6 por imagen (`DC-34`) |
| `prisma:generate`, `build`, `dev:api`, `dev:worker` (en `backend`) | §5.3 |
| `build`, `dev` (en `frontend`) | §5.3 |

### 13.3 Criterios de aceptación locales verificables

| ID | Criterio | Comprobación |
|---|---|---|
| AC-01 | Generación de entorno | `npm run env:init` crea `.env` con modo 600 y `grep -c __GENERATE .env` devuelve 0 |
| AC-02 | Compose válido | `config --quiet` en 0 para los perfiles por defecto, `dev`, `test` y `tools` |
| AC-03 | Arranque desde cero | `npm run dev:reset && npm run dev:up` termina en 0; todos los servicios sanos o `exited (0)` |
| AC-04 | Repetibilidad | Un segundo `npm run dev:up` termina en 0 sin cambios en la base |
| AC-05 | *Fail-fast* | Quitar `TOKEN_DERIVATION_KEYS` impide arrancar; un valor con formato inválido hace salir al proceso con 78 y el log muestra el nombre, no el valor |
| AC-06 | Imágenes | `docker image inspect` muestra usuario `node`; `docker history --no-trunc` no contiene valores de `.env` |
| AC-07 | Roles y pooler | `pe_api` por PgBouncer reporta `statement_timeout = 5s` y no puede crear tablas |
| AC-08 | Aislamiento de red | `web` no resuelve `postgres` ni `redis` |
| AC-09 | RLS | `DB_APPLY_RLS=true` aplica `20_rls` en `development`; con `APP_ENV=production` sale con 78 |
| AC-10 | Migraciones | Base desde cero en PostgreSQL 15 y 16 sin deriva |
| AC-11 | Dobles | Inicio de sesión local completo y correo de una solicitud visible en Mailpit con enlace `/r#…` |
| AC-12 | Perfil `test` | `npm run test:stack:up` sano y `test:e2e:smoke` en verde |
| AC-13 | Rollback | Procedimiento de §8.5 ejecutado y §8.7 cumplido |
| AC-14 | CI bloquea sabotajes | PR de prueba con `eslint-disable`, con `.skip`, con una migración integrada modificada, con un secreto ficticio detectable o con un documento normativo y código mezclados: cada uno falla su check |
| AC-15 | Revisor cerrado | Sin proveedor configurado, `ai-reviewer` falla |
| AC-16 | Suites sin red | `run-offline.sh curl https://registry.npmjs.org` falla en el runner |
| AC-17 | Sin secretos en el repositorio | `npm run secrets:scan` en 0 y `git ls-files` sin `.env` ni `*.pem` |

### 13.4 Contrato de URLs e identidades para pruebas E2E y de infraestructura

No se añaden variables: `playwright.config.ts` y las suites `e2e/` e `infra/` leen `.env` (§3.3) y usan estos valores.

| Destino | Valor |
|---|---|
| Web (`baseURL` de Playwright) | `APP_BASE_URL` (local: `http://localhost:3000`) |
| API | `http://127.0.0.1:${API_PORT}` |
| API de Mailpit | `http://127.0.0.1:${MAILPIT_UI_PORT}` |
| Dobles locales (`dev-stubs`) | `http://127.0.0.1:${DEV_STUBS_PORT}` |
| Identidades de prueba | Los usuarios sintéticos de las semillas, que el doble de identidad ofrece en `/authorize` (§5.6); sin contraseñas ni credenciales en las pruebas |
