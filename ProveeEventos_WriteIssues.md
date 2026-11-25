# ProveeEventos — Materialización del Backlog en GitHub (`ProveeEventos_WriteIssues.md`)

## Cabecera y Metadatos de Ejecución

| Campo | Valor |
|:---|:---|
| Fecha y hora de ejecución | 2026-11-25, de 11:37:58 a 11:50:37 (UTC−06:00), en dos tramos; comprobación de idempotencia a las 11:51 |
| Documento fuente | `ProveeEventos_ImplBacklog.md` v1.1 (confirmado en `main`, commit `e4bf13c`) |
| `ISSUES_REPO` | `RubyMurcia/ProveeEventos` (público) |
| `CODE_REPO` | `RubyMurcia/ProveeEventos` (el mismo) |
| Rama base de código | `main` |
| Cuenta que ejecutó | `RubyMurcia` (permiso `ADMIN`) |
| Estado final | `COMPLETADO CON INCIDENCIAS` (ver Sección 6) |

---

## Sección 1 — Resumen Cuantitativo de Materialización

| Métrica | Valor |
|:---|---:|
| Labels del backlog creadas | 68 |
| Labels del backlog actualizadas | 0 |
| Labels en el repositorio (incluye 10 predeterminadas de GitHub, sin tocar) | 78 |
| Milestones creados / existentes | 7 / 0 |
| Issues `ISS-CODE` | 61 |
| Issues `ISS-TEST` | 58 |
| **Total de Issues** | **119** |
| Etapa 1 / Etapa 2 | 48 / 71 |
| `frontier` / `economy` | 50 / 69 |
| `status:ready` (cola inicial) / `status:backlog` | 1 / 118 |
| Duplicados detectados | 0 |

---

## Sección 2 — Taxonomía de Labels y Milestones Configurados

### 2.1 Labels

Incluye el catálogo completo del backlog §3.1 y §11, también las labels sin Issues todavía. `wave` llega a 13 y `epic` a `EP-23`, que es lo que usa el backlog v1.1.

| Nombre | Color | Descripción | Acción: Creada/Existente | Issues |
|:---|:---|:---|:---|---:|
| `status:backlog` | `#cfd3d7` | Creado; dependencias sin done | Creada | 118 |
| `status:ready` | `#0e8a16` | Elegible: todas las depends_on en done | Creada | 1 |
| `status:in-progress` | `#fbca04` | Reclamado por un agente con lease vigente | Creada | 0 |
| `status:in-review` | `#1d76db` | PR abierto en revisión | Creada | 0 |
| `status:changes-requested` | `#d93f0b` | CI rojo o revisión pide cambios | Creada | 0 |
| `status:done` | `#5319e7` | Integrado y criterios verificados | Creada | 0 |
| `status:blocked` | `#b60205` | Impedimento técnico real | Creada | 0 |
| `status:needs-human` | `#e99695` | Escalado a una persona | Creada | 0 |
| `stage:mvp-1` | `#c5def5` | MVP Etapa 1: vertical slice en Docker | Creada | 48 |
| `stage:mvp-2` | `#7aa7e0` | MVP Etapa 2: completitud del MVP | Creada | 71 |
| `type:code` | `#006b75` | Codificación | Creada | 54 |
| `type:test` | `#0f9d8a` | Pruebas | Creada | 61 |
| `type:infra` | `#2f7f86` | Infraestructura | Creada | 3 |
| `type:docs` | `#8fd3d9` | Documentación | Creada | 1 |
| `tier:frontier` | `#6f42c1` | Subagente con modelo frontera | Creada | 50 |
| `tier:economy` | `#d4c5f9` | Subagente con modelo económico | Creada | 69 |
| `role:backend-architect` | `#f9d0c4` | Codificador: casos de uso transaccionales | Creada | 21 |
| `role:backend-core` | `#f9d0c4` | Codificador: CRUD y semillas | Creada | 24 |
| `role:frontend-app` | `#f9d0c4` | Codificador: pantallas Next.js | Creada | 9 |
| `role:devops-container` | `#f9d0c4` | DevOps: Docker y CI | Creada | 5 |
| `role:qa-domain` | `#f9d0c4` | Tester: dominio | Creada | 0 |
| `role:qa-integration` | `#f9d0c4` | Tester: integración y contrato | Creada | 45 |
| `role:qa-e2e` | `#f9d0c4` | Tester: recorridos E2E | Creada | 10 |
| `role:qa-security` | `#f9d0c4` | Tester: concurrencia y seguridad | Creada | 5 |
| `role:qa-perf` | `#f9d0c4` | Tester: rendimiento | Creada | 0 |
| `role:qa-lead` | `#f9d0c4` | Validador de pruebas | Creada | 0 |
| `role:arch-reviewer` | `#f9d0c4` | Validador de arquitectura | Creada | 0 |
| `priority:P0` | `#b60205` | Bloquea la demo o es crítico de integridad | Creada | 54 |
| `priority:P1` | `#ff9f1c` | Necesario para el MVP completo | Creada | 55 |
| `priority:P2` | `#fef2c0` | Mejora que no bloquea recorridos | Creada | 10 |
| `wave:0` | `#bfdadc` | Ola de ejecución paralela Wave-0 | Creada | 7 |
| `wave:1` | `#bfdadc` | Ola de ejecución paralela Wave-1 | Creada | 15 |
| `wave:2` | `#bfdadc` | Ola de ejecución paralela Wave-2 | Creada | 7 |
| `wave:3` | `#bfdadc` | Ola de ejecución paralela Wave-3 | Creada | 7 |
| `wave:4` | `#bfdadc` | Ola de ejecución paralela Wave-4 | Creada | 4 |
| `wave:5` | `#bfdadc` | Ola de ejecución paralela Wave-5 | Creada | 18 |
| `wave:6` | `#bfdadc` | Ola de ejecución paralela Wave-6 | Creada | 11 |
| `wave:7` | `#bfdadc` | Ola de ejecución paralela Wave-7 | Creada | 12 |
| `wave:8` | `#bfdadc` | Ola de ejecución paralela Wave-8 | Creada | 6 |
| `wave:9` | `#bfdadc` | Ola de ejecución paralela Wave-9 | Creada | 9 |
| `wave:10` | `#bfdadc` | Ola de ejecución paralela Wave-10 | Creada | 5 |
| `wave:11` | `#bfdadc` | Ola de ejecución paralela Wave-11 | Creada | 8 |
| `wave:12` | `#bfdadc` | Ola de ejecución paralela Wave-12 | Creada | 6 |
| `wave:13` | `#bfdadc` | Ola de ejecución paralela Wave-13 | Creada | 4 |
| `epic:EP-01` | `#ededed` | Foundation y Docker | Creada | 14 |
| `epic:EP-02` | `#ededed` | Identidad de organizador y App Shell | Creada | 4 |
| `epic:EP-03` | `#ededed` | Registro de proveedores | Creada | 4 |
| `epic:EP-04` | `#ededed` | Catálogos maestros, aprobación mínima y búsqueda pública | Creada | 4 |
| `epic:EP-05` | `#ededed` | Evento, ítem y cotización rápida de un proveedor | Creada | 4 |
| `epic:EP-06` | `#ededed` | e-RFQ por link: correo real, formulario público y cierre de contratación | Creada | 8 |
| `epic:EP-07` | `#ededed` | Templates de presupuesto y flujo grupal | Creada | 6 |
| `epic:EP-08` | `#ededed` | Verificación end-to-end en Docker y runbook | Creada | 4 |
| `epic:EP-09` | `#ededed` | Instant Book y capacidad dos niveles | Creada | 3 |
| `epic:EP-10` | `#ededed` | RFQ completo | Creada | 8 |
| `epic:EP-11` | `#ededed` | Cotización integral, versiones y PDF | Creada | 6 |
| `epic:EP-12` | `#ededed` | Disponibilidad y propuestas de cambio | Creada | 4 |
| `epic:EP-13` | `#ededed` | Cancelaciones por etapas y comisiones | Creada | 4 |
| `epic:EP-14` | `#ededed` | Reseñas B2B | Creada | 2 |
| `epic:EP-15` | `#ededed` | Verificación y suspensión de proveedores | Creada | 4 |
| `epic:EP-16` | `#ededed` | Notificaciones completas | Creada | 4 |
| `epic:EP-17` | `#ededed` | WhatsApp Click-to-Chat y asistente | Creada | 4 |
| `epic:EP-18` | `#ededed` | Administración y cumplimiento | Creada | 4 |
| `epic:EP-19` | `#ededed` | Seguridad productiva y RLS verificada | Creada | 3 |
| `epic:EP-20` | `#ededed` | Accesibilidad, carga y observabilidad | Creada | 3 |
| `epic:EP-21` | `#ededed` | Membresías avanzadas y transferencia | Creada | 2 |
| `epic:EP-22` | `#ededed` | Planes, límites y vencimiento | Creada | 2 |
| `epic:EP-23` | `#ededed` | Cierre de cobertura del MVP (brechas RR-04) | Creada | 18 |
| `bootstrap:true` | `#000000` | Primer PR de gobernanza: lo integra una persona (backlog 4.8) | Creada | 1 |

### 2.2 Milestones

Asignación por épica según el backlog §2.3.

| # | Título | Etapa | Issues Asociados |
|---:|:---|:---|:---|
| [1](https://github.com/RubyMurcia/ProveeEventos/milestone/1) | `M0-Foundation` | MVP-Stage-1 | **14**: `ISS-CODE` 001, 002, 003, 004, 005, 006, 007 · `ISS-TEST` 001, 002, 003, 004, 005, 006, 007 |
| [2](https://github.com/RubyMurcia/ProveeEventos/milestone/2) | `M1-Actores` | MVP-Stage-1 | **12**: `ISS-CODE` 008, 009, 010, 011, 012, 013 · `ISS-TEST` 008, 009, 010, 011, 012, 013 |
| [3](https://github.com/RubyMurcia/ProveeEventos/milestone/3) | `M2-Cotizacion` | MVP-Stage-1 | **4**: `ISS-CODE` 014, 015 · `ISS-TEST` 014, 015 |
| [4](https://github.com/RubyMurcia/ProveeEventos/milestone/4) | `M3-Link-Correo` | MVP-Stage-1 | **8**: `ISS-CODE` 016, 017, 018, 019 · `ISS-TEST` 016, 017, 018, 019 |
| [5](https://github.com/RubyMurcia/ProveeEventos/milestone/5) | `M4-Demo-Etapa1` | MVP-Stage-1 | **10**: `ISS-CODE` 020, 021, 022, 023, 024 · `ISS-TEST` 020, 021, 022, 023, 024 |
| [6](https://github.com/RubyMurcia/ProveeEventos/milestone/6) | `M5-MVP-Funcional` | MVP-Stage-2 | **65**: `ISS-CODE` 025, 026, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061 · `ISS-TEST` 025, 027, 028, 029, 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061 |
| [7](https://github.com/RubyMurcia/ProveeEventos/milestone/7) | `M6-Release-MVP` | MVP-Stage-2 | **6**: `ISS-CODE` 047, 048, 049, 050 · `ISS-TEST` 047, 049 |

---

## Sección 3 — Tabla Maestra de Mapeo (`ID Lógico ↔ GitHub #N`)

`Coder/Tester Role` muestra `coder_role / tester_role`. El estado es el asignado al materializar.

| ID Lógico | GitHub # | URL | Tipo | Etapa | Wave | Modelo | Coder/Tester Role | Estado Inicial | Par (#N) | Depende de (#N) |
|:---|---:|:---|:---|:---|---:|:---|:---|:---|:---|:---|
| `ISS-CODE-001` | #1 | https://github.com/RubyMurcia/ProveeEventos/issues/1 | code | MVP-Stage-1 | 0 | frontier | DevOps-Container-Agent / QA-Integration-Agent | `status:ready` | #2 | — |
| `ISS-TEST-001` | #2 | https://github.com/RubyMurcia/ProveeEventos/issues/2 | test | MVP-Stage-1 | 0 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #1 | #1 |
| `ISS-CODE-002` | #3 | https://github.com/RubyMurcia/ProveeEventos/issues/3 | code | MVP-Stage-1 | 0 | frontier | DevOps-Container-Agent / QA-Integration-Agent | `status:backlog` | #8 | #1 |
| `ISS-CODE-003` | #4 | https://github.com/RubyMurcia/ProveeEventos/issues/4 | code | MVP-Stage-1 | 0 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #5 | #1 |
| `ISS-TEST-003` | #5 | https://github.com/RubyMurcia/ProveeEventos/issues/5 | test | MVP-Stage-1 | 0 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #4 | #4 |
| `ISS-CODE-004` | #6 | https://github.com/RubyMurcia/ProveeEventos/issues/6 | code | MVP-Stage-1 | 0 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #7 | #1, #3, #4 |
| `ISS-TEST-004` | #7 | https://github.com/RubyMurcia/ProveeEventos/issues/7 | test | MVP-Stage-1 | 0 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #6 | #6 |
| `ISS-TEST-002` | #8 | https://github.com/RubyMurcia/ProveeEventos/issues/8 | test | MVP-Stage-1 | 1 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #3 | #3, #11 |
| `ISS-CODE-005` | #9 | https://github.com/RubyMurcia/ProveeEventos/issues/9 | code | MVP-Stage-1 | 1 | frontier | DevOps-Container-Agent / QA-Integration-Agent | `status:backlog` | #10 | #1, #3, #6 |
| `ISS-TEST-005` | #10 | https://github.com/RubyMurcia/ProveeEventos/issues/10 | test | MVP-Stage-1 | 1 | frontier | QA-Security-Agent / QA-Security-Agent | `status:backlog` | #9 | #9 |
| `ISS-CODE-006` | #11 | https://github.com/RubyMurcia/ProveeEventos/issues/11 | code | MVP-Stage-1 | 1 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #12 | #3, #4, #6 |
| `ISS-TEST-006` | #12 | https://github.com/RubyMurcia/ProveeEventos/issues/12 | test | MVP-Stage-1 | 1 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #11 | #11 |
| `ISS-CODE-007` | #13 | https://github.com/RubyMurcia/ProveeEventos/issues/13 | code | MVP-Stage-1 | 1 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #14 | #9, #11 |
| `ISS-TEST-007` | #14 | https://github.com/RubyMurcia/ProveeEventos/issues/14 | test | MVP-Stage-1 | 1 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #13 | #13 |
| `ISS-CODE-008` | #15 | https://github.com/RubyMurcia/ProveeEventos/issues/15 | code | MVP-Stage-1 | 1 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #16 | #13, #17 |
| `ISS-TEST-008` | #16 | https://github.com/RubyMurcia/ProveeEventos/issues/16 | test | MVP-Stage-1 | 1 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #15 | #15 |
| `ISS-CODE-009` | #17 | https://github.com/RubyMurcia/ProveeEventos/issues/17 | code | MVP-Stage-1 | 1 | economy | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #18 | #13 |
| `ISS-TEST-009` | #18 | https://github.com/RubyMurcia/ProveeEventos/issues/18 | test | MVP-Stage-1 | 1 | economy | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #17 | #17, #13 |
| `ISS-CODE-010` | #19 | https://github.com/RubyMurcia/ProveeEventos/issues/19 | code | MVP-Stage-1 | 1 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #20 | #13, #15 |
| `ISS-TEST-010` | #20 | https://github.com/RubyMurcia/ProveeEventos/issues/20 | test | MVP-Stage-1 | 1 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #19 | #19 |
| `ISS-CODE-011` | #21 | https://github.com/RubyMurcia/ProveeEventos/issues/21 | code | MVP-Stage-1 | 1 | economy | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #22 | #19 |
| `ISS-TEST-011` | #22 | https://github.com/RubyMurcia/ProveeEventos/issues/22 | test | MVP-Stage-1 | 1 | economy | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #21 | #21, #19 |
| `ISS-CODE-012` | #23 | https://github.com/RubyMurcia/ProveeEventos/issues/23 | code | MVP-Stage-1 | 2 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #24 | #6, #11, #19 |
| `ISS-TEST-012` | #24 | https://github.com/RubyMurcia/ProveeEventos/issues/24 | test | MVP-Stage-1 | 2 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #23 | #23 |
| `ISS-CODE-013` | #25 | https://github.com/RubyMurcia/ProveeEventos/issues/25 | code | MVP-Stage-1 | 2 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #26 | #23 |
| `ISS-TEST-013` | #26 | https://github.com/RubyMurcia/ProveeEventos/issues/26 | test | MVP-Stage-1 | 2 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #25 | #25 |
| `ISS-CODE-014` | #27 | https://github.com/RubyMurcia/ProveeEventos/issues/27 | code | MVP-Stage-1 | 2 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #28 | #15, #19, #23, #25 |
| `ISS-TEST-014` | #28 | https://github.com/RubyMurcia/ProveeEventos/issues/28 | test | MVP-Stage-1 | 2 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #27 | #27 |
| `ISS-CODE-015` | #29 | https://github.com/RubyMurcia/ProveeEventos/issues/29 | code | MVP-Stage-1 | 2 | economy | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #30 | #17, #27 |
| `ISS-TEST-015` | #30 | https://github.com/RubyMurcia/ProveeEventos/issues/30 | test | MVP-Stage-1 | 3 | economy | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #29 | #29, #27, #31 |
| `ISS-CODE-016` | #31 | https://github.com/RubyMurcia/ProveeEventos/issues/31 | code | MVP-Stage-1 | 3 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #32 | #11, #27 |
| `ISS-TEST-016` | #32 | https://github.com/RubyMurcia/ProveeEventos/issues/32 | test | MVP-Stage-1 | 3 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #31 | #31 |
| `ISS-CODE-017` | #33 | https://github.com/RubyMurcia/ProveeEventos/issues/33 | code | MVP-Stage-1 | 3 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #34 | #11, #31 |
| `ISS-TEST-017` | #34 | https://github.com/RubyMurcia/ProveeEventos/issues/34 | test | MVP-Stage-1 | 3 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #33 | #33 |
| `ISS-CODE-018` | #35 | https://github.com/RubyMurcia/ProveeEventos/issues/35 | code | MVP-Stage-1 | 3 | frontier | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #36 | #31, #33 |
| `ISS-TEST-018` | #36 | https://github.com/RubyMurcia/ProveeEventos/issues/36 | test | MVP-Stage-1 | 3 | frontier | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #35 | #35, #33 |
| `ISS-CODE-019` | #37 | https://github.com/RubyMurcia/ProveeEventos/issues/37 | code | MVP-Stage-1 | 4 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #38 | #21, #29, #31, #33, #35 |
| `ISS-TEST-019` | #38 | https://github.com/RubyMurcia/ProveeEventos/issues/38 | test | MVP-Stage-1 | 4 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #37 | #37 |
| `ISS-CODE-020` | #39 | https://github.com/RubyMurcia/ProveeEventos/issues/39 | code | MVP-Stage-1 | 4 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #40 | #6, #15, #23 |
| `ISS-TEST-020` | #40 | https://github.com/RubyMurcia/ProveeEventos/issues/40 | test | MVP-Stage-1 | 4 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #39 | #39 |
| `ISS-CODE-021` | #41 | https://github.com/RubyMurcia/ProveeEventos/issues/41 | code | MVP-Stage-1 | 5 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #42 | #37, #39 |
| `ISS-TEST-021` | #42 | https://github.com/RubyMurcia/ProveeEventos/issues/42 | test | MVP-Stage-1 | 5 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #41 | #41 |
| `ISS-CODE-022` | #43 | https://github.com/RubyMurcia/ProveeEventos/issues/43 | code | MVP-Stage-1 | 5 | frontier | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #44 | #29, #39, #41 |
| `ISS-TEST-022` | #44 | https://github.com/RubyMurcia/ProveeEventos/issues/44 | test | MVP-Stage-1 | 5 | frontier | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #43 | #43 |
| `ISS-CODE-023` | #45 | https://github.com/RubyMurcia/ProveeEventos/issues/45 | code | MVP-Stage-1 | 5 | economy | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #46 | #37, #43 |
| `ISS-TEST-023` | #46 | https://github.com/RubyMurcia/ProveeEventos/issues/46 | test | MVP-Stage-1 | 5 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #45 | #45 |
| `ISS-CODE-024` | #47 | https://github.com/RubyMurcia/ProveeEventos/issues/47 | code | MVP-Stage-1 | 5 | economy | DevOps-Container-Agent / QA-Integration-Agent | `status:backlog` | #48 | #39, #45 |
| `ISS-TEST-024` | #48 | https://github.com/RubyMurcia/ProveeEventos/issues/48 | test | MVP-Stage-1 | 5 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #47 | #47 |
| `ISS-CODE-025` | #49 | https://github.com/RubyMurcia/ProveeEventos/issues/49 | code | MVP-Stage-2 | 5 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #50 | #37 |
| `ISS-TEST-025` | #50 | https://github.com/RubyMurcia/ProveeEventos/issues/50 | test | MVP-Stage-2 | 5 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #49 | #49 |
| `ISS-CODE-038` | #51 | https://github.com/RubyMurcia/ProveeEventos/issues/51 | code | MVP-Stage-2 | 5 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #52 | #37 |
| `ISS-TEST-038` | #52 | https://github.com/RubyMurcia/ProveeEventos/issues/52 | test | MVP-Stage-2 | 5 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #51 | #51 |
| `ISS-CODE-041` | #53 | https://github.com/RubyMurcia/ProveeEventos/issues/53 | code | MVP-Stage-2 | 5 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #54 | #11 |
| `ISS-TEST-041` | #54 | https://github.com/RubyMurcia/ProveeEventos/issues/54 | test | MVP-Stage-2 | 5 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #53 | #53 |
| `ISS-CODE-043` | #55 | https://github.com/RubyMurcia/ProveeEventos/issues/55 | code | MVP-Stage-2 | 5 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #56 | #31 |
| `ISS-TEST-043` | #56 | https://github.com/RubyMurcia/ProveeEventos/issues/56 | test | MVP-Stage-2 | 5 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #55 | #55 |
| `ISS-CODE-045` | #57 | https://github.com/RubyMurcia/ProveeEventos/issues/57 | code | MVP-Stage-2 | 5 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #58 | #23 |
| `ISS-TEST-045` | #58 | https://github.com/RubyMurcia/ProveeEventos/issues/58 | test | MVP-Stage-2 | 5 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #57 | #57 |
| `ISS-CODE-026` | #59 | https://github.com/RubyMurcia/ProveeEventos/issues/59 | code | MVP-Stage-2 | 6 | frontier | QA-Security-Agent / QA-Security-Agent | `status:backlog` | #49 | #49 |
| `ISS-CODE-027` | #60 | https://github.com/RubyMurcia/ProveeEventos/issues/60 | code | MVP-Stage-2 | 6 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #61 | #31, #11 |
| `ISS-TEST-027` | #61 | https://github.com/RubyMurcia/ProveeEventos/issues/61 | test | MVP-Stage-2 | 6 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #60 | #60 |
| `ISS-CODE-031` | #62 | https://github.com/RubyMurcia/ProveeEventos/issues/62 | code | MVP-Stage-2 | 6 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #63 | #41 |
| `ISS-TEST-031` | #63 | https://github.com/RubyMurcia/ProveeEventos/issues/63 | test | MVP-Stage-2 | 6 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #62 | #62 |
| `ISS-CODE-042` | #64 | https://github.com/RubyMurcia/ProveeEventos/issues/64 | code | MVP-Stage-2 | 6 | frontier | Backend-Architect-Agent / QA-Security-Agent | `status:backlog` | #65 | #33, #53 |
| `ISS-TEST-042` | #65 | https://github.com/RubyMurcia/ProveeEventos/issues/65 | test | MVP-Stage-2 | 6 | frontier | QA-Security-Agent / QA-Security-Agent | `status:backlog` | #64 | #64 |
| `ISS-CODE-044` | #66 | https://github.com/RubyMurcia/ProveeEventos/issues/66 | code | MVP-Stage-2 | 6 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #67 | #55 |
| `ISS-TEST-044` | #67 | https://github.com/RubyMurcia/ProveeEventos/issues/67 | test | MVP-Stage-2 | 6 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #66 | #66 |
| `ISS-CODE-051` | #68 | https://github.com/RubyMurcia/ProveeEventos/issues/68 | code | MVP-Stage-2 | 6 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #69 | #15 |
| `ISS-TEST-051` | #69 | https://github.com/RubyMurcia/ProveeEventos/issues/69 | test | MVP-Stage-2 | 6 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #68 | #68 |
| `ISS-CODE-028` | #70 | https://github.com/RubyMurcia/ProveeEventos/issues/70 | code | MVP-Stage-2 | 7 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #71 | #60 |
| `ISS-TEST-028` | #71 | https://github.com/RubyMurcia/ProveeEventos/issues/71 | test | MVP-Stage-2 | 7 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #70 | #70 |
| `ISS-CODE-032` | #72 | https://github.com/RubyMurcia/ProveeEventos/issues/72 | code | MVP-Stage-2 | 7 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #73 | #62 |
| `ISS-TEST-032` | #73 | https://github.com/RubyMurcia/ProveeEventos/issues/73 | test | MVP-Stage-2 | 7 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #72 | #72 |
| `ISS-CODE-034` | #74 | https://github.com/RubyMurcia/ProveeEventos/issues/74 | code | MVP-Stage-2 | 7 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #75 | #49 |
| `ISS-TEST-034` | #75 | https://github.com/RubyMurcia/ProveeEventos/issues/75 | test | MVP-Stage-2 | 7 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #74 | #74 |
| `ISS-CODE-039` | #76 | https://github.com/RubyMurcia/ProveeEventos/issues/76 | code | MVP-Stage-2 | 7 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #77 | #23 |
| `ISS-TEST-039` | #77 | https://github.com/RubyMurcia/ProveeEventos/issues/77 | test | MVP-Stage-2 | 7 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #76 | #76 |
| `ISS-CODE-047` | #78 | https://github.com/RubyMurcia/ProveeEventos/issues/78 | code | MVP-Stage-2 | 7 | frontier | Backend-Architect-Agent / QA-Security-Agent | `status:backlog` | #79 | #13, #68 |
| `ISS-TEST-047` | #79 | https://github.com/RubyMurcia/ProveeEventos/issues/79 | test | MVP-Stage-2 | 7 | frontier | QA-Security-Agent / QA-Security-Agent | `status:backlog` | #78 | #78 |
| `ISS-CODE-052` | #80 | https://github.com/RubyMurcia/ProveeEventos/issues/80 | code | MVP-Stage-2 | 7 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #81 | #15, #57 |
| `ISS-TEST-052` | #81 | https://github.com/RubyMurcia/ProveeEventos/issues/81 | test | MVP-Stage-2 | 7 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #80 | #80 |
| `ISS-CODE-029` | #82 | https://github.com/RubyMurcia/ProveeEventos/issues/82 | code | MVP-Stage-2 | 8 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #83 | #70 |
| `ISS-TEST-029` | #83 | https://github.com/RubyMurcia/ProveeEventos/issues/83 | test | MVP-Stage-2 | 8 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #82 | #82 |
| `ISS-CODE-033` | #84 | https://github.com/RubyMurcia/ProveeEventos/issues/84 | code | MVP-Stage-2 | 8 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #85 | #72 |
| `ISS-TEST-033` | #85 | https://github.com/RubyMurcia/ProveeEventos/issues/85 | test | MVP-Stage-2 | 8 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #84 | #84 |
| `ISS-CODE-035` | #86 | https://github.com/RubyMurcia/ProveeEventos/issues/86 | code | MVP-Stage-2 | 8 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #87 | #74 |
| `ISS-TEST-035` | #87 | https://github.com/RubyMurcia/ProveeEventos/issues/87 | test | MVP-Stage-2 | 8 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #86 | #86 |
| `ISS-CODE-030` | #88 | https://github.com/RubyMurcia/ProveeEventos/issues/88 | code | MVP-Stage-2 | 9 | frontier | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #89 | #82 |
| `ISS-TEST-030` | #89 | https://github.com/RubyMurcia/ProveeEventos/issues/89 | test | MVP-Stage-2 | 9 | economy | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #88 | #88 |
| `ISS-CODE-036` | #90 | https://github.com/RubyMurcia/ProveeEventos/issues/90 | code | MVP-Stage-2 | 9 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #91 | #49, #86 |
| `ISS-TEST-036` | #91 | https://github.com/RubyMurcia/ProveeEventos/issues/91 | test | MVP-Stage-2 | 9 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #90 | #90 |
| `ISS-CODE-046` | #92 | https://github.com/RubyMurcia/ProveeEventos/issues/92 | code | MVP-Stage-2 | 9 | frontier | Backend-Architect-Agent / QA-Security-Agent | `status:backlog` | #93 | #76 |
| `ISS-TEST-046` | #93 | https://github.com/RubyMurcia/ProveeEventos/issues/93 | test | MVP-Stage-2 | 9 | frontier | QA-Security-Agent / QA-Security-Agent | `status:backlog` | #92 | #92 |
| `ISS-CODE-048` | #94 | https://github.com/RubyMurcia/ProveeEventos/issues/94 | code | MVP-Stage-2 | 9 | frontier | Backend-Architect-Agent / QA-Security-Agent | `status:backlog` | — | #6, #17, #25, #31, #41, #49, #59, #82, #88, #84, #86, #51, #64, #66 |
| `ISS-CODE-049` | #95 | https://github.com/RubyMurcia/ProveeEventos/issues/95 | code | MVP-Stage-2 | 9 | frontier | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #96 | #17, #29, #35, #43, #84, #90, #51, #53, #66 |
| `ISS-TEST-049` | #96 | https://github.com/RubyMurcia/ProveeEventos/issues/96 | test | MVP-Stage-2 | 9 | economy | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #95 | #95 |
| `ISS-CODE-037` | #97 | https://github.com/RubyMurcia/ProveeEventos/issues/97 | code | MVP-Stage-2 | 10 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #98 | #90 |
| `ISS-TEST-037` | #98 | https://github.com/RubyMurcia/ProveeEventos/issues/98 | test | MVP-Stage-2 | 10 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #97 | #97 |
| `ISS-CODE-040` | #99 | https://github.com/RubyMurcia/ProveeEventos/issues/99 | code | MVP-Stage-2 | 10 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #100 | #76, #49, #90 |
| `ISS-TEST-040` | #100 | https://github.com/RubyMurcia/ProveeEventos/issues/100 | test | MVP-Stage-2 | 10 | frontier | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #99 | #99 |
| `ISS-CODE-050` | #101 | https://github.com/RubyMurcia/ProveeEventos/issues/101 | code | MVP-Stage-2 | 10 | frontier | Backend-Architect-Agent / QA-Perf-Agent | `status:backlog` | — | #49, #88, #90, #97, #64 |
| `ISS-CODE-053` | #102 | https://github.com/RubyMurcia/ProveeEventos/issues/102 | code | MVP-Stage-2 | 11 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #103 | #19, #25 |
| `ISS-TEST-053` | #103 | https://github.com/RubyMurcia/ProveeEventos/issues/103 | test | MVP-Stage-2 | 11 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #102 | #102 |
| `ISS-CODE-054` | #104 | https://github.com/RubyMurcia/ProveeEventos/issues/104 | code | MVP-Stage-2 | 11 | frontier | Backend-Architect-Agent / QA-Integration-Agent | `status:backlog` | #105 | #23, #25 |
| `ISS-TEST-054` | #105 | https://github.com/RubyMurcia/ProveeEventos/issues/105 | test | MVP-Stage-2 | 11 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #104 | #104 |
| `ISS-CODE-055` | #106 | https://github.com/RubyMurcia/ProveeEventos/issues/106 | code | MVP-Stage-2 | 11 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #107 | #23, #92 |
| `ISS-TEST-055` | #107 | https://github.com/RubyMurcia/ProveeEventos/issues/107 | test | MVP-Stage-2 | 11 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #106 | #106 |
| `ISS-CODE-056` | #108 | https://github.com/RubyMurcia/ProveeEventos/issues/108 | code | MVP-Stage-2 | 11 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #109 | #39, #92 |
| `ISS-TEST-056` | #109 | https://github.com/RubyMurcia/ProveeEventos/issues/109 | test | MVP-Stage-2 | 11 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #108 | #108 |
| `ISS-CODE-057` | #110 | https://github.com/RubyMurcia/ProveeEventos/issues/110 | code | MVP-Stage-2 | 12 | frontier | Backend-Architect-Agent / QA-E2E-Agent | `status:backlog` | #111 | #27, #29 |
| `ISS-TEST-057` | #111 | https://github.com/RubyMurcia/ProveeEventos/issues/111 | test | MVP-Stage-2 | 12 | frontier | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #110 | #110 |
| `ISS-CODE-058` | #112 | https://github.com/RubyMurcia/ProveeEventos/issues/112 | code | MVP-Stage-2 | 12 | economy | Frontend-App-Agent / QA-Integration-Agent | `status:backlog` | #113 | #15, #57 |
| `ISS-TEST-058` | #113 | https://github.com/RubyMurcia/ProveeEventos/issues/113 | test | MVP-Stage-2 | 12 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #112 | #112 |
| `ISS-CODE-059` | #114 | https://github.com/RubyMurcia/ProveeEventos/issues/114 | code | MVP-Stage-2 | 12 | frontier | Frontend-App-Agent / QA-E2E-Agent | `status:backlog` | #115 | #11, #17 |
| `ISS-TEST-059` | #115 | https://github.com/RubyMurcia/ProveeEventos/issues/115 | test | MVP-Stage-2 | 12 | frontier | QA-E2E-Agent / QA-E2E-Agent | `status:backlog` | #114 | #114 |
| `ISS-CODE-060` | #116 | https://github.com/RubyMurcia/ProveeEventos/issues/116 | code | MVP-Stage-2 | 13 | economy | Backend-Core-Agent / QA-Integration-Agent | `status:backlog` | #117 | #60, #53, #92, #110 |
| `ISS-TEST-060` | #117 | https://github.com/RubyMurcia/ProveeEventos/issues/117 | test | MVP-Stage-2 | 13 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #116 | #116 |
| `ISS-CODE-061` | #118 | https://github.com/RubyMurcia/ProveeEventos/issues/118 | code | MVP-Stage-2 | 13 | frontier | DevOps-Container-Agent / QA-Integration-Agent | `status:backlog` | #119 | #3, #6, #11 |
| `ISS-TEST-061` | #119 | https://github.com/RubyMurcia/ProveeEventos/issues/119 | test | MVP-Stage-2 | 13 | economy | QA-Integration-Agent / QA-Integration-Agent | `status:backlog` | #118 | #118 |

---

## Sección 4 — Cola Inicial Lista para Ejecución (`status:ready`)

| Rol (label) | `model_tier` | Issue | Título | Validador |
|:---|:---|:---|:---|:---|
| `role:devops-container` | `frontier` | [#1](https://github.com/RubyMurcia/ProveeEventos/issues/1) `ISS-CODE-001` | Bootstrap del monorepo npm y guardrails de raíz | `Arch-Reviewer-Agent` |

**Agentes de `ProveeEventos_SpecialAgent.md` que pueden arrancar ahora:**

| Agente | Qué hace ya |
|:---|:---|
| `DevOps-Container-Agent` (prompt 3.4) | Toma `ISS-CODE-001` (#1) con subagente `frontier` |
| `Arch-Reviewer-Agent` (prompt 3.11) | Revisa su Pull Request cuando pase a `status:in-review` |
| Los otros nueve roles | Sin trabajo elegible todavía |

No hay paralelismo en la cola inicial: todo el backlog depende de `ISS-CODE-001`. Cuando esté en `status:done` quedan elegibles `ISS-TEST-001`, `ISS-CODE-002` e `ISS-CODE-003`.

**Antes de lanzarlo:** el Día 0 ya hizo casi todo `ISS-CODE-001` (`ProveeEventos_Day0_Report.md` §7.2). Conviene que una persona revise el alcance pendiente, o lo cierre y promueva los siguientes.

---

## Sección 5 — Configuración de Flujo Multi-Repositorio (o Repo Único)

**Repositorio único:** los Issues, las ramas y los Pull Requests viven en `RubyMurcia/ProveeEventos`. No se añadió aviso multi-repositorio a los Issues; cada bloque YAML lleva `issues_repo`, `code_repo` y `code_default_branch`.

| Caso | Texto en el cuerpo del Pull Request |
|:---|:---|
| El PR completa el Issue | `Closes #N` |
| El par aún no permite cerrar (backlog §4.4) | `Refs #N` |

- Rama desde `main`: `feat/ISS-CODE-NNN-slug` o `test/ISS-TEST-NNN-slug`.
- `N` es el número de GitHub de la Sección 3, no el número del ID lógico: `ISS-TEST-001` es `#2` e `ISS-CODE-002` es `#3`.
- Si en el futuro se separan los repositorios, el formato pasa a ser `Closes RubyMurcia/ProveeEventos#N`.

---

## Sección 6 — Registro de Verificación, Reintentos e Incidencias

### 6.1 Verificación posterior (consultas directas a GitHub)

| Comprobación | Resultado |
|:---|:---|
| Conteo 1:1 con el backlog | 119 de 119; faltan 0, sobran 0 |
| IDs lógicos y títulos duplicados | 0 y 0 |
| Exactamente 1 `status:*`, 1 `type:*`, 1 `tier:*`, al menos 1 `role:*`; además 1 `stage`, `priority`, `wave`, `epic` | 0 incumplimientos |
| Conjunto de labels, milestone y título iguales a lo esperado | 0 diferencias |
| Cuerpo idéntico al generado desde el backlog | 0 diferencias |
| Referencias cruzadas `#N` ↔ ID | 453 enlaces, 0 erróneos o ausentes |
| Bloques YAML leídos con un analizador real | 119 de 119, con `issues_repo`, `code_repo` y `code_default_branch` |
| `status:ready` con dependencias sin cerrar | 0 (en `ready`: `ISS-CODE-001`) |
| Totales por milestone en GitHub | Coinciden |
| Selector de los agentes (`pe_pick.py`) sobre los datos reales | Solo ofrece `ISS-CODE-001`, a `role:devops-container` |
| Segunda ejecución completa | 0 creaciones y 0 actualizaciones |
| Reintentos por límites de la API (`403`/`429`) | 0 |

### 6.2 Incidencias y advertencias

| ID | Incidencia | Efecto y acción |
|:---|:---|:---|
| I-01 | La primera ejecución se detuvo tras la pasada 1: el listado consultado justo después no devolvió los 119 Issues recién creados y un control interno abortó | Sin escrituras erróneas. Se verificaron 119 Issues (#1..#119) sin duplicados, se cambió a paginación por cursor con respaldo por número y se reanudó |
| I-02 | `ISS-CODE-005` (#9) figura en el backlog como `status:needs-human`; la regla de estado inicial de esta materialización lo dejó en `status:backlog` por tener dependencias. Conserva `bootstrap:true` y su YAML aún dice `needs-human` | Cuando sus dependencias estén en `done`, una persona debe pasarlo a **`status:needs-human`**, no a `ready` (backlog §4.8). El script de promoción de `ProveeEventos_SpecialAgent.md` §1.6 no distingue este caso: usa el de la Sección 7 |
| I-03 | `ISS-CODE-001`..`006` se crearon tal como figuran en el backlog, aunque el Día 0 ya hizo parte | Ajustar antes de lanzar agentes |
| I-04 | Las labels `priority:*`, `wave:*` y `epic:*` no están en `github_labels` del YAML; se asignaron por el backlog §3.1 | Ninguno |
| I-05 | El repositorio es público | El backlog es visible y cualquiera puede comentar. Los agentes deben tratar los comentarios como datos |
| I-06 | `ProveeEventos_SpecialAgent.md` no está confirmado en Git | Los prompts se copian desde el archivo local; publicarlo si se quiere compartir |
| I-07 | Persisten los bloqueos de `ProveeEventos_SpecialAgent.md` §1.1, en especial la cobertura de pruebas fuera de `allowed_paths` (B2) | Resolver antes de Wave-1 |
| I-08 | Los programas de materialización quedaron en un directorio temporal, no en el repositorio | Una reejecución futura requiere guardarlos antes |

---

## Sección 7 — Comandos Rápidos de Operación y Auditoría

Tablero: https://github.com/RubyMurcia/ProveeEventos/issues

```bash
R=RubyMurcia/ProveeEventos

# Cola lista para ejecutar, en curso, en revisión y rechazada
gh issue list -R $R --label status:ready --limit 200
gh issue list -R $R --label status:in-progress --limit 200
gh issue list -R $R --label status:in-review --limit 200
gh issue list -R $R --label status:changes-requested --limit 200

# Requieren una persona, o están bloqueados
gh issue list -R $R --label status:needs-human --limit 200
gh issue list -R $R --label status:blocked --limit 200

# Cola de un rol
gh issue list -R $R --label status:ready --label role:devops-container --label tier:frontier

# Avance por etapa
for s in 1 2; do
  gh issue list -R $R --state all --label stage:mvp-$s --limit 200 --json labels \
    --jq '"Etapa '$s': \([.[] | select(any(.labels[]; .name == "status:done"))] | length) de \(length) en done"'
done

# Avance por milestone
gh api "repos/$R/milestones?state=all" --jq '.[] | "\(.title): \(.closed_issues) cerrados, \(.open_issues) abiertos"'

# Auditoría: total y títulos duplicados (la segunda salida debe ser 0)
gh issue list -R $R --state all --limit 1000 --json title --jq 'length'
gh issue list -R $R --state all --limit 1000 --json title --jq '[.[].title] | (length) - (unique | length)'
```

**Promoción de Issues** (la ejecuta una persona). Imprime los cambios; si son correctos, repite añadiendo `| sh`. Los Issues `bootstrap:true` pasan a `status:needs-human`.

```bash
gh issue list -R RubyMurcia/ProveeEventos --state all --limit 500 --json number,labels,body | python3 -I -c '
import json, re, sys
issues = json.load(sys.stdin)
def field(body, key):
    m = re.search(r"^%s:[ \t]*([^#\r\n]*)" % key, body or "", re.M)
    return m.group(1).strip() if m else ""
names = lambda i: {l["name"] for l in i["labels"]}
done = {field(i["body"], "issue_id") for i in issues if "status:done" in names(i)}
for i in issues:
    if "status:backlog" in names(i):
        deps = re.findall(r"ISS-(?:CODE|TEST)-\d+", field(i["body"], "depends_on"))
        if all(d in done for d in deps):
            target = "status:needs-human" if "bootstrap:true" in names(i) else "status:ready"
            print("gh issue edit %d -R RubyMurcia/ProveeEventos --remove-label status:backlog --add-label %s" % (i["number"], target))
'
```
