-- ProveeEventos — anexo SQL complementario a proveeeventos.prisma (PostgreSQL 15 o superior).
-- Ensamblado desde Plans/Plan0005_work/sql/: no editar a mano. Fuente: ProveeEventos_TDD.md §10.2.
-- Cada migración empieza en una línea ">>> MIGRACIÓN". La reversión de cada bloque está comentada con el prefijo "--| ";
-- para revertir se ejecutan esas líneas, quitando el prefijo, en orden inverso de bloques.

-- =============================================================================
-- >>> MIGRACIÓN 00_extensiones_roles
-- Ejecutar una vez con el usuario administrador de la base, ANTES del SQL base de Prisma.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-001 | extensión citext | TDD §4.0 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "citext";
-- rollback SQL-001:
--| DROP EXTENSION IF EXISTS "citext";

-- -----------------------------------------------------------------------------
-- SQL-002 | extensión pg_trgm | TDD §4.0 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
-- rollback SQL-002:
--| DROP EXTENSION IF EXISTS "pg_trgm";

-- -----------------------------------------------------------------------------
-- SQL-003 | extensión unaccent | TDD §4.0 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "unaccent";
-- rollback SQL-003:
--| DROP EXTENSION IF EXISTS "unaccent";

-- -----------------------------------------------------------------------------
-- SQL-004 | extensión btree_gist | TDD §4.0 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "btree_gist";
-- rollback SQL-004:
--| DROP EXTENSION IF EXISTS "btree_gist";

-- -----------------------------------------------------------------------------
-- SQL-005 | roles de base de datos | TDD §7.2 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  r text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pe_owner') THEN
    CREATE ROLE pe_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  FOREACH r IN ARRAY ARRAY['pe_migrator', 'pe_api', 'pe_worker', 'pe_retention', 'pe_readonly'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS', r);
    END IF;
  END LOOP;
END
$$;
GRANT pe_owner TO pe_migrator;
-- Toda sesión de migración actúa como pe_owner: los objetos quedan a su nombre.
ALTER ROLE pe_migrator SET role = 'pe_owner';
-- Las contraseñas se asignan fuera de este archivo, desde el gestor de secretos.
-- rollback SQL-005:
--| DROP ROLE IF EXISTS pe_api;
--| DROP ROLE IF EXISTS pe_worker;
--| DROP ROLE IF EXISTS pe_retention;
--| DROP ROLE IF EXISTS pe_readonly;
--| DROP ROLE IF EXISTS pe_migrator;
--| DROP ROLE IF EXISTS pe_owner;

-- -----------------------------------------------------------------------------
-- SQL-006 | privilegios del esquema y privilegios por defecto | TDD §7.2 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO pe_api, pe_worker, pe_retention, pe_readonly;
GRANT USAGE, CREATE ON SCHEMA public TO pe_owner;
DO $$
BEGIN
  EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO pe_migrator, pe_api, pe_worker, pe_retention, pe_readonly', current_database());
  -- Prisma emite CREATE SCHEMA IF NOT EXISTS "public" en el SQL base, que exige CREATE sobre la base.
  EXECUTE format('GRANT CREATE ON DATABASE %I TO pe_owner', current_database());
END
$$;
ALTER DEFAULT PRIVILEGES FOR ROLE pe_owner IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pe_api, pe_worker;
ALTER DEFAULT PRIVILEGES FOR ROLE pe_owner IN SCHEMA public GRANT SELECT, UPDATE, DELETE ON TABLES TO pe_retention;
ALTER DEFAULT PRIVILEGES FOR ROLE pe_owner IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO pe_api, pe_worker;
-- rollback SQL-006:
--| ALTER DEFAULT PRIVILEGES FOR ROLE pe_owner IN SCHEMA public REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM pe_api, pe_worker;
--| ALTER DEFAULT PRIVILEGES FOR ROLE pe_owner IN SCHEMA public REVOKE SELECT, UPDATE, DELETE ON TABLES FROM pe_retention;
--| ALTER DEFAULT PRIVILEGES FOR ROLE pe_owner IN SCHEMA public REVOKE USAGE, SELECT ON SEQUENCES FROM pe_api, pe_worker;
--| DO $$ BEGIN EXECUTE format('REVOKE CREATE ON DATABASE %I FROM pe_owner', current_database()); EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM pe_migrator, pe_api, pe_worker, pe_retention, pe_readonly', current_database()); EXECUTE format('GRANT CONNECT, TEMPORARY ON DATABASE %I TO PUBLIC', current_database()); END $$;
--| REVOKE USAGE, CREATE ON SCHEMA public FROM pe_owner;
--| REVOKE USAGE ON SCHEMA public FROM pe_api, pe_worker, pe_retention, pe_readonly;
--| GRANT USAGE ON SCHEMA public TO PUBLIC;

-- -----------------------------------------------------------------------------
-- SQL-007 | tiempos límite por rol | TDD §5.1 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
ALTER ROLE pe_api SET statement_timeout = '5s';
ALTER ROLE pe_api SET lock_timeout = '2s';
ALTER ROLE pe_api SET idle_in_transaction_session_timeout = '10s';
ALTER ROLE pe_worker SET statement_timeout = '30s';
ALTER ROLE pe_worker SET lock_timeout = '5s';
ALTER ROLE pe_worker SET idle_in_transaction_session_timeout = '30s';
ALTER ROLE pe_retention SET statement_timeout = '30s';
ALTER ROLE pe_retention SET lock_timeout = '5s';
ALTER ROLE pe_retention SET idle_in_transaction_session_timeout = '30s';
ALTER ROLE pe_migrator SET statement_timeout = '0';
ALTER ROLE pe_migrator SET lock_timeout = '2s';
ALTER ROLE pe_migrator SET idle_in_transaction_session_timeout = '60s';
ALTER ROLE pe_readonly SET statement_timeout = '30s';
ALTER ROLE pe_readonly SET lock_timeout = '2s';
ALTER ROLE pe_readonly SET idle_in_transaction_session_timeout = '30s';
-- rollback SQL-007:
--| ALTER ROLE pe_api RESET statement_timeout;
--| ALTER ROLE pe_api RESET lock_timeout;
--| ALTER ROLE pe_api RESET idle_in_transaction_session_timeout;
--| ALTER ROLE pe_worker RESET statement_timeout;
--| ALTER ROLE pe_worker RESET lock_timeout;
--| ALTER ROLE pe_worker RESET idle_in_transaction_session_timeout;
--| ALTER ROLE pe_retention RESET statement_timeout;
--| ALTER ROLE pe_retention RESET lock_timeout;
--| ALTER ROLE pe_retention RESET idle_in_transaction_session_timeout;
--| ALTER ROLE pe_migrator RESET statement_timeout;
--| ALTER ROLE pe_migrator RESET lock_timeout;
--| ALTER ROLE pe_migrator RESET idle_in_transaction_session_timeout;
--| ALTER ROLE pe_readonly RESET statement_timeout;
--| ALTER ROLE pe_readonly RESET lock_timeout;
--| ALTER ROLE pe_readonly RESET idle_in_transaction_session_timeout;

-- -----------------------------------------------------------------------------
-- SQL-008 | función fn_reject_mutation | TDD §5.3 | migración 00_extensiones_roles
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_reject_mutation() RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_mode text := TG_ARGV[0];
  v_cols text[] := TG_ARGV[1 : TG_NARGS - 1];
  v_col text;
BEGIN
  -- Solo el rol de retención puede eliminar o seudonimizar historial; en modo estricto, nadie.
  IF v_mode <> 'estricto' AND pg_has_role(current_user, 'pe_retention', 'MEMBER') THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    END IF;
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND v_mode = 'proteger' THEN
    FOREACH v_col IN ARRAY v_cols LOOP
      IF (to_jsonb(OLD) -> v_col) IS DISTINCT FROM (to_jsonb(NEW) -> v_col) THEN
        RAISE EXCEPTION 'columna inmutable: %.%', TG_TABLE_NAME, v_col USING ERRCODE = 'restrict_violation', CONSTRAINT = TG_NAME;
      END IF;
    END LOOP;
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND v_mode = 'permitir' AND (to_jsonb(OLD) - v_cols) IS NOT DISTINCT FROM (to_jsonb(NEW) - v_cols) THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'operación % no permitida en %', TG_OP, TG_TABLE_NAME USING ERRCODE = 'restrict_violation', CONSTRAINT = TG_NAME;
END
$$;
ALTER FUNCTION fn_reject_mutation() OWNER TO pe_owner;
-- rollback SQL-008:
--| DROP FUNCTION IF EXISTS fn_reject_mutation();

-- =============================================================================
-- >>> MIGRACIÓN 01_fundaciones
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-020 | ck_users__suspension | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "ck_users__suspension";
ALTER TABLE "users" ADD CONSTRAINT "ck_users__suspension" CHECK (status <> 'SUSPENDIDO' OR suspended_at IS NOT NULL);
-- rollback SQL-020:
--| ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "ck_users__suspension";

-- -----------------------------------------------------------------------------
-- SQL-021 | ck_consent_records__sujeto | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "consent_records" DROP CONSTRAINT IF EXISTS "ck_consent_records__sujeto";
ALTER TABLE "consent_records" ADD CONSTRAINT "ck_consent_records__sujeto" CHECK (subject_type = 'USUARIO' OR subject_id IS NOT NULL);
-- rollback SQL-021:
--| ALTER TABLE "consent_records" DROP CONSTRAINT IF EXISTS "ck_consent_records__sujeto";

-- -----------------------------------------------------------------------------
-- SQL-360 | ck_audit_logs__cambios | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "audit_logs" DROP CONSTRAINT IF EXISTS "ck_audit_logs__cambios";
ALTER TABLE "audit_logs" ADD CONSTRAINT "ck_audit_logs__cambios" CHECK (changes IS NULL OR jsonb_typeof(changes) = 'object');
-- rollback SQL-360:
--| ALTER TABLE "audit_logs" DROP CONSTRAINT IF EXISTS "ck_audit_logs__cambios";

-- -----------------------------------------------------------------------------
-- SQL-361 | ck_data_subject_requests__prorroga | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "data_subject_requests" DROP CONSTRAINT IF EXISTS "ck_data_subject_requests__prorroga";
ALTER TABLE "data_subject_requests" ADD CONSTRAINT "ck_data_subject_requests__prorroga" CHECK (extended_due_date IS NULL OR (extended_due_date > due_date AND extension_reason IS NOT NULL));
-- rollback SQL-361:
--| ALTER TABLE "data_subject_requests" DROP CONSTRAINT IF EXISTS "ck_data_subject_requests__prorroga";

-- -----------------------------------------------------------------------------
-- SQL-362 | ck_legal_holds__liberacion | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "legal_holds" DROP CONSTRAINT IF EXISTS "ck_legal_holds__liberacion";
ALTER TABLE "legal_holds" ADD CONSTRAINT "ck_legal_holds__liberacion" CHECK ((released_at IS NULL) = (released_by_user_id IS NULL));
-- rollback SQL-362:
--| ALTER TABLE "legal_holds" DROP CONSTRAINT IF EXISTS "ck_legal_holds__liberacion";

-- -----------------------------------------------------------------------------
-- SQL-363 | ck_retention_executions__filas | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "retention_executions" DROP CONSTRAINT IF EXISTS "ck_retention_executions__filas";
ALTER TABLE "retention_executions" ADD CONSTRAINT "ck_retention_executions__filas" CHECK (affected_rows >= 0);
-- rollback SQL-363:
--| ALTER TABLE "retention_executions" DROP CONSTRAINT IF EXISTS "ck_retention_executions__filas";

-- -----------------------------------------------------------------------------
-- SQL-390 | ck_outbox_events__payload | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "outbox_events" DROP CONSTRAINT IF EXISTS "ck_outbox_events__payload";
ALTER TABLE "outbox_events" ADD CONSTRAINT "ck_outbox_events__payload" CHECK (jsonb_typeof(payload) = 'object' AND octet_length(payload::text) <= 32768);
-- rollback SQL-390:
--| ALTER TABLE "outbox_events" DROP CONSTRAINT IF EXISTS "ck_outbox_events__payload";

-- -----------------------------------------------------------------------------
-- SQL-391 | ck_outbox_events__intentos | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "outbox_events" DROP CONSTRAINT IF EXISTS "ck_outbox_events__intentos";
ALTER TABLE "outbox_events" ADD CONSTRAINT "ck_outbox_events__intentos" CHECK (attempts >= 0 AND event_version >= 1);
-- rollback SQL-391:
--| ALTER TABLE "outbox_events" DROP CONSTRAINT IF EXISTS "ck_outbox_events__intentos";

-- -----------------------------------------------------------------------------
-- SQL-392 | ck_idempotency_keys__principal | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "idempotency_keys" DROP CONSTRAINT IF EXISTS "ck_idempotency_keys__principal";
ALTER TABLE "idempotency_keys" ADD CONSTRAINT "ck_idempotency_keys__principal" CHECK (principal_type IN ('USER', 'MAGIC_LINK', 'ANONYMOUS_AUTH') AND octet_length(request_hash) = 32);
-- rollback SQL-392:
--| ALTER TABLE "idempotency_keys" DROP CONSTRAINT IF EXISTS "ck_idempotency_keys__principal";

-- -----------------------------------------------------------------------------
-- SQL-393 | ck_idempotency_keys__respuesta | TDD §4.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "idempotency_keys" DROP CONSTRAINT IF EXISTS "ck_idempotency_keys__respuesta";
ALTER TABLE "idempotency_keys" ADD CONSTRAINT "ck_idempotency_keys__respuesta" CHECK (jsonb_typeof(response_body) = 'object' OR jsonb_typeof(response_body) = 'array' OR response_body IS NULL);
-- rollback SQL-393:
--| ALTER TABLE "idempotency_keys" DROP CONSTRAINT IF EXISTS "ck_idempotency_keys__respuesta";

-- -----------------------------------------------------------------------------
-- SQL-420 | trg_user_global_roles__sin_borrado | TDD §4.3 y §5.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_user_global_roles__sin_borrado"
  BEFORE DELETE ON "user_global_roles"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('sin_borrado');
-- rollback SQL-420:
--| DROP TRIGGER IF EXISTS "trg_user_global_roles__sin_borrado" ON "user_global_roles";

-- -----------------------------------------------------------------------------
-- SQL-421 | trg_consent_records__inmutable | TDD §4.3 y §5.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_consent_records__inmutable"
  BEFORE UPDATE OR DELETE ON "consent_records"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-421:
--| DROP TRIGGER IF EXISTS "trg_consent_records__inmutable" ON "consent_records";

-- -----------------------------------------------------------------------------
-- SQL-434 | trg_audit_logs__inmutable | TDD §4.3 y §5.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_audit_logs__inmutable"
  BEFORE UPDATE OR DELETE ON "audit_logs"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-434:
--| DROP TRIGGER IF EXISTS "trg_audit_logs__inmutable" ON "audit_logs";

-- -----------------------------------------------------------------------------
-- SQL-436 | trg_legal_holds__sin_borrado | TDD §4.3 y §5.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_legal_holds__sin_borrado"
  BEFORE DELETE ON "legal_holds"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('sin_borrado');
-- rollback SQL-436:
--| DROP TRIGGER IF EXISTS "trg_legal_holds__sin_borrado" ON "legal_holds";

-- -----------------------------------------------------------------------------
-- SQL-437 | trg_retention_executions__inmutable | TDD §4.3 y §5.3 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_retention_executions__inmutable"
  BEFORE UPDATE OR DELETE ON "retention_executions"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('estricto');
-- rollback SQL-437:
--| DROP TRIGGER IF EXISTS "trg_retention_executions__inmutable" ON "retention_executions";

-- -----------------------------------------------------------------------------
-- SQL-441 | privilegios de las tablas de la migración 01 | TDD §7.2 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "outbox_events" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "outbox_events" TO pe_retention;
REVOKE DELETE ON "outbox_events" FROM pe_api;
GRANT USAGE, SELECT ON SEQUENCE "outbox_events_position_seq" TO pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "processed_events" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "processed_events" TO pe_retention;
REVOKE UPDATE ON "processed_events" FROM pe_api, pe_worker;
REVOKE DELETE ON "processed_events" FROM pe_api;
GRANT SELECT, INSERT, UPDATE, DELETE ON "idempotency_keys" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "idempotency_keys" TO pe_retention;
REVOKE DELETE ON "idempotency_keys" FROM pe_api;
GRANT SELECT, INSERT, UPDATE, DELETE ON "users" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "users" TO pe_retention;
REVOKE DELETE ON "users" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "user_global_roles" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "user_global_roles" TO pe_retention;
REVOKE DELETE ON "user_global_roles" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "consent_records" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "consent_records" TO pe_retention;
REVOKE UPDATE ON "consent_records" FROM pe_api, pe_worker;
REVOKE DELETE ON "consent_records" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "audit_logs" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "audit_logs" TO pe_retention;
REVOKE UPDATE ON "audit_logs" FROM pe_api, pe_worker;
REVOKE DELETE ON "audit_logs" FROM pe_api, pe_worker;
GRANT INSERT ON "audit_logs" TO pe_retention;
GRANT SELECT, INSERT, UPDATE, DELETE ON "data_subject_requests" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "data_subject_requests" TO pe_retention;
REVOKE DELETE ON "data_subject_requests" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "legal_holds" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "legal_holds" TO pe_retention;
REVOKE DELETE ON "legal_holds" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "holidays" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "holidays" TO pe_retention;
GRANT SELECT, INSERT, UPDATE, DELETE ON "retention_executions" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "retention_executions" TO pe_retention;
REVOKE UPDATE ON "retention_executions" FROM pe_api, pe_worker;
REVOKE DELETE ON "retention_executions" FROM pe_api, pe_worker;
GRANT INSERT ON "retention_executions" TO pe_retention;
REVOKE UPDATE, DELETE ON "retention_executions" FROM pe_retention;
DO $$
BEGIN
  IF to_regclass('public._prisma_migrations') IS NOT NULL THEN
    REVOKE ALL ON "_prisma_migrations" FROM pe_api, pe_worker, pe_retention, pe_readonly;
  END IF;
END
$$;
-- rollback SQL-441:
--| REVOKE ALL ON SEQUENCE "outbox_events_position_seq" FROM pe_api, pe_worker;
--| REVOKE ALL ON "outbox_events" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "processed_events" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "idempotency_keys" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "users" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "user_global_roles" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "consent_records" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "audit_logs" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "data_subject_requests" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "legal_holds" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "holidays" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "retention_executions" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-461 | lectura analítica sin columnas personales, migración 01 | TDD §7.1 y §7.2 | migración 01_fundaciones
-- -----------------------------------------------------------------------------
GRANT SELECT ON "outbox_events" TO pe_readonly;
GRANT SELECT ON "processed_events" TO pe_readonly;
REVOKE SELECT ON "idempotency_keys" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "principal_type", "principal_id", "operation", "idempotency_key", "request_hash", "status", "response_status", "resource_id", "expires_at", "created_at", "updated_at") ON "idempotency_keys" TO pe_readonly;
REVOKE SELECT ON "users" FROM pe_readonly;
GRANT SELECT ("id", "status", "email_verified_at", "suspended_at", "suspension_reason", "anonymized_at", "created_at", "updated_at") ON "users" TO pe_readonly;
GRANT SELECT ON "user_global_roles" TO pe_readonly;
REVOKE SELECT ON "consent_records" FROM pe_readonly;
GRANT SELECT ("id", "subject_type", "consent_type", "notice_version", "accepted_at", "created_at") ON "consent_records" TO pe_readonly;
REVOKE SELECT ON "audit_logs" FROM pe_readonly;
GRANT SELECT ("id", "occurred_at", "actor_role", "organization_id", "action", "resource_type", "resource_id", "result", "correlation_id", "created_at") ON "audit_logs" TO pe_readonly;
REVOKE SELECT ON "data_subject_requests" FROM pe_readonly;
GRANT SELECT ("id", "requester_user_id", "type", "status", "responsible_user_id", "due_date", "extended_due_date", "extension_reason", "extension_notified_at", "resolved_at", "created_at", "updated_at") ON "data_subject_requests" TO pe_readonly;
REVOKE SELECT ON "legal_holds" FROM pe_readonly;
GRANT SELECT ("id", "resource_type", "resource_id", "set_by_user_id", "set_at", "released_at", "released_by_user_id", "created_at", "updated_at") ON "legal_holds" TO pe_readonly;
GRANT SELECT ON "holidays" TO pe_readonly;
GRANT SELECT ON "retention_executions" TO pe_readonly;
-- rollback SQL-461:
--| REVOKE SELECT ON "outbox_events" FROM pe_readonly;
--| REVOKE SELECT ON "processed_events" FROM pe_readonly;
--| REVOKE SELECT ON "idempotency_keys" FROM pe_readonly;
--| REVOKE SELECT ON "users" FROM pe_readonly;
--| REVOKE SELECT ON "user_global_roles" FROM pe_readonly;
--| REVOKE SELECT ON "consent_records" FROM pe_readonly;
--| REVOKE SELECT ON "audit_logs" FROM pe_readonly;
--| REVOKE SELECT ON "data_subject_requests" FROM pe_readonly;
--| REVOKE SELECT ON "legal_holds" FROM pe_readonly;
--| REVOKE SELECT ON "holidays" FROM pe_readonly;
--| REVOKE SELECT ON "retention_executions" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 02_organizaciones
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-030 | ck_organizations__suspension | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "organizations" DROP CONSTRAINT IF EXISTS "ck_organizations__suspension";
ALTER TABLE "organizations" ADD CONSTRAINT "ck_organizations__suspension" CHECK (status <> 'SUSPENDIDO' OR suspended_at IS NOT NULL);
-- rollback SQL-030:
--| ALTER TABLE "organizations" DROP CONSTRAINT IF EXISTS "ck_organizations__suspension";

-- -----------------------------------------------------------------------------
-- SQL-031 | ck_memberships__usuario | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "memberships" DROP CONSTRAINT IF EXISTS "ck_memberships__usuario";
ALTER TABLE "memberships" ADD CONSTRAINT "ck_memberships__usuario" CHECK (status = 'INVITADO' OR user_id IS NOT NULL);
-- rollback SQL-031:
--| ALTER TABLE "memberships" DROP CONSTRAINT IF EXISTS "ck_memberships__usuario";

-- -----------------------------------------------------------------------------
-- SQL-032 | ck_invitations__token | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "invitations" DROP CONSTRAINT IF EXISTS "ck_invitations__token";
ALTER TABLE "invitations" ADD CONSTRAINT "ck_invitations__token" CHECK (octet_length(token_hash) = 32 AND octet_length(token_nonce) = 32);
-- rollback SQL-032:
--| ALTER TABLE "invitations" DROP CONSTRAINT IF EXISTS "ck_invitations__token";

-- -----------------------------------------------------------------------------
-- SQL-033 | ck_ownership_transfers__partes | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "ownership_transfers" DROP CONSTRAINT IF EXISTS "ck_ownership_transfers__partes";
ALTER TABLE "ownership_transfers" ADD CONSTRAINT "ck_ownership_transfers__partes" CHECK (from_membership_id <> to_membership_id);
-- rollback SQL-033:
--| ALTER TABLE "ownership_transfers" DROP CONSTRAINT IF EXISTS "ck_ownership_transfers__partes";

-- -----------------------------------------------------------------------------
-- SQL-034 | ck_plans__limites | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "plans" DROP CONSTRAINT IF EXISTS "ck_plans__limites";
ALTER TABLE "plans" ADD CONSTRAINT "ck_plans__limites" CHECK ((max_active_events IS NULL OR max_active_events >= 0) AND (max_monthly_quotations IS NULL OR max_monthly_quotations >= 0) AND (max_coordinators IS NULL OR max_coordinators >= 0) AND (max_custom_templates IS NULL OR max_custom_templates >= 0));
-- rollback SQL-034:
--| ALTER TABLE "plans" DROP CONSTRAINT IF EXISTS "ck_plans__limites";

-- -----------------------------------------------------------------------------
-- SQL-035 | ck_plans__precio | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "plans" DROP CONSTRAINT IF EXISTS "ck_plans__precio";
ALTER TABLE "plans" ADD CONSTRAINT "ck_plans__precio" CHECK (monthly_price >= 0 AND currency = 'COP');
-- rollback SQL-035:
--| ALTER TABLE "plans" DROP CONSTRAINT IF EXISTS "ck_plans__precio";

-- -----------------------------------------------------------------------------
-- SQL-036 | ck_plans__vigencia | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "plans" DROP CONSTRAINT IF EXISTS "ck_plans__vigencia";
ALTER TABLE "plans" ADD CONSTRAINT "ck_plans__vigencia" CHECK (valid_until IS NULL OR valid_until >= valid_from);
-- rollback SQL-036:
--| ALTER TABLE "plans" DROP CONSTRAINT IF EXISTS "ck_plans__vigencia";

-- -----------------------------------------------------------------------------
-- SQL-037 | ck_organization_plans__periodo | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "organization_plans" DROP CONSTRAINT IF EXISTS "ck_organization_plans__periodo";
ALTER TABLE "organization_plans" ADD CONSTRAINT "ck_organization_plans__periodo" CHECK (valid_until IS NULL OR valid_until > valid_from);
-- rollback SQL-037:
--| ALTER TABLE "organization_plans" DROP CONSTRAINT IF EXISTS "ck_organization_plans__periodo";

-- -----------------------------------------------------------------------------
-- SQL-038 | ex_organization_plans__sin_solape | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "organization_plans" DROP CONSTRAINT IF EXISTS "ex_organization_plans__sin_solape";
ALTER TABLE "organization_plans" ADD CONSTRAINT "ex_organization_plans__sin_solape" EXCLUDE USING gist (organization_id WITH =, tstzrange(valid_from, valid_until, '[)') WITH &&);
-- rollback SQL-038:
--| ALTER TABLE "organization_plans" DROP CONSTRAINT IF EXISTS "ex_organization_plans__sin_solape";

-- -----------------------------------------------------------------------------
-- SQL-039 | ck_plan_usage_counters__consumo | TDD §4.3 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "plan_usage_counters" DROP CONSTRAINT IF EXISTS "ck_plan_usage_counters__consumo";
ALTER TABLE "plan_usage_counters" ADD CONSTRAINT "ck_plan_usage_counters__consumo" CHECK (used >= 0);
-- rollback SQL-039:
--| ALTER TABLE "plan_usage_counters" DROP CONSTRAINT IF EXISTS "ck_plan_usage_counters__consumo";

-- -----------------------------------------------------------------------------
-- SQL-442 | privilegios de las tablas de la migración 02 | TDD §7.2 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "organizations" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "organizations" TO pe_retention;
REVOKE DELETE ON "organizations" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "memberships" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "memberships" TO pe_retention;
REVOKE DELETE ON "memberships" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "invitations" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "invitations" TO pe_retention;
REVOKE DELETE ON "invitations" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "ownership_transfers" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "ownership_transfers" TO pe_retention;
REVOKE DELETE ON "ownership_transfers" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "plans" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "plans" TO pe_retention;
REVOKE DELETE ON "plans" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "organization_plans" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "organization_plans" TO pe_retention;
REVOKE DELETE ON "organization_plans" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "plan_usage_counters" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "plan_usage_counters" TO pe_retention;
REVOKE DELETE ON "plan_usage_counters" FROM pe_api, pe_worker;
-- rollback SQL-442:
--| REVOKE ALL ON "organizations" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "memberships" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "invitations" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "ownership_transfers" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "plans" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "organization_plans" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "plan_usage_counters" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-462 | lectura analítica sin columnas personales, migración 02 | TDD §7.1 y §7.2 | migración 02_organizaciones
-- -----------------------------------------------------------------------------
REVOKE SELECT ON "organizations" FROM pe_readonly;
GRANT SELECT ("id", "trade_name", "city", "status", "suspended_at", "suspension_reason", "registered_by_user_id", "created_at", "updated_at") ON "organizations" TO pe_readonly;
REVOKE SELECT ON "memberships" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "user_id", "role", "status", "invited_at", "accepted_at", "suspended_at", "removed_at", "created_at", "updated_at") ON "memberships" TO pe_readonly;
REVOKE SELECT ON "invitations" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "membership_id", "role", "secret_key_version", "status", "expires_at", "accepted_at", "revoked_at", "invited_by_user_id", "created_at", "updated_at") ON "invitations" TO pe_readonly;
GRANT SELECT ON "ownership_transfers" TO pe_readonly;
GRANT SELECT ON "plans" TO pe_readonly;
GRANT SELECT ON "organization_plans" TO pe_readonly;
GRANT SELECT ON "plan_usage_counters" TO pe_readonly;
-- rollback SQL-462:
--| REVOKE SELECT ON "organizations" FROM pe_readonly;
--| REVOKE SELECT ON "memberships" FROM pe_readonly;
--| REVOKE SELECT ON "invitations" FROM pe_readonly;
--| REVOKE SELECT ON "ownership_transfers" FROM pe_readonly;
--| REVOKE SELECT ON "plans" FROM pe_readonly;
--| REVOKE SELECT ON "organization_plans" FROM pe_readonly;
--| REVOKE SELECT ON "plan_usage_counters" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 03_taxonomia
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-060 | ck_event_templates__alcance | TDD §4.3 | migración 03_taxonomia
-- -----------------------------------------------------------------------------
ALTER TABLE "event_templates" DROP CONSTRAINT IF EXISTS "ck_event_templates__alcance";
ALTER TABLE "event_templates" ADD CONSTRAINT "ck_event_templates__alcance" CHECK ((scope = 'GLOBAL') = (organization_id IS NULL));
-- rollback SQL-060:
--| ALTER TABLE "event_templates" DROP CONSTRAINT IF EXISTS "ck_event_templates__alcance";

-- -----------------------------------------------------------------------------
-- SQL-061 | ck_whatsapp_templates__alcance | TDD §4.3 | migración 03_taxonomia
-- -----------------------------------------------------------------------------
ALTER TABLE "whatsapp_templates" DROP CONSTRAINT IF EXISTS "ck_whatsapp_templates__alcance";
ALTER TABLE "whatsapp_templates" ADD CONSTRAINT "ck_whatsapp_templates__alcance" CHECK ((scope = 'GLOBAL') = (organization_id IS NULL));
-- rollback SQL-061:
--| ALTER TABLE "whatsapp_templates" DROP CONSTRAINT IF EXISTS "ck_whatsapp_templates__alcance";

-- -----------------------------------------------------------------------------
-- SQL-443 | privilegios de las tablas de la migración 03 | TDD §7.2 | migración 03_taxonomia
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "categories" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "categories" TO pe_retention;
REVOKE DELETE ON "categories" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "subtypes" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "subtypes" TO pe_retention;
REVOKE DELETE ON "subtypes" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "event_templates" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "event_templates" TO pe_retention;
REVOKE DELETE ON "event_templates" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "event_template_selections" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "event_template_selections" TO pe_retention;
REVOKE UPDATE ON "event_template_selections" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "whatsapp_templates" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "whatsapp_templates" TO pe_retention;
REVOKE DELETE ON "whatsapp_templates" FROM pe_api, pe_worker;
-- rollback SQL-443:
--| REVOKE ALL ON "categories" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "subtypes" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "event_templates" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "event_template_selections" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "whatsapp_templates" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-463 | lectura analítica sin columnas personales, migración 03 | TDD §7.1 y §7.2 | migración 03_taxonomia
-- -----------------------------------------------------------------------------
GRANT SELECT ON "categories" TO pe_readonly;
GRANT SELECT ON "subtypes" TO pe_readonly;
GRANT SELECT ON "event_templates" TO pe_readonly;
GRANT SELECT ON "event_template_selections" TO pe_readonly;
GRANT SELECT ON "whatsapp_templates" TO pe_readonly;
-- rollback SQL-463:
--| REVOKE SELECT ON "categories" FROM pe_readonly;
--| REVOKE SELECT ON "subtypes" FROM pe_readonly;
--| REVOKE SELECT ON "event_templates" FROM pe_readonly;
--| REVOKE SELECT ON "event_template_selections" FROM pe_readonly;
--| REVOKE SELECT ON "whatsapp_templates" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 04_comunicaciones
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-330 | ck_message_templates__asunto | TDD §4.3 | migración 04_comunicaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "message_templates" DROP CONSTRAINT IF EXISTS "ck_message_templates__asunto";
ALTER TABLE "message_templates" ADD CONSTRAINT "ck_message_templates__asunto" CHECK (channel <> 'EMAIL' OR subject IS NOT NULL);
-- rollback SQL-330:
--| ALTER TABLE "message_templates" DROP CONSTRAINT IF EXISTS "ck_message_templates__asunto";

-- -----------------------------------------------------------------------------
-- SQL-331 | ck_notifications__destinatario | TDD §4.3 | migración 04_comunicaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "notifications" DROP CONSTRAINT IF EXISTS "ck_notifications__destinatario";
ALTER TABLE "notifications" ADD CONSTRAINT "ck_notifications__destinatario" CHECK ((channel = 'IN_APP' AND user_id IS NOT NULL) OR (channel = 'EMAIL' AND (recipient_email IS NOT NULL OR anonymized_at IS NOT NULL)));
-- rollback SQL-331:
--| ALTER TABLE "notifications" DROP CONSTRAINT IF EXISTS "ck_notifications__destinatario";

-- -----------------------------------------------------------------------------
-- SQL-332 | ck_delivery_attempts__intento | TDD §4.3 | migración 04_comunicaciones
-- -----------------------------------------------------------------------------
ALTER TABLE "delivery_attempts" DROP CONSTRAINT IF EXISTS "ck_delivery_attempts__intento";
ALTER TABLE "delivery_attempts" ADD CONSTRAINT "ck_delivery_attempts__intento" CHECK (attempt_number >= 1);
-- rollback SQL-332:
--| ALTER TABLE "delivery_attempts" DROP CONSTRAINT IF EXISTS "ck_delivery_attempts__intento";

-- -----------------------------------------------------------------------------
-- SQL-444 | privilegios de las tablas de la migración 04 | TDD §7.2 | migración 04_comunicaciones
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "message_templates" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "message_templates" TO pe_retention;
REVOKE DELETE ON "message_templates" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "notifications" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "notifications" TO pe_retention;
REVOKE DELETE ON "notifications" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "notification_preferences" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "notification_preferences" TO pe_retention;
GRANT SELECT, INSERT, UPDATE, DELETE ON "delivery_attempts" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "delivery_attempts" TO pe_retention;
REVOKE DELETE ON "delivery_attempts" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "email_webhook_events" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "email_webhook_events" TO pe_retention;
REVOKE DELETE ON "email_webhook_events" FROM pe_api;
-- rollback SQL-444:
--| REVOKE ALL ON "message_templates" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "notifications" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "notification_preferences" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "delivery_attempts" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "email_webhook_events" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-464 | lectura analítica sin columnas personales, migración 04 | TDD §7.1 y §7.2 | migración 04_comunicaciones
-- -----------------------------------------------------------------------------
GRANT SELECT ON "message_templates" TO pe_readonly;
REVOKE SELECT ON "notifications" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "user_id", "channel", "category", "type", "template_id", "action_resource_type", "action_resource_id", "read_at", "dispatch_status", "source_event_id", "dedupe_key", "anonymized_at", "created_at", "updated_at") ON "notifications" TO pe_readonly;
GRANT SELECT ON "notification_preferences" TO pe_readonly;
REVOKE SELECT ON "delivery_attempts" FROM pe_readonly;
GRANT SELECT ("id", "notification_id", "attempt_number", "status", "error_code", "attempted_at", "status_updated_at", "created_at", "updated_at") ON "delivery_attempts" TO pe_readonly;
GRANT SELECT ON "email_webhook_events" TO pe_readonly;
-- rollback SQL-464:
--| REVOKE SELECT ON "message_templates" FROM pe_readonly;
--| REVOKE SELECT ON "notifications" FROM pe_readonly;
--| REVOKE SELECT ON "notification_preferences" FROM pe_readonly;
--| REVOKE SELECT ON "delivery_attempts" FROM pe_readonly;
--| REVOKE SELECT ON "email_webhook_events" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 05_catalogo
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-080 | ck_providers__nivel | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "providers" DROP CONSTRAINT IF EXISTS "ck_providers__nivel";
ALTER TABLE "providers" ADD CONSTRAINT "ck_providers__nivel" CHECK (verification_level IS NULL OR verification_level BETWEEN 1 AND 3);
-- rollback SQL-080:
--| ALTER TABLE "providers" DROP CONSTRAINT IF EXISTS "ck_providers__nivel";

-- -----------------------------------------------------------------------------
-- SQL-081 | ck_providers__capacidad | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "providers" DROP CONSTRAINT IF EXISTS "ck_providers__capacidad";
ALTER TABLE "providers" ADD CONSTRAINT "ck_providers__capacidad" CHECK (max_guest_capacity IS NULL OR max_guest_capacity > 0);
-- rollback SQL-081:
--| ALTER TABLE "providers" DROP CONSTRAINT IF EXISTS "ck_providers__capacidad";

-- -----------------------------------------------------------------------------
-- SQL-082 | ck_providers__suspension | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "providers" DROP CONSTRAINT IF EXISTS "ck_providers__suspension";
ALTER TABLE "providers" ADD CONSTRAINT "ck_providers__suspension" CHECK (account_status <> 'SUSPENDIDO' OR suspended_at IS NOT NULL);
-- rollback SQL-082:
--| ALTER TABLE "providers" DROP CONSTRAINT IF EXISTS "ck_providers__suspension";

-- -----------------------------------------------------------------------------
-- SQL-083 | ck_provider_categories__posicion | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_categories" DROP CONSTRAINT IF EXISTS "ck_provider_categories__posicion";
ALTER TABLE "provider_categories" ADD CONSTRAINT "ck_provider_categories__posicion" CHECK (position BETWEEN 1 AND 5);
-- rollback SQL-083:
--| ALTER TABLE "provider_categories" DROP CONSTRAINT IF EXISTS "ck_provider_categories__posicion";

-- -----------------------------------------------------------------------------
-- SQL-084 | ck_provider_coverage_areas__coordenadas | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_coverage_areas" DROP CONSTRAINT IF EXISTS "ck_provider_coverage_areas__coordenadas";
ALTER TABLE "provider_coverage_areas" ADD CONSTRAINT "ck_provider_coverage_areas__coordenadas" CHECK ((latitude IS NULL) = (longitude IS NULL));
-- rollback SQL-084:
--| ALTER TABLE "provider_coverage_areas" DROP CONSTRAINT IF EXISTS "ck_provider_coverage_areas__coordenadas";

-- -----------------------------------------------------------------------------
-- SQL-085 | ck_portfolio_assets__tamano | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "portfolio_assets" DROP CONSTRAINT IF EXISTS "ck_portfolio_assets__tamano";
ALTER TABLE "portfolio_assets" ADD CONSTRAINT "ck_portfolio_assets__tamano" CHECK (size_bytes > 0);
-- rollback SQL-085:
--| ALTER TABLE "portfolio_assets" DROP CONSTRAINT IF EXISTS "ck_portfolio_assets__tamano";

-- -----------------------------------------------------------------------------
-- SQL-086 | ck_service_packages__precios | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__precios";
ALTER TABLE "service_packages" ADD CONSTRAINT "ck_service_packages__precios" CHECK (base_price >= 0 AND (price_per_person IS NULL OR price_per_person >= 0) AND currency = 'COP');
-- rollback SQL-086:
--| ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__precios";

-- -----------------------------------------------------------------------------
-- SQL-087 | ck_service_packages__impuestos | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__impuestos";
ALTER TABLE "service_packages" ADD CONSTRAINT "ck_service_packages__impuestos" CHECK ((tax_rate IS NULL OR tax_rate BETWEEN 0 AND 1) AND (tax_valid_until IS NULL OR tax_valid_until >= tax_valid_from));
-- rollback SQL-087:
--| ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__impuestos";

-- -----------------------------------------------------------------------------
-- SQL-088 | ck_service_packages__capacidad | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__capacidad";
ALTER TABLE "service_packages" ADD CONSTRAINT "ck_service_packages__capacidad" CHECK ((package_capacity IS NULL OR package_capacity > 0) AND (NOT independent_inventory OR package_capacity IS NOT NULL));
-- rollback SQL-088:
--| ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__capacidad";

-- -----------------------------------------------------------------------------
-- SQL-089 | ck_provider_verification_submissions__evidencia | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_verification_submissions" DROP CONSTRAINT IF EXISTS "ck_provider_verification_submissions__evidencia";
ALTER TABLE "provider_verification_submissions" ADD CONSTRAINT "ck_provider_verification_submissions__evidencia" CHECK (jsonb_typeof(evidence) = 'array');
-- rollback SQL-089:
--| ALTER TABLE "provider_verification_submissions" DROP CONSTRAINT IF EXISTS "ck_provider_verification_submissions__evidencia";

-- -----------------------------------------------------------------------------
-- SQL-090 | ck_provider_verification_decisions__motivo | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_verification_decisions" DROP CONSTRAINT IF EXISTS "ck_provider_verification_decisions__motivo";
ALTER TABLE "provider_verification_decisions" ADD CONSTRAINT "ck_provider_verification_decisions__motivo" CHECK (to_status <> 'RECHAZADO' OR reason IS NOT NULL);
-- rollback SQL-090:
--| ALTER TABLE "provider_verification_decisions" DROP CONSTRAINT IF EXISTS "ck_provider_verification_decisions__motivo";

-- -----------------------------------------------------------------------------
-- SQL-091 | ck_ranking_configurations__pesos | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "ranking_configurations" DROP CONSTRAINT IF EXISTS "ck_ranking_configurations__pesos";
ALTER TABLE "ranking_configurations" ADD CONSTRAINT "ck_ranking_configurations__pesos" CHECK (jsonb_typeof(weights) = 'object');
-- rollback SQL-091:
--| ALTER TABLE "ranking_configurations" DROP CONSTRAINT IF EXISTS "ck_ranking_configurations__pesos";

-- -----------------------------------------------------------------------------
-- SQL-092 | ck_provider_search__puntajes | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_search" DROP CONSTRAINT IF EXISTS "ck_provider_search__puntajes";
ALTER TABLE "provider_search" ADD CONSTRAINT "ck_provider_search__puntajes" CHECK (quality_score BETWEEN 0 AND 1 AND price_position_score BETWEEN 0 AND 1 AND completeness_score BETWEEN 0 AND 1);
-- rollback SQL-092:
--| ALTER TABLE "provider_search" DROP CONSTRAINT IF EXISTS "ck_provider_search__puntajes";

-- -----------------------------------------------------------------------------
-- SQL-093 | ck_provider_reputation__conteos | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_reputation" DROP CONSTRAINT IF EXISTS "ck_provider_reputation__conteos";
ALTER TABLE "provider_reputation" ADD CONSTRAINT "ck_provider_reputation__conteos" CHECK (review_count >= 0 AND (review_count = 0) = (rating_average IS NULL));
-- rollback SQL-093:
--| ALTER TABLE "provider_reputation" DROP CONSTRAINT IF EXISTS "ck_provider_reputation__conteos";

-- -----------------------------------------------------------------------------
-- SQL-094 | ck_provider_search__importes | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_search" DROP CONSTRAINT IF EXISTS "ck_provider_search__importes";
ALTER TABLE "provider_search" ADD CONSTRAINT "ck_provider_search__importes" CHECK (price_from >= 0 AND (price_per_person IS NULL OR price_per_person >= 0) AND currency = 'COP');
-- rollback SQL-094:
--| ALTER TABLE "provider_search" DROP CONSTRAINT IF EXISTS "ck_provider_search__importes";

-- -----------------------------------------------------------------------------
-- SQL-095 | ck_service_packages__listas | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__listas";
ALTER TABLE "service_packages" ADD CONSTRAINT "ck_service_packages__listas" CHECK (inclusions IS NOT NULL AND exclusions IS NOT NULL);
-- rollback SQL-095:
--| ALTER TABLE "service_packages" DROP CONSTRAINT IF EXISTS "ck_service_packages__listas";

-- -----------------------------------------------------------------------------
-- SQL-096 | ck_provider_search__cobertura | TDD §4.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_search" DROP CONSTRAINT IF EXISTS "ck_provider_search__cobertura";
ALTER TABLE "provider_search" ADD CONSTRAINT "ck_provider_search__cobertura" CHECK (coverage_keys IS NOT NULL);
-- rollback SQL-096:
--| ALTER TABLE "provider_search" DROP CONSTRAINT IF EXISTS "ck_provider_search__cobertura";

-- -----------------------------------------------------------------------------
-- SQL-422 | trg_provider_verification_submissions__inmutable | TDD §4.3 y §5.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_provider_verification_submissions__inmutable"
  BEFORE UPDATE OR DELETE ON "provider_verification_submissions"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-422:
--| DROP TRIGGER IF EXISTS "trg_provider_verification_submissions__inmutable" ON "provider_verification_submissions";

-- -----------------------------------------------------------------------------
-- SQL-423 | trg_provider_verification_decisions__inmutable | TDD §4.3 y §5.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_provider_verification_decisions__inmutable"
  BEFORE UPDATE OR DELETE ON "provider_verification_decisions"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-423:
--| DROP TRIGGER IF EXISTS "trg_provider_verification_decisions__inmutable" ON "provider_verification_decisions";

-- -----------------------------------------------------------------------------
-- SQL-424 | trg_provider_verification_evidence__inmutable | TDD §4.3 y §5.3 | migración 05_catalogo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_provider_verification_evidence__inmutable"
  BEFORE UPDATE OR DELETE ON "provider_verification_evidence"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-424:
--| DROP TRIGGER IF EXISTS "trg_provider_verification_evidence__inmutable" ON "provider_verification_evidence";

-- -----------------------------------------------------------------------------
-- SQL-445 | privilegios de las tablas de la migración 05 | TDD §7.2 | migración 05_catalogo
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "providers" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "providers" TO pe_retention;
REVOKE DELETE ON "providers" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_categories" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_categories" TO pe_retention;
REVOKE UPDATE ON "provider_categories" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_subtypes" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_subtypes" TO pe_retention;
REVOKE UPDATE ON "provider_subtypes" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_coverage_areas" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_coverage_areas" TO pe_retention;
REVOKE UPDATE ON "provider_coverage_areas" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "portfolio_assets" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "portfolio_assets" TO pe_retention;
REVOKE DELETE ON "portfolio_assets" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "service_packages" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "service_packages" TO pe_retention;
REVOKE DELETE ON "service_packages" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_verification_submissions" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_verification_submissions" TO pe_retention;
REVOKE UPDATE ON "provider_verification_submissions" FROM pe_api, pe_worker;
REVOKE DELETE ON "provider_verification_submissions" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_verification_decisions" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_verification_decisions" TO pe_retention;
REVOKE UPDATE ON "provider_verification_decisions" FROM pe_api, pe_worker;
REVOKE DELETE ON "provider_verification_decisions" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_verification_evidence" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_verification_evidence" TO pe_retention;
REVOKE UPDATE ON "provider_verification_evidence" FROM pe_api, pe_worker;
REVOKE DELETE ON "provider_verification_evidence" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "ranking_configurations" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "ranking_configurations" TO pe_retention;
REVOKE DELETE ON "ranking_configurations" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_search" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_search" TO pe_retention;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_reputation" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_reputation" TO pe_retention;
-- rollback SQL-445:
--| REVOKE ALL ON "providers" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_categories" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_subtypes" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_coverage_areas" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "portfolio_assets" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "service_packages" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_verification_submissions" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_verification_decisions" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_verification_evidence" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "ranking_configurations" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_search" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_reputation" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-465 | lectura analítica sin columnas personales, migración 05 | TDD §7.1 y §7.2 | migración 05_catalogo
-- -----------------------------------------------------------------------------
REVOKE SELECT ON "providers" FROM pe_readonly;
GRANT SELECT ("id", "user_id", "provider_type", "description", "city", "preferred_channel", "max_guest_capacity", "verification_status", "verification_level", "account_status", "suspended_at", "suspension_reason", "submitted_for_review_at", "version", "created_at", "updated_at") ON "providers" TO pe_readonly;
GRANT SELECT ON "provider_categories" TO pe_readonly;
GRANT SELECT ON "provider_subtypes" TO pe_readonly;
GRANT SELECT ON "provider_coverage_areas" TO pe_readonly;
GRANT SELECT ON "portfolio_assets" TO pe_readonly;
GRANT SELECT ON "service_packages" TO pe_readonly;
REVOKE SELECT ON "provider_verification_submissions" FROM pe_readonly;
GRANT SELECT ("id", "provider_id", "submitted_by_user_id", "submitted_at", "created_at") ON "provider_verification_submissions" TO pe_readonly;
GRANT SELECT ON "provider_verification_decisions" TO pe_readonly;
GRANT SELECT ON "provider_verification_evidence" TO pe_readonly;
GRANT SELECT ON "ranking_configurations" TO pe_readonly;
GRANT SELECT ON "provider_search" TO pe_readonly;
GRANT SELECT ON "provider_reputation" TO pe_readonly;
-- rollback SQL-465:
--| REVOKE SELECT ON "providers" FROM pe_readonly;
--| REVOKE SELECT ON "provider_categories" FROM pe_readonly;
--| REVOKE SELECT ON "provider_subtypes" FROM pe_readonly;
--| REVOKE SELECT ON "provider_coverage_areas" FROM pe_readonly;
--| REVOKE SELECT ON "portfolio_assets" FROM pe_readonly;
--| REVOKE SELECT ON "service_packages" FROM pe_readonly;
--| REVOKE SELECT ON "provider_verification_submissions" FROM pe_readonly;
--| REVOKE SELECT ON "provider_verification_decisions" FROM pe_readonly;
--| REVOKE SELECT ON "provider_verification_evidence" FROM pe_readonly;
--| REVOKE SELECT ON "ranking_configurations" FROM pe_readonly;
--| REVOKE SELECT ON "provider_search" FROM pe_readonly;
--| REVOKE SELECT ON "provider_reputation" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 06_eventos
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-130 | ck_events__intervalo | TDD §4.3 | migración 06_eventos
-- -----------------------------------------------------------------------------
ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__intervalo";
ALTER TABLE "events" ADD CONSTRAINT "ck_events__intervalo" CHECK (ends_at_utc > starts_at_utc AND local_ends_at > local_starts_at);
-- rollback SQL-130:
--| ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__intervalo";

-- -----------------------------------------------------------------------------
-- SQL-131 | ck_events__invitados | TDD §4.3 | migración 06_eventos
-- -----------------------------------------------------------------------------
ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__invitados";
ALTER TABLE "events" ADD CONSTRAINT "ck_events__invitados" CHECK (guests > 0);
-- rollback SQL-131:
--| ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__invitados";

-- -----------------------------------------------------------------------------
-- SQL-132 | ck_events__presupuesto | TDD §4.3 | migración 06_eventos
-- -----------------------------------------------------------------------------
ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__presupuesto";
ALTER TABLE "events" ADD CONSTRAINT "ck_events__presupuesto" CHECK ((estimated_budget IS NULL OR estimated_budget >= 0) AND currency = 'COP');
-- rollback SQL-132:
--| ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__presupuesto";

-- -----------------------------------------------------------------------------
-- SQL-133 | ck_events__coordenadas | TDD §4.3 | migración 06_eventos
-- -----------------------------------------------------------------------------
ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__coordenadas";
ALTER TABLE "events" ADD CONSTRAINT "ck_events__coordenadas" CHECK ((latitude IS NULL) = (longitude IS NULL));
-- rollback SQL-133:
--| ALTER TABLE "events" DROP CONSTRAINT IF EXISTS "ck_events__coordenadas";

-- -----------------------------------------------------------------------------
-- SQL-446 | privilegios de las tablas de la migración 06 | TDD §7.2 | migración 06_eventos
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "events" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "events" TO pe_retention;
REVOKE DELETE ON "events" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "event_categories" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "event_categories" TO pe_retention;
REVOKE UPDATE ON "event_categories" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "event_assignments" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "event_assignments" TO pe_retention;
REVOKE DELETE ON "event_assignments" FROM pe_api, pe_worker;
-- rollback SQL-446:
--| REVOKE ALL ON "events" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "event_categories" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "event_assignments" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-466 | lectura analítica sin columnas personales, migración 06 | TDD §7.1 y §7.2 | migración 06_eventos
-- -----------------------------------------------------------------------------
REVOKE SELECT ON "events" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "coordinator_membership_id", "template_id", "name", "local_starts_at", "local_ends_at", "time_zone", "starts_at_utc", "ends_at_utc", "event_date", "guests", "location_city", "estimated_budget", "currency", "status", "archived_at", "archive_warning_sent_at", "last_activity_at", "cancelled_at", "cancellation_reason", "cloned_from_event_id", "created_by_user_id", "version", "created_at", "updated_at") ON "events" TO pe_readonly;
GRANT SELECT ON "event_categories" TO pe_readonly;
GRANT SELECT ON "event_assignments" TO pe_readonly;
-- rollback SQL-466:
--| REVOKE SELECT ON "events" FROM pe_readonly;
--| REVOKE SELECT ON "event_categories" FROM pe_readonly;
--| REVOKE SELECT ON "event_assignments" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 07_cotizacion
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-250 | ck_quotations__importes | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotations" DROP CONSTRAINT IF EXISTS "ck_quotations__importes";
ALTER TABLE "quotations" ADD CONSTRAINT "ck_quotations__importes" CHECK (subtotal >= 0 AND total_estimated >= 0 AND (commission_amount IS NULL OR commission_amount >= 0) AND currency = 'COP');
-- rollback SQL-250:
--| ALTER TABLE "quotations" DROP CONSTRAINT IF EXISTS "ck_quotations__importes";

-- -----------------------------------------------------------------------------
-- SQL-251 | ck_quotations__version_snapshot | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotations" DROP CONSTRAINT IF EXISTS "ck_quotations__version_snapshot";
ALTER TABLE "quotations" ADD CONSTRAINT "ck_quotations__version_snapshot" CHECK (snapshot_version >= 0);
-- rollback SQL-251:
--| ALTER TABLE "quotations" DROP CONSTRAINT IF EXISTS "ck_quotations__version_snapshot";

-- -----------------------------------------------------------------------------
-- SQL-252 | ck_quotation_items__seleccion | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_items" DROP CONSTRAINT IF EXISTS "ck_quotation_items__seleccion";
ALTER TABLE "quotation_items" ADD CONSTRAINT "ck_quotation_items__seleccion" CHECK ((selected_package_id IS NULL) = (selected_provider_id IS NULL));
-- rollback SQL-252:
--| ALTER TABLE "quotation_items" DROP CONSTRAINT IF EXISTS "ck_quotation_items__seleccion";

-- -----------------------------------------------------------------------------
-- SQL-253 | ck_quotation_items__importes | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_items" DROP CONSTRAINT IF EXISTS "ck_quotation_items__importes";
ALTER TABLE "quotation_items" ADD CONSTRAINT "ck_quotation_items__importes" CHECK ((unit_price IS NULL OR unit_price >= 0) AND (estimated_total IS NULL OR estimated_total >= 0) AND currency = 'COP');
-- rollback SQL-253:
--| ALTER TABLE "quotation_items" DROP CONSTRAINT IF EXISTS "ck_quotation_items__importes";

-- -----------------------------------------------------------------------------
-- SQL-254 | ck_quotation_item_options__posicion | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__posicion";
ALTER TABLE "quotation_item_options" ADD CONSTRAINT "ck_quotation_item_options__posicion" CHECK (rank BETWEEN 1 AND 20);
-- rollback SQL-254:
--| ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__posicion";

-- -----------------------------------------------------------------------------
-- SQL-255 | ck_quotation_item_options__importes | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__importes";
ALTER TABLE "quotation_item_options" ADD CONSTRAINT "ck_quotation_item_options__importes" CHECK (unit_price >= 0 AND total_estimated >= 0 AND currency = 'COP');
-- rollback SQL-255:
--| ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__importes";

-- -----------------------------------------------------------------------------
-- SQL-256 | ck_quotation_item_options__componentes | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__componentes";
ALTER TABLE "quotation_item_options" ADD CONSTRAINT "ck_quotation_item_options__componentes" CHECK (jsonb_typeof(ranking_components) = 'object');
-- rollback SQL-256:
--| ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__componentes";

-- -----------------------------------------------------------------------------
-- SQL-257 | ck_quotation_versions__formato | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_versions" DROP CONSTRAINT IF EXISTS "ck_quotation_versions__formato";
ALTER TABLE "quotation_versions" ADD CONSTRAINT "ck_quotation_versions__formato" CHECK (version_number >= 1 AND schema_version >= 1 AND jsonb_typeof(snapshot) = 'object');
-- rollback SQL-257:
--| ALTER TABLE "quotation_versions" DROP CONSTRAINT IF EXISTS "ck_quotation_versions__formato";

-- -----------------------------------------------------------------------------
-- SQL-258 | ck_quick_quotations__datos | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quick_quotations" DROP CONSTRAINT IF EXISTS "ck_quick_quotations__datos";
ALTER TABLE "quick_quotations" ADD CONSTRAINT "ck_quick_quotations__datos" CHECK (guests > 0 AND (max_budget IS NULL OR max_budget >= 0) AND currency = 'COP');
-- rollback SQL-258:
--| ALTER TABLE "quick_quotations" DROP CONSTRAINT IF EXISTS "ck_quick_quotations__datos";

-- -----------------------------------------------------------------------------
-- SQL-259 | ck_quick_quotation_options__datos | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quick_quotation_options" DROP CONSTRAINT IF EXISTS "ck_quick_quotation_options__datos";
ALTER TABLE "quick_quotation_options" ADD CONSTRAINT "ck_quick_quotation_options__datos" CHECK (rank BETWEEN 1 AND 20 AND total_price >= 0 AND currency = 'COP');
-- rollback SQL-259:
--| ALTER TABLE "quick_quotation_options" DROP CONSTRAINT IF EXISTS "ck_quick_quotation_options__datos";

-- -----------------------------------------------------------------------------
-- SQL-260 | ck_quotation_versions__importes | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_versions" DROP CONSTRAINT IF EXISTS "ck_quotation_versions__importes";
ALTER TABLE "quotation_versions" ADD CONSTRAINT "ck_quotation_versions__importes" CHECK (subtotal >= 0 AND total_estimated >= 0 AND (commission_amount IS NULL OR commission_amount >= 0) AND currency = 'COP');
-- rollback SQL-260:
--| ALTER TABLE "quotation_versions" DROP CONSTRAINT IF EXISTS "ck_quotation_versions__importes";

-- -----------------------------------------------------------------------------
-- SQL-261 | ck_quick_quotation_options__componentes | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quick_quotation_options" DROP CONSTRAINT IF EXISTS "ck_quick_quotation_options__componentes";
ALTER TABLE "quick_quotation_options" ADD CONSTRAINT "ck_quick_quotation_options__componentes" CHECK (jsonb_typeof(ranking_components) = 'object');
-- rollback SQL-261:
--| ALTER TABLE "quick_quotation_options" DROP CONSTRAINT IF EXISTS "ck_quick_quotation_options__componentes";

-- -----------------------------------------------------------------------------
-- SQL-262 | ck_quotation_item_options__listas | TDD §4.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__listas";
ALTER TABLE "quotation_item_options" ADD CONSTRAINT "ck_quotation_item_options__listas" CHECK (inclusions IS NOT NULL AND exclusions IS NOT NULL);
-- rollback SQL-262:
--| ALTER TABLE "quotation_item_options" DROP CONSTRAINT IF EXISTS "ck_quotation_item_options__listas";

-- -----------------------------------------------------------------------------
-- SQL-431 | trg_quotation_item_tracking_history__inmutable | TDD §4.3 y §5.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_quotation_item_tracking_history__inmutable"
  BEFORE UPDATE OR DELETE ON "quotation_item_tracking_history"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-431:
--| DROP TRIGGER IF EXISTS "trg_quotation_item_tracking_history__inmutable" ON "quotation_item_tracking_history";

-- -----------------------------------------------------------------------------
-- SQL-432 | trg_quotation_versions__inmutable | TDD §4.3 y §5.3 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_quotation_versions__inmutable"
  BEFORE UPDATE OR DELETE ON "quotation_versions"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-432:
--| DROP TRIGGER IF EXISTS "trg_quotation_versions__inmutable" ON "quotation_versions";

-- -----------------------------------------------------------------------------
-- SQL-447 | privilegios de las tablas de la migración 07 | TDD §7.2 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "quotations" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quotations" TO pe_retention;
REVOKE DELETE ON "quotations" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quotation_items" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quotation_items" TO pe_retention;
REVOKE DELETE ON "quotation_items" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quotation_item_subtypes" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quotation_item_subtypes" TO pe_retention;
REVOKE UPDATE ON "quotation_item_subtypes" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quotation_item_options" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quotation_item_options" TO pe_retention;
REVOKE UPDATE ON "quotation_item_options" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quotation_item_tracking_history" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quotation_item_tracking_history" TO pe_retention;
REVOKE UPDATE ON "quotation_item_tracking_history" FROM pe_api, pe_worker;
REVOKE DELETE ON "quotation_item_tracking_history" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quotation_versions" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quotation_versions" TO pe_retention;
REVOKE UPDATE ON "quotation_versions" FROM pe_api, pe_worker;
REVOKE DELETE ON "quotation_versions" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quotation_documents" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quotation_documents" TO pe_retention;
REVOKE DELETE ON "quotation_documents" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quick_quotations" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quick_quotations" TO pe_retention;
REVOKE DELETE ON "quick_quotations" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "quick_quotation_options" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "quick_quotation_options" TO pe_retention;
REVOKE UPDATE ON "quick_quotation_options" FROM pe_api, pe_worker;
REVOKE DELETE ON "quick_quotation_options" FROM pe_api, pe_worker;
-- rollback SQL-447:
--| REVOKE ALL ON "quotations" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quotation_items" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quotation_item_subtypes" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quotation_item_options" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quotation_item_tracking_history" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quotation_versions" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quotation_documents" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quick_quotations" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "quick_quotation_options" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-467 | lectura analítica sin columnas personales, migración 07 | TDD §7.1 y §7.2 | migración 07_cotizacion
-- -----------------------------------------------------------------------------
GRANT SELECT ON "quotations" TO pe_readonly;
GRANT SELECT ON "quotation_items" TO pe_readonly;
GRANT SELECT ON "quotation_item_subtypes" TO pe_readonly;
GRANT SELECT ON "quotation_item_options" TO pe_readonly;
GRANT SELECT ON "quotation_item_tracking_history" TO pe_readonly;
REVOKE SELECT ON "quotation_versions" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "quotation_id", "version_number", "trigger", "schema_version", "subtotal", "commission_amount", "total_estimated", "currency", "created_by_user_id", "created_at") ON "quotation_versions" TO pe_readonly;
GRANT SELECT ON "quotation_documents" TO pe_readonly;
REVOKE SELECT ON "quick_quotations" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "created_by_user_id", "category_id", "subtype_id", "event_date", "guests", "location_city", "max_budget", "currency", "favorite", "favorited_at", "created_at", "updated_at") ON "quick_quotations" TO pe_readonly;
GRANT SELECT ON "quick_quotation_options" TO pe_readonly;
-- rollback SQL-467:
--| REVOKE SELECT ON "quotations" FROM pe_readonly;
--| REVOKE SELECT ON "quotation_items" FROM pe_readonly;
--| REVOKE SELECT ON "quotation_item_subtypes" FROM pe_readonly;
--| REVOKE SELECT ON "quotation_item_options" FROM pe_readonly;
--| REVOKE SELECT ON "quotation_item_tracking_history" FROM pe_readonly;
--| REVOKE SELECT ON "quotation_versions" FROM pe_readonly;
--| REVOKE SELECT ON "quotation_documents" FROM pe_readonly;
--| REVOKE SELECT ON "quick_quotations" FROM pe_readonly;
--| REVOKE SELECT ON "quick_quotation_options" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 08_contratacion
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-150 | ck_provider_daily_capacity__cupo | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "provider_daily_capacity" DROP CONSTRAINT IF EXISTS "ck_provider_daily_capacity__cupo";
ALTER TABLE "provider_daily_capacity" ADD CONSTRAINT "ck_provider_daily_capacity__cupo" CHECK (capacity >= 0 AND consumed >= 0 AND consumed <= capacity);
-- rollback SQL-150:
--| ALTER TABLE "provider_daily_capacity" DROP CONSTRAINT IF EXISTS "ck_provider_daily_capacity__cupo";

-- -----------------------------------------------------------------------------
-- SQL-151 | ck_package_daily_capacity__cupo | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "package_daily_capacity" DROP CONSTRAINT IF EXISTS "ck_package_daily_capacity__cupo";
ALTER TABLE "package_daily_capacity" ADD CONSTRAINT "ck_package_daily_capacity__cupo" CHECK (capacity >= 0 AND consumed >= 0 AND consumed <= capacity);
-- rollback SQL-151:
--| ALTER TABLE "package_daily_capacity" DROP CONSTRAINT IF EXISTS "ck_package_daily_capacity__cupo";

-- -----------------------------------------------------------------------------
-- SQL-152 | ck_bookings__cantidad | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__cantidad";
ALTER TABLE "bookings" ADD CONSTRAINT "ck_bookings__cantidad" CHECK (quantity >= 1);
-- rollback SQL-152:
--| ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__cantidad";

-- -----------------------------------------------------------------------------
-- SQL-153 | ck_bookings__intervalo | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__intervalo";
ALTER TABLE "bookings" ADD CONSTRAINT "ck_bookings__intervalo" CHECK (service_ends_at > service_starts_at);
-- rollback SQL-153:
--| ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__intervalo";

-- -----------------------------------------------------------------------------
-- SQL-154 | ck_bookings__precio | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__precio";
ALTER TABLE "bookings" ADD CONSTRAINT "ck_bookings__precio" CHECK (accepted_price >= 0 AND currency = 'COP');
-- rollback SQL-154:
--| ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__precio";

-- -----------------------------------------------------------------------------
-- SQL-155 | ck_bookings__revision | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__revision";
ALTER TABLE "bookings" ADD CONSTRAINT "ck_bookings__revision" CHECK (status <> 'CANCELACION_EN_REVISION' OR review_origin IS NOT NULL);
-- rollback SQL-155:
--| ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__revision";

-- -----------------------------------------------------------------------------
-- SQL-156 | ck_bookings__decision | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__decision";
ALTER TABLE "bookings" ADD CONSTRAINT "ck_bookings__decision" CHECK (organizer_review_decision IS NULL OR review_origin = 'PLATAFORMA');
-- rollback SQL-156:
--| ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__decision";

-- -----------------------------------------------------------------------------
-- SQL-157 | ck_bookings__paquete | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__paquete";
ALTER TABLE "bookings" ADD CONSTRAINT "ck_bookings__paquete" CHECK ((origin <> 'INSTANT_BOOK' OR package_id IS NOT NULL) AND (NOT consumes_package_capacity OR package_id IS NOT NULL));
-- rollback SQL-157:
--| ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__paquete";

-- -----------------------------------------------------------------------------
-- SQL-158 | ck_bookings__consumo | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__consumo";
ALTER TABLE "bookings" ADD CONSTRAINT "ck_bookings__consumo" CHECK (consumes_global_capacity OR consumes_package_capacity);
-- rollback SQL-158:
--| ALTER TABLE "bookings" DROP CONSTRAINT IF EXISTS "ck_bookings__consumo";

-- -----------------------------------------------------------------------------
-- SQL-159 | ck_booking_consumed_dates__cantidad | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "booking_consumed_dates" DROP CONSTRAINT IF EXISTS "ck_booking_consumed_dates__cantidad";
ALTER TABLE "booking_consumed_dates" ADD CONSTRAINT "ck_booking_consumed_dates__cantidad" CHECK (quantity >= 1);
-- rollback SQL-159:
--| ALTER TABLE "booking_consumed_dates" DROP CONSTRAINT IF EXISTS "ck_booking_consumed_dates__cantidad";

-- -----------------------------------------------------------------------------
-- SQL-160 | ck_booking_terms_snapshots__formato | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "booking_terms_snapshots" DROP CONSTRAINT IF EXISTS "ck_booking_terms_snapshots__formato";
ALTER TABLE "booking_terms_snapshots" ADD CONSTRAINT "ck_booking_terms_snapshots__formato" CHECK (schema_version >= 1 AND jsonb_typeof(terms) = 'object');
-- rollback SQL-160:
--| ALTER TABLE "booking_terms_snapshots" DROP CONSTRAINT IF EXISTS "ck_booking_terms_snapshots__formato";

-- -----------------------------------------------------------------------------
-- SQL-161 | ck_commission_rates__porcentaje | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "commission_rates" DROP CONSTRAINT IF EXISTS "ck_commission_rates__porcentaje";
ALTER TABLE "commission_rates" ADD CONSTRAINT "ck_commission_rates__porcentaje" CHECK (rate BETWEEN 0 AND 1);
-- rollback SQL-161:
--| ALTER TABLE "commission_rates" DROP CONSTRAINT IF EXISTS "ck_commission_rates__porcentaje";

-- -----------------------------------------------------------------------------
-- SQL-162 | ck_commission_rates__periodo | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "commission_rates" DROP CONSTRAINT IF EXISTS "ck_commission_rates__periodo";
ALTER TABLE "commission_rates" ADD CONSTRAINT "ck_commission_rates__periodo" CHECK (valid_until IS NULL OR valid_until > valid_from);
-- rollback SQL-162:
--| ALTER TABLE "commission_rates" DROP CONSTRAINT IF EXISTS "ck_commission_rates__periodo";

-- -----------------------------------------------------------------------------
-- SQL-163 | ex_commission_rates__sin_solape | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "commission_rates" DROP CONSTRAINT IF EXISTS "ex_commission_rates__sin_solape";
ALTER TABLE "commission_rates" ADD CONSTRAINT "ex_commission_rates__sin_solape" EXCLUDE USING gist (tstzrange(valid_from, valid_until, '[)') WITH &&);
-- rollback SQL-163:
--| ALTER TABLE "commission_rates" DROP CONSTRAINT IF EXISTS "ex_commission_rates__sin_solape";

-- -----------------------------------------------------------------------------
-- SQL-164 | ck_commission_records__importes | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "commission_records" DROP CONSTRAINT IF EXISTS "ck_commission_records__importes";
ALTER TABLE "commission_records" ADD CONSTRAINT "ck_commission_records__importes" CHECK (base_amount >= 0 AND amount >= 0 AND rate BETWEEN 0 AND 1 AND currency = 'COP');
-- rollback SQL-164:
--| ALTER TABLE "commission_records" DROP CONSTRAINT IF EXISTS "ck_commission_records__importes";

-- -----------------------------------------------------------------------------
-- SQL-165 | ck_commission_records__devengo | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "commission_records" DROP CONSTRAINT IF EXISTS "ck_commission_records__devengo";
ALTER TABLE "commission_records" ADD CONSTRAINT "ck_commission_records__devengo" CHECK (status <> 'DEVENGADA' OR accrued_at IS NOT NULL);
-- rollback SQL-165:
--| ALTER TABLE "commission_records" DROP CONSTRAINT IF EXISTS "ck_commission_records__devengo";

-- -----------------------------------------------------------------------------
-- SQL-166 | ck_commission_records__reversion | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "commission_records" DROP CONSTRAINT IF EXISTS "ck_commission_records__reversion";
ALTER TABLE "commission_records" ADD CONSTRAINT "ck_commission_records__reversion" CHECK (status <> 'REVERTIDA' OR (reversed_at IS NOT NULL AND reversal_reason IS NOT NULL));
-- rollback SQL-166:
--| ALTER TABLE "commission_records" DROP CONSTRAINT IF EXISTS "ck_commission_records__reversion";

-- -----------------------------------------------------------------------------
-- SQL-167 | ck_booking_change_proposals__importes | TDD §4.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
ALTER TABLE "booking_change_proposals" DROP CONSTRAINT IF EXISTS "ck_booking_change_proposals__importes";
ALTER TABLE "booking_change_proposals" ADD CONSTRAINT "ck_booking_change_proposals__importes" CHECK ((proposed_price IS NULL OR proposed_price >= 0) AND currency = 'COP');
-- rollback SQL-167:
--| ALTER TABLE "booking_change_proposals" DROP CONSTRAINT IF EXISTS "ck_booking_change_proposals__importes";

-- -----------------------------------------------------------------------------
-- SQL-425 | trg_booking_terms_snapshots__inmutable | TDD §4.3 y §5.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_booking_terms_snapshots__inmutable"
  BEFORE UPDATE OR DELETE ON "booking_terms_snapshots"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-425:
--| DROP TRIGGER IF EXISTS "trg_booking_terms_snapshots__inmutable" ON "booking_terms_snapshots";

-- -----------------------------------------------------------------------------
-- SQL-426 | trg_booking_status_history__inmutable | TDD §4.3 y §5.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_booking_status_history__inmutable"
  BEFORE UPDATE OR DELETE ON "booking_status_history"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-426:
--| DROP TRIGGER IF EXISTS "trg_booking_status_history__inmutable" ON "booking_status_history";

-- -----------------------------------------------------------------------------
-- SQL-427 | trg_commission_records__sin_borrado | TDD §4.3 y §5.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_commission_records__sin_borrado"
  BEFORE DELETE ON "commission_records"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('sin_borrado');
-- rollback SQL-427:
--| DROP TRIGGER IF EXISTS "trg_commission_records__sin_borrado" ON "commission_records";

-- -----------------------------------------------------------------------------
-- SQL-435 | trg_dispute_resolutions__inmutable | TDD §4.3 y §5.3 | migración 08_contratacion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_dispute_resolutions__inmutable"
  BEFORE UPDATE OR DELETE ON "dispute_resolutions"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-435:
--| DROP TRIGGER IF EXISTS "trg_dispute_resolutions__inmutable" ON "dispute_resolutions";

-- -----------------------------------------------------------------------------
-- SQL-448 | privilegios de las tablas de la migración 08 | TDD §7.2 | migración 08_contratacion
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_availability" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_availability" TO pe_retention;
REVOKE DELETE ON "provider_availability" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "provider_daily_capacity" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "provider_daily_capacity" TO pe_retention;
REVOKE DELETE ON "provider_daily_capacity" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "package_daily_capacity" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "package_daily_capacity" TO pe_retention;
REVOKE DELETE ON "package_daily_capacity" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "bookings" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "bookings" TO pe_retention;
REVOKE DELETE ON "bookings" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "booking_consumed_dates" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "booking_consumed_dates" TO pe_retention;
REVOKE DELETE ON "booking_consumed_dates" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "booking_terms_snapshots" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "booking_terms_snapshots" TO pe_retention;
REVOKE UPDATE ON "booking_terms_snapshots" FROM pe_api, pe_worker;
REVOKE DELETE ON "booking_terms_snapshots" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "booking_status_history" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "booking_status_history" TO pe_retention;
REVOKE UPDATE ON "booking_status_history" FROM pe_api, pe_worker;
REVOKE DELETE ON "booking_status_history" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "booking_change_proposals" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "booking_change_proposals" TO pe_retention;
REVOKE DELETE ON "booking_change_proposals" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "commission_rates" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "commission_rates" TO pe_retention;
REVOKE DELETE ON "commission_rates" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "commission_records" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "commission_records" TO pe_retention;
REVOKE DELETE ON "commission_records" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "dispute_resolutions" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "dispute_resolutions" TO pe_retention;
REVOKE UPDATE ON "dispute_resolutions" FROM pe_api, pe_worker;
REVOKE DELETE ON "dispute_resolutions" FROM pe_api, pe_worker;
-- rollback SQL-448:
--| REVOKE ALL ON "provider_availability" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "provider_daily_capacity" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "package_daily_capacity" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "bookings" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "booking_consumed_dates" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "booking_terms_snapshots" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "booking_status_history" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "booking_change_proposals" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "commission_rates" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "commission_records" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "dispute_resolutions" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-468 | lectura analítica sin columnas personales, migración 08 | TDD §7.1 y §7.2 | migración 08_contratacion
-- -----------------------------------------------------------------------------
GRANT SELECT ON "provider_availability" TO pe_readonly;
GRANT SELECT ON "provider_daily_capacity" TO pe_readonly;
GRANT SELECT ON "package_daily_capacity" TO pe_readonly;
REVOKE SELECT ON "bookings" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "event_id", "quotation_item_id", "provider_id", "package_id", "origin", "status", "quantity", "service_starts_at", "service_ends_at", "time_zone", "first_service_date", "accepted_price", "currency", "consumes_global_capacity", "consumes_package_capacity", "confirmed_at", "confirmed_by_user_id", "review_origin", "organizer_review_decision", "organizer_review_decided_at", "review_decision_due_at", "review_window_closed_at", "cancellation_requested_by", "cancellation_requested_at", "cancellation_response_due_at", "service_marked_done_at", "completion_due_at", "closure_reminder_sent_at", "completed_at", "cancelled_at", "created_at", "updated_at") ON "bookings" TO pe_readonly;
GRANT SELECT ON "booking_consumed_dates" TO pe_readonly;
REVOKE SELECT ON "booking_terms_snapshots" FROM pe_readonly;
GRANT SELECT ("booking_id", "organization_id", "provider_id", "schema_version", "created_at") ON "booking_terms_snapshots" TO pe_readonly;
REVOKE SELECT ON "booking_status_history" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "provider_id", "booking_id", "from_status", "to_status", "actor_party", "actor_user_id", "occurred_at", "created_at") ON "booking_status_history" TO pe_readonly;
GRANT SELECT ON "booking_change_proposals" TO pe_readonly;
GRANT SELECT ON "commission_rates" TO pe_readonly;
GRANT SELECT ON "commission_records" TO pe_readonly;
REVOKE SELECT ON "dispute_resolutions" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "booking_id", "decision", "resulting_booking_status", "resulting_commission_status", "resolved_by_user_id", "resolved_at", "created_at") ON "dispute_resolutions" TO pe_readonly;
-- rollback SQL-468:
--| REVOKE SELECT ON "provider_availability" FROM pe_readonly;
--| REVOKE SELECT ON "provider_daily_capacity" FROM pe_readonly;
--| REVOKE SELECT ON "package_daily_capacity" FROM pe_readonly;
--| REVOKE SELECT ON "bookings" FROM pe_readonly;
--| REVOKE SELECT ON "booking_consumed_dates" FROM pe_readonly;
--| REVOKE SELECT ON "booking_terms_snapshots" FROM pe_readonly;
--| REVOKE SELECT ON "booking_status_history" FROM pe_readonly;
--| REVOKE SELECT ON "booking_change_proposals" FROM pe_readonly;
--| REVOKE SELECT ON "commission_rates" FROM pe_readonly;
--| REVOKE SELECT ON "commission_records" FROM pe_readonly;
--| REVOKE SELECT ON "dispute_resolutions" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 09_rfq
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-210 | ck_rfq_cycles__sla | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_cycles" DROP CONSTRAINT IF EXISTS "ck_rfq_cycles__sla";
ALTER TABLE "rfq_cycles" ADD CONSTRAINT "ck_rfq_cycles__sla" CHECK (sla_hours IN (6, 12, 24, 48));
-- rollback SQL-210:
--| ALTER TABLE "rfq_cycles" DROP CONSTRAINT IF EXISTS "ck_rfq_cycles__sla";

-- -----------------------------------------------------------------------------
-- SQL-211 | ck_rfq_cycles__ronda | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_cycles" DROP CONSTRAINT IF EXISTS "ck_rfq_cycles__ronda";
ALTER TABLE "rfq_cycles" ADD CONSTRAINT "ck_rfq_cycles__ronda" CHECK (round >= 1);
-- rollback SQL-211:
--| ALTER TABLE "rfq_cycles" DROP CONSTRAINT IF EXISTS "ck_rfq_cycles__ronda";

-- -----------------------------------------------------------------------------
-- SQL-212 | ck_rfq_requests__cupo | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_requests" DROP CONSTRAINT IF EXISTS "ck_rfq_requests__cupo";
ALTER TABLE "rfq_requests" ADD CONSTRAINT "ck_rfq_requests__cupo" CHECK (slot BETWEEN 1 AND 5);
-- rollback SQL-212:
--| ALTER TABLE "rfq_requests" DROP CONSTRAINT IF EXISTS "ck_rfq_requests__cupo";

-- -----------------------------------------------------------------------------
-- SQL-213 | ck_rfq_requests__reintentos | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_requests" DROP CONSTRAINT IF EXISTS "ck_rfq_requests__reintentos";
ALTER TABLE "rfq_requests" ADD CONSTRAINT "ck_rfq_requests__reintentos" CHECK (retry_count BETWEEN 0 AND 3);
-- rollback SQL-213:
--| ALTER TABLE "rfq_requests" DROP CONSTRAINT IF EXISTS "ck_rfq_requests__reintentos";

-- -----------------------------------------------------------------------------
-- SQL-214 | ck_rfq_requests__snapshot | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_requests" DROP CONSTRAINT IF EXISTS "ck_rfq_requests__snapshot";
ALTER TABLE "rfq_requests" ADD CONSTRAINT "ck_rfq_requests__snapshot" CHECK (jsonb_typeof(request_snapshot) = 'object' AND snapshot_schema_version >= 1);
-- rollback SQL-214:
--| ALTER TABLE "rfq_requests" DROP CONSTRAINT IF EXISTS "ck_rfq_requests__snapshot";

-- -----------------------------------------------------------------------------
-- SQL-215 | ck_magic_link_grants__token | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "magic_link_grants" DROP CONSTRAINT IF EXISTS "ck_magic_link_grants__token";
ALTER TABLE "magic_link_grants" ADD CONSTRAINT "ck_magic_link_grants__token" CHECK (octet_length(token_hash) = 32 AND octet_length(token_nonce) = 32);
-- rollback SQL-215:
--| ALTER TABLE "magic_link_grants" DROP CONSTRAINT IF EXISTS "ck_magic_link_grants__token";

-- -----------------------------------------------------------------------------
-- SQL-216 | ck_rfq_offers__decision | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__decision";
ALTER TABLE "rfq_offers" ADD CONSTRAINT "ck_rfq_offers__decision" CHECK ((decision = 'OFERTA') = (status IS NOT NULL));
-- rollback SQL-216:
--| ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__decision";

-- -----------------------------------------------------------------------------
-- SQL-217 | ck_rfq_offers__precio | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__precio";
ALTER TABLE "rfq_offers" ADD CONSTRAINT "ck_rfq_offers__precio" CHECK ((decision = 'RECHAZO' OR total_price IS NOT NULL) AND (total_price IS NULL OR total_price >= 0) AND currency = 'COP');
-- rollback SQL-217:
--| ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__precio";

-- -----------------------------------------------------------------------------
-- SQL-218 | ck_rfq_offers__revision | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__revision";
ALTER TABLE "rfq_offers" ADD CONSTRAINT "ck_rfq_offers__revision" CHECK (revision >= 1 AND (revision = 1 OR revision_reason IS NOT NULL));
-- rollback SQL-218:
--| ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__revision";

-- -----------------------------------------------------------------------------
-- SQL-219 | ck_rfq_offers__extras | TDD §4.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__extras";
ALTER TABLE "rfq_offers" ADD CONSTRAINT "ck_rfq_offers__extras" CHECK (jsonb_typeof(extras) = 'array');
-- rollback SQL-219:
--| ALTER TABLE "rfq_offers" DROP CONSTRAINT IF EXISTS "ck_rfq_offers__extras";

-- -----------------------------------------------------------------------------
-- SQL-428 | trg_rfq_requests__snapshot_inmutable | TDD §4.3 y §5.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_rfq_requests__snapshot_inmutable"
  BEFORE UPDATE OR DELETE ON "rfq_requests"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('proteger', 'request_snapshot', 'snapshot_schema_version', 'sla_expires_at', 'provider_id', 'cycle_id');
-- rollback SQL-428:
--| DROP TRIGGER IF EXISTS "trg_rfq_requests__snapshot_inmutable" ON "rfq_requests";

-- -----------------------------------------------------------------------------
-- SQL-429 | trg_rfq_offers__inmutable | TDD §4.3 y §5.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_rfq_offers__inmutable"
  BEFORE UPDATE OR DELETE ON "rfq_offers"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('permitir', 'status', 'status_changed_at', 'updated_at');
-- rollback SQL-429:
--| DROP TRIGGER IF EXISTS "trg_rfq_offers__inmutable" ON "rfq_offers";

-- -----------------------------------------------------------------------------
-- SQL-430 | trg_awards__inmutable | TDD §4.3 y §5.3 | migración 09_rfq
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_awards__inmutable"
  BEFORE UPDATE OR DELETE ON "awards"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('congelada');
-- rollback SQL-430:
--| DROP TRIGGER IF EXISTS "trg_awards__inmutable" ON "awards";

-- -----------------------------------------------------------------------------
-- SQL-449 | privilegios de las tablas de la migración 09 | TDD §7.2 | migración 09_rfq
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "rfq_items" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "rfq_items" TO pe_retention;
REVOKE UPDATE ON "rfq_items" FROM pe_api, pe_worker;
REVOKE DELETE ON "rfq_items" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "rfq_cycles" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "rfq_cycles" TO pe_retention;
REVOKE DELETE ON "rfq_cycles" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "rfq_requests" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "rfq_requests" TO pe_retention;
REVOKE DELETE ON "rfq_requests" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "magic_link_grants" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "magic_link_grants" TO pe_retention;
REVOKE DELETE ON "magic_link_grants" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "rfq_offers" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "rfq_offers" TO pe_retention;
REVOKE DELETE ON "rfq_offers" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "awards" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "awards" TO pe_retention;
REVOKE UPDATE ON "awards" FROM pe_api, pe_worker;
REVOKE DELETE ON "awards" FROM pe_api, pe_worker;
-- rollback SQL-449:
--| REVOKE ALL ON "rfq_items" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "rfq_cycles" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "rfq_requests" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "magic_link_grants" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "rfq_offers" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "awards" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-469 | lectura analítica sin columnas personales, migración 09 | TDD §7.1 y §7.2 | migración 09_rfq
-- -----------------------------------------------------------------------------
GRANT SELECT ON "rfq_items" TO pe_readonly;
GRANT SELECT ON "rfq_cycles" TO pe_readonly;
REVOKE SELECT ON "rfq_requests" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "cycle_id", "quotation_item_id", "event_id", "provider_id", "slot", "status", "channel", "dispatch_status", "snapshot_schema_version", "sla_expires_at", "sent_at", "sla_reminder_sent_at", "responded_at", "rejected_at", "expired_at", "cancelled_at", "cancelled_by_user_id", "retry_count", "created_at", "updated_at") ON "rfq_requests" TO pe_readonly;
REVOKE SELECT ON "magic_link_grants" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "provider_id", "request_id", "secret_key_version", "status", "expires_at", "first_opened_at", "consumed_at", "revoked_at", "revocation_reason", "created_at", "updated_at") ON "magic_link_grants" TO pe_readonly;
REVOKE SELECT ON "rfq_offers" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "provider_id", "request_id", "revision", "decision", "status", "availability", "total_price", "currency", "valid_until", "origin", "revision_reason", "supersedes_offer_id", "replacement_confirmed", "received_at", "submitted_by_user_id", "status_changed_at", "created_at", "updated_at") ON "rfq_offers" TO pe_readonly;
GRANT SELECT ON "awards" TO pe_readonly;
-- rollback SQL-469:
--| REVOKE SELECT ON "rfq_items" FROM pe_readonly;
--| REVOKE SELECT ON "rfq_cycles" FROM pe_readonly;
--| REVOKE SELECT ON "rfq_requests" FROM pe_readonly;
--| REVOKE SELECT ON "magic_link_grants" FROM pe_readonly;
--| REVOKE SELECT ON "rfq_offers" FROM pe_readonly;
--| REVOKE SELECT ON "awards" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 10_respuesta_asistida
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-300 | ck_assisted_response_drafts__purga | TDD §4.3 | migración 10_respuesta_asistida
-- -----------------------------------------------------------------------------
ALTER TABLE "assisted_response_drafts" DROP CONSTRAINT IF EXISTS "ck_assisted_response_drafts__purga";
ALTER TABLE "assisted_response_drafts" ADD CONSTRAINT "ck_assisted_response_drafts__purga" CHECK ((purged_at IS NULL) = (imported_response IS NOT NULL));
-- rollback SQL-300:
--| ALTER TABLE "assisted_response_drafts" DROP CONSTRAINT IF EXISTS "ck_assisted_response_drafts__purga";

-- -----------------------------------------------------------------------------
-- SQL-301 | ck_assisted_response_drafts__formato | TDD §4.3 | migración 10_respuesta_asistida
-- -----------------------------------------------------------------------------
ALTER TABLE "assisted_response_drafts" DROP CONSTRAINT IF EXISTS "ck_assisted_response_drafts__formato";
ALTER TABLE "assisted_response_drafts" ADD CONSTRAINT "ck_assisted_response_drafts__formato" CHECK (jsonb_typeof(imported_response) = 'object' AND jsonb_typeof(validation_result) = 'object');
-- rollback SQL-301:
--| ALTER TABLE "assisted_response_drafts" DROP CONSTRAINT IF EXISTS "ck_assisted_response_drafts__formato";

-- -----------------------------------------------------------------------------
-- SQL-450 | privilegios de las tablas de la migración 10 | TDD §7.2 | migración 10_respuesta_asistida
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "assisted_response_drafts" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "assisted_response_drafts" TO pe_retention;
REVOKE DELETE ON "assisted_response_drafts" FROM pe_api, pe_worker;
-- rollback SQL-450:
--| REVOKE ALL ON "assisted_response_drafts" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-470 | lectura analítica sin columnas personales, migración 10 | TDD §7.1 y §7.2 | migración 10_respuesta_asistida
-- -----------------------------------------------------------------------------
REVOKE SELECT ON "assisted_response_drafts" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "request_id", "offer_id", "schema_version", "imported_by_user_id", "imported_at", "confirmed_at", "purged_at", "created_at", "updated_at") ON "assisted_response_drafts" TO pe_readonly;
-- rollback SQL-470:
--| REVOKE SELECT ON "assisted_response_drafts" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 11_resenas
-- Ejecutar con pe_migrator, inmediatamente después del SQL base de las tablas de esta migración (TDD §10.1).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-310 | ck_reviews__puntajes | TDD §4.3 | migración 11_resenas
-- -----------------------------------------------------------------------------
ALTER TABLE "reviews" DROP CONSTRAINT IF EXISTS "ck_reviews__puntajes";
ALTER TABLE "reviews" ADD CONSTRAINT "ck_reviews__puntajes" CHECK (punctuality BETWEEN 1 AND 5 AND service_quality BETWEEN 1 AND 5 AND communication BETWEEN 1 AND 5 AND value_for_money BETWEEN 1 AND 5);
-- rollback SQL-310:
--| ALTER TABLE "reviews" DROP CONSTRAINT IF EXISTS "ck_reviews__puntajes";

-- -----------------------------------------------------------------------------
-- SQL-311 | ck_reviews__promedio | TDD §4.3 | migración 11_resenas
-- -----------------------------------------------------------------------------
ALTER TABLE "reviews" DROP CONSTRAINT IF EXISTS "ck_reviews__promedio";
ALTER TABLE "reviews" ADD CONSTRAINT "ck_reviews__promedio" CHECK (average = (punctuality + service_quality + communication + value_for_money)::numeric / 4);
-- rollback SQL-311:
--| ALTER TABLE "reviews" DROP CONSTRAINT IF EXISTS "ck_reviews__promedio";

-- -----------------------------------------------------------------------------
-- SQL-312 | ck_reviews__ocultacion | TDD §4.3 | migración 11_resenas
-- -----------------------------------------------------------------------------
ALTER TABLE "reviews" DROP CONSTRAINT IF EXISTS "ck_reviews__ocultacion";
ALTER TABLE "reviews" ADD CONSTRAINT "ck_reviews__ocultacion" CHECK (status <> 'OCULTA' OR hidden_at IS NOT NULL);
-- rollback SQL-312:
--| ALTER TABLE "reviews" DROP CONSTRAINT IF EXISTS "ck_reviews__ocultacion";

-- -----------------------------------------------------------------------------
-- SQL-313 | ck_review_reports__resolucion | TDD §4.3 | migración 11_resenas
-- -----------------------------------------------------------------------------
ALTER TABLE "review_reports" DROP CONSTRAINT IF EXISTS "ck_review_reports__resolucion";
ALTER TABLE "review_reports" ADD CONSTRAINT "ck_review_reports__resolucion" CHECK (status <> 'RESUELTO' OR (decision IS NOT NULL AND resolved_at IS NOT NULL AND resolution_reason IS NOT NULL));
-- rollback SQL-313:
--| ALTER TABLE "review_reports" DROP CONSTRAINT IF EXISTS "ck_review_reports__resolucion";

-- -----------------------------------------------------------------------------
-- SQL-433 | trg_reviews__inmutable | TDD §4.3 y §5.3 | migración 11_resenas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "trg_reviews__inmutable"
  BEFORE UPDATE OR DELETE ON "reviews"
  FOR EACH ROW EXECUTE FUNCTION fn_reject_mutation('proteger', 'punctuality', 'service_quality', 'communication', 'value_for_money', 'average', 'comment', 'booking_id', 'author_user_id');
-- rollback SQL-433:
--| DROP TRIGGER IF EXISTS "trg_reviews__inmutable" ON "reviews";

-- -----------------------------------------------------------------------------
-- SQL-451 | privilegios de las tablas de la migración 11 | TDD §7.2 | migración 11_resenas
-- -----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "reviews" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "reviews" TO pe_retention;
REVOKE DELETE ON "reviews" FROM pe_api, pe_worker;
GRANT SELECT, INSERT, UPDATE, DELETE ON "review_reports" TO pe_api, pe_worker;
GRANT SELECT, UPDATE, DELETE ON "review_reports" TO pe_retention;
REVOKE DELETE ON "review_reports" FROM pe_api, pe_worker;
-- rollback SQL-451:
--| REVOKE ALL ON "reviews" FROM pe_api, pe_worker, pe_retention;
--| REVOKE ALL ON "review_reports" FROM pe_api, pe_worker, pe_retention;

-- -----------------------------------------------------------------------------
-- SQL-471 | lectura analítica sin columnas personales, migración 11 | TDD §7.1 y §7.2 | migración 11_resenas
-- -----------------------------------------------------------------------------
REVOKE SELECT ON "reviews" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "booking_id", "provider_id", "event_id", "organization_display_name", "punctuality", "service_quality", "communication", "value_for_money", "average", "status", "hidden_at", "responded_at", "created_at", "updated_at") ON "reviews" TO pe_readonly;
REVOKE SELECT ON "review_reports" FROM pe_readonly;
GRANT SELECT ("id", "organization_id", "review_id", "reporter_user_id", "reason", "status", "decision", "resolved_by_user_id", "resolved_at", "created_at", "updated_at") ON "review_reports" TO pe_readonly;
-- rollback SQL-471:
--| REVOKE SELECT ON "reviews" FROM pe_readonly;
--| REVOKE SELECT ON "review_reports" FROM pe_readonly;

-- =============================================================================
-- >>> MIGRACIÓN 20_rls
-- Etapa J (ADR-018). Ejecutar con pe_migrator, en una migración independiente.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SQL-500 | funciones de contexto de tenant | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_current_organization_id() RETURNS uuid
LANGUAGE sql STABLE
AS $$ SELECT nullif(current_setting('app.organization_id', true), '')::uuid $$;
CREATE OR REPLACE FUNCTION fn_current_provider_id() RETURNS uuid
LANGUAGE sql STABLE
AS $$ SELECT nullif(current_setting('app.provider_id', true), '')::uuid $$;
CREATE OR REPLACE FUNCTION fn_current_user_id() RETURNS uuid
LANGUAGE sql STABLE
AS $$ SELECT nullif(current_setting('app.user_id', true), '')::uuid $$;
CREATE OR REPLACE FUNCTION fn_is_platform_admin() RETURNS boolean
LANGUAGE sql STABLE
AS $$ SELECT coalesce(current_setting('app.platform_admin', true), '') = 'on' $$;
CREATE OR REPLACE FUNCTION fn_current_magic_token_hash() RETURNS bytea
LANGUAGE sql STABLE
AS $$ SELECT decode(nullif(current_setting('app.magic_token_hash', true), ''), 'hex') $$;
CREATE OR REPLACE FUNCTION fn_current_invitation_token_hash() RETURNS bytea
LANGUAGE sql STABLE
AS $$ SELECT decode(nullif(current_setting('app.invitation_token_hash', true), ''), 'hex') $$;
-- rollback SQL-500:
--| DROP FUNCTION IF EXISTS fn_current_organization_id();
--| DROP FUNCTION IF EXISTS fn_current_provider_id();
--| DROP FUNCTION IF EXISTS fn_current_user_id();
--| DROP FUNCTION IF EXISTS fn_is_platform_admin();
--| DROP FUNCTION IF EXISTS fn_current_magic_token_hash();
--| DROP FUNCTION IF EXISTS fn_current_invitation_token_hash();

-- -----------------------------------------------------------------------------
-- SQL-510 | RLS de organizations | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-D
ALTER TABLE "organizations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "organizations" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_organizations__sistema" ON "organizations";
CREATE POLICY "pol_organizations__sistema" ON "organizations" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_organizations__lectura_sistema" ON "organizations";
CREATE POLICY "pol_organizations__lectura_sistema" ON "organizations" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_organizations__lectura" ON "organizations";
CREATE POLICY "pol_organizations__lectura" ON "organizations" FOR SELECT TO pe_api, pe_worker
  USING (id = fn_current_organization_id() OR fn_is_platform_admin() OR EXISTS (SELECT 1 FROM memberships m WHERE m.organization_id = organizations.id AND m.user_id = fn_current_user_id()));
DROP POLICY IF EXISTS "pol_organizations__alta" ON "organizations";
CREATE POLICY "pol_organizations__alta" ON "organizations" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (id = fn_current_organization_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_organizations__cambio" ON "organizations";
CREATE POLICY "pol_organizations__cambio" ON "organizations" FOR UPDATE TO pe_api, pe_worker
  USING (id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-510:
--| DROP POLICY IF EXISTS "pol_organizations__sistema" ON "organizations";
--| DROP POLICY IF EXISTS "pol_organizations__lectura_sistema" ON "organizations";
--| DROP POLICY IF EXISTS "pol_organizations__lectura" ON "organizations";
--| DROP POLICY IF EXISTS "pol_organizations__alta" ON "organizations";
--| DROP POLICY IF EXISTS "pol_organizations__cambio" ON "organizations";
--| ALTER TABLE "organizations" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "organizations" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-511 | RLS de memberships | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-D
ALTER TABLE "memberships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "memberships" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_memberships__sistema" ON "memberships";
CREATE POLICY "pol_memberships__sistema" ON "memberships" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_memberships__lectura_sistema" ON "memberships";
CREATE POLICY "pol_memberships__lectura_sistema" ON "memberships" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_memberships__lectura" ON "memberships";
CREATE POLICY "pol_memberships__lectura" ON "memberships" FOR SELECT TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR user_id = fn_current_user_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_memberships__alta" ON "memberships";
CREATE POLICY "pol_memberships__alta" ON "memberships" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_memberships__cambio" ON "memberships";
CREATE POLICY "pol_memberships__cambio" ON "memberships" FOR UPDATE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-511:
--| DROP POLICY IF EXISTS "pol_memberships__sistema" ON "memberships";
--| DROP POLICY IF EXISTS "pol_memberships__lectura_sistema" ON "memberships";
--| DROP POLICY IF EXISTS "pol_memberships__lectura" ON "memberships";
--| DROP POLICY IF EXISTS "pol_memberships__alta" ON "memberships";
--| DROP POLICY IF EXISTS "pol_memberships__cambio" ON "memberships";
--| ALTER TABLE "memberships" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "memberships" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-512 | RLS de invitations | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-D
ALTER TABLE "invitations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "invitations" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_invitations__sistema" ON "invitations";
CREATE POLICY "pol_invitations__sistema" ON "invitations" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_invitations__lectura_sistema" ON "invitations";
CREATE POLICY "pol_invitations__lectura_sistema" ON "invitations" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_invitations__lectura" ON "invitations";
CREATE POLICY "pol_invitations__lectura" ON "invitations" FOR SELECT TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR token_hash = fn_current_invitation_token_hash() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_invitations__alta" ON "invitations";
CREATE POLICY "pol_invitations__alta" ON "invitations" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_invitations__cambio" ON "invitations";
CREATE POLICY "pol_invitations__cambio" ON "invitations" FOR UPDATE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-512:
--| DROP POLICY IF EXISTS "pol_invitations__sistema" ON "invitations";
--| DROP POLICY IF EXISTS "pol_invitations__lectura_sistema" ON "invitations";
--| DROP POLICY IF EXISTS "pol_invitations__lectura" ON "invitations";
--| DROP POLICY IF EXISTS "pol_invitations__alta" ON "invitations";
--| DROP POLICY IF EXISTS "pol_invitations__cambio" ON "invitations";
--| ALTER TABLE "invitations" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "invitations" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-513 | RLS de ownership_transfers | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "ownership_transfers" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ownership_transfers" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_ownership_transfers__sistema" ON "ownership_transfers";
CREATE POLICY "pol_ownership_transfers__sistema" ON "ownership_transfers" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_ownership_transfers__lectura_sistema" ON "ownership_transfers";
CREATE POLICY "pol_ownership_transfers__lectura_sistema" ON "ownership_transfers" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_ownership_transfers__tenant" ON "ownership_transfers";
CREATE POLICY "pol_ownership_transfers__tenant" ON "ownership_transfers" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-513:
--| DROP POLICY IF EXISTS "pol_ownership_transfers__sistema" ON "ownership_transfers";
--| DROP POLICY IF EXISTS "pol_ownership_transfers__lectura_sistema" ON "ownership_transfers";
--| DROP POLICY IF EXISTS "pol_ownership_transfers__tenant" ON "ownership_transfers";
--| ALTER TABLE "ownership_transfers" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "ownership_transfers" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-514 | RLS de organization_plans | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "organization_plans" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "organization_plans" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_organization_plans__sistema" ON "organization_plans";
CREATE POLICY "pol_organization_plans__sistema" ON "organization_plans" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_organization_plans__lectura_sistema" ON "organization_plans";
CREATE POLICY "pol_organization_plans__lectura_sistema" ON "organization_plans" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_organization_plans__tenant" ON "organization_plans";
CREATE POLICY "pol_organization_plans__tenant" ON "organization_plans" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-514:
--| DROP POLICY IF EXISTS "pol_organization_plans__sistema" ON "organization_plans";
--| DROP POLICY IF EXISTS "pol_organization_plans__lectura_sistema" ON "organization_plans";
--| DROP POLICY IF EXISTS "pol_organization_plans__tenant" ON "organization_plans";
--| ALTER TABLE "organization_plans" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "organization_plans" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-515 | RLS de plan_usage_counters | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "plan_usage_counters" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "plan_usage_counters" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_plan_usage_counters__sistema" ON "plan_usage_counters";
CREATE POLICY "pol_plan_usage_counters__sistema" ON "plan_usage_counters" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_plan_usage_counters__lectura_sistema" ON "plan_usage_counters";
CREATE POLICY "pol_plan_usage_counters__lectura_sistema" ON "plan_usage_counters" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_plan_usage_counters__tenant" ON "plan_usage_counters";
CREATE POLICY "pol_plan_usage_counters__tenant" ON "plan_usage_counters" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-515:
--| DROP POLICY IF EXISTS "pol_plan_usage_counters__sistema" ON "plan_usage_counters";
--| DROP POLICY IF EXISTS "pol_plan_usage_counters__lectura_sistema" ON "plan_usage_counters";
--| DROP POLICY IF EXISTS "pol_plan_usage_counters__tenant" ON "plan_usage_counters";
--| ALTER TABLE "plan_usage_counters" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "plan_usage_counters" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-516 | RLS de event_templates | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-C
ALTER TABLE "event_templates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "event_templates" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_event_templates__sistema" ON "event_templates";
CREATE POLICY "pol_event_templates__sistema" ON "event_templates" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_event_templates__lectura_sistema" ON "event_templates";
CREATE POLICY "pol_event_templates__lectura_sistema" ON "event_templates" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_event_templates__lectura" ON "event_templates";
CREATE POLICY "pol_event_templates__lectura" ON "event_templates" FOR SELECT TO pe_api, pe_worker
  USING (organization_id IS NULL OR organization_id = fn_current_organization_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_event_templates__alta" ON "event_templates";
CREATE POLICY "pol_event_templates__alta" ON "event_templates" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
DROP POLICY IF EXISTS "pol_event_templates__cambio" ON "event_templates";
CREATE POLICY "pol_event_templates__cambio" ON "event_templates" FOR UPDATE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()))
  WITH CHECK (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
DROP POLICY IF EXISTS "pol_event_templates__baja" ON "event_templates";
CREATE POLICY "pol_event_templates__baja" ON "event_templates" FOR DELETE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
-- rollback SQL-516:
--| DROP POLICY IF EXISTS "pol_event_templates__sistema" ON "event_templates";
--| DROP POLICY IF EXISTS "pol_event_templates__lectura_sistema" ON "event_templates";
--| DROP POLICY IF EXISTS "pol_event_templates__lectura" ON "event_templates";
--| DROP POLICY IF EXISTS "pol_event_templates__alta" ON "event_templates";
--| DROP POLICY IF EXISTS "pol_event_templates__cambio" ON "event_templates";
--| DROP POLICY IF EXISTS "pol_event_templates__baja" ON "event_templates";
--| ALTER TABLE "event_templates" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "event_templates" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-517 | RLS de event_template_selections | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-C
ALTER TABLE "event_template_selections" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "event_template_selections" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_event_template_selections__sistema" ON "event_template_selections";
CREATE POLICY "pol_event_template_selections__sistema" ON "event_template_selections" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_event_template_selections__lectura_sistema" ON "event_template_selections";
CREATE POLICY "pol_event_template_selections__lectura_sistema" ON "event_template_selections" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_event_template_selections__lectura" ON "event_template_selections";
CREATE POLICY "pol_event_template_selections__lectura" ON "event_template_selections" FOR SELECT TO pe_api, pe_worker
  USING (organization_id IS NULL OR organization_id = fn_current_organization_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_event_template_selections__alta" ON "event_template_selections";
CREATE POLICY "pol_event_template_selections__alta" ON "event_template_selections" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
DROP POLICY IF EXISTS "pol_event_template_selections__cambio" ON "event_template_selections";
CREATE POLICY "pol_event_template_selections__cambio" ON "event_template_selections" FOR UPDATE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()))
  WITH CHECK (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
DROP POLICY IF EXISTS "pol_event_template_selections__baja" ON "event_template_selections";
CREATE POLICY "pol_event_template_selections__baja" ON "event_template_selections" FOR DELETE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
-- rollback SQL-517:
--| DROP POLICY IF EXISTS "pol_event_template_selections__sistema" ON "event_template_selections";
--| DROP POLICY IF EXISTS "pol_event_template_selections__lectura_sistema" ON "event_template_selections";
--| DROP POLICY IF EXISTS "pol_event_template_selections__lectura" ON "event_template_selections";
--| DROP POLICY IF EXISTS "pol_event_template_selections__alta" ON "event_template_selections";
--| DROP POLICY IF EXISTS "pol_event_template_selections__cambio" ON "event_template_selections";
--| DROP POLICY IF EXISTS "pol_event_template_selections__baja" ON "event_template_selections";
--| ALTER TABLE "event_template_selections" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "event_template_selections" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-518 | RLS de whatsapp_templates | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-C
ALTER TABLE "whatsapp_templates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "whatsapp_templates" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_whatsapp_templates__sistema" ON "whatsapp_templates";
CREATE POLICY "pol_whatsapp_templates__sistema" ON "whatsapp_templates" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_whatsapp_templates__lectura_sistema" ON "whatsapp_templates";
CREATE POLICY "pol_whatsapp_templates__lectura_sistema" ON "whatsapp_templates" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_whatsapp_templates__lectura" ON "whatsapp_templates";
CREATE POLICY "pol_whatsapp_templates__lectura" ON "whatsapp_templates" FOR SELECT TO pe_api, pe_worker
  USING (organization_id IS NULL OR organization_id = fn_current_organization_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_whatsapp_templates__alta" ON "whatsapp_templates";
CREATE POLICY "pol_whatsapp_templates__alta" ON "whatsapp_templates" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
DROP POLICY IF EXISTS "pol_whatsapp_templates__cambio" ON "whatsapp_templates";
CREATE POLICY "pol_whatsapp_templates__cambio" ON "whatsapp_templates" FOR UPDATE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()))
  WITH CHECK (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
DROP POLICY IF EXISTS "pol_whatsapp_templates__baja" ON "whatsapp_templates";
CREATE POLICY "pol_whatsapp_templates__baja" ON "whatsapp_templates" FOR DELETE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR (organization_id IS NULL AND fn_is_platform_admin()));
-- rollback SQL-518:
--| DROP POLICY IF EXISTS "pol_whatsapp_templates__sistema" ON "whatsapp_templates";
--| DROP POLICY IF EXISTS "pol_whatsapp_templates__lectura_sistema" ON "whatsapp_templates";
--| DROP POLICY IF EXISTS "pol_whatsapp_templates__lectura" ON "whatsapp_templates";
--| DROP POLICY IF EXISTS "pol_whatsapp_templates__alta" ON "whatsapp_templates";
--| DROP POLICY IF EXISTS "pol_whatsapp_templates__cambio" ON "whatsapp_templates";
--| DROP POLICY IF EXISTS "pol_whatsapp_templates__baja" ON "whatsapp_templates";
--| ALTER TABLE "whatsapp_templates" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "whatsapp_templates" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-519 | RLS de events | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "events" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_events__sistema" ON "events";
CREATE POLICY "pol_events__sistema" ON "events" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_events__lectura_sistema" ON "events";
CREATE POLICY "pol_events__lectura_sistema" ON "events" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_events__tenant" ON "events";
CREATE POLICY "pol_events__tenant" ON "events" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-519:
--| DROP POLICY IF EXISTS "pol_events__sistema" ON "events";
--| DROP POLICY IF EXISTS "pol_events__lectura_sistema" ON "events";
--| DROP POLICY IF EXISTS "pol_events__tenant" ON "events";
--| ALTER TABLE "events" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "events" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-520 | RLS de event_categories | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "event_categories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "event_categories" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_event_categories__sistema" ON "event_categories";
CREATE POLICY "pol_event_categories__sistema" ON "event_categories" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_event_categories__lectura_sistema" ON "event_categories";
CREATE POLICY "pol_event_categories__lectura_sistema" ON "event_categories" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_event_categories__tenant" ON "event_categories";
CREATE POLICY "pol_event_categories__tenant" ON "event_categories" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-520:
--| DROP POLICY IF EXISTS "pol_event_categories__sistema" ON "event_categories";
--| DROP POLICY IF EXISTS "pol_event_categories__lectura_sistema" ON "event_categories";
--| DROP POLICY IF EXISTS "pol_event_categories__tenant" ON "event_categories";
--| ALTER TABLE "event_categories" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "event_categories" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-521 | RLS de event_assignments | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "event_assignments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "event_assignments" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_event_assignments__sistema" ON "event_assignments";
CREATE POLICY "pol_event_assignments__sistema" ON "event_assignments" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_event_assignments__lectura_sistema" ON "event_assignments";
CREATE POLICY "pol_event_assignments__lectura_sistema" ON "event_assignments" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_event_assignments__tenant" ON "event_assignments";
CREATE POLICY "pol_event_assignments__tenant" ON "event_assignments" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-521:
--| DROP POLICY IF EXISTS "pol_event_assignments__sistema" ON "event_assignments";
--| DROP POLICY IF EXISTS "pol_event_assignments__lectura_sistema" ON "event_assignments";
--| DROP POLICY IF EXISTS "pol_event_assignments__tenant" ON "event_assignments";
--| ALTER TABLE "event_assignments" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "event_assignments" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-522 | RLS de bookings | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "bookings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "bookings" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_bookings__sistema" ON "bookings";
CREATE POLICY "pol_bookings__sistema" ON "bookings" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_bookings__lectura_sistema" ON "bookings";
CREATE POLICY "pol_bookings__lectura_sistema" ON "bookings" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_bookings__partes" ON "bookings";
CREATE POLICY "pol_bookings__partes" ON "bookings" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-522:
--| DROP POLICY IF EXISTS "pol_bookings__sistema" ON "bookings";
--| DROP POLICY IF EXISTS "pol_bookings__lectura_sistema" ON "bookings";
--| DROP POLICY IF EXISTS "pol_bookings__partes" ON "bookings";
--| ALTER TABLE "bookings" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "bookings" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-523 | RLS de booking_consumed_dates | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "booking_consumed_dates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "booking_consumed_dates" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_booking_consumed_dates__sistema" ON "booking_consumed_dates";
CREATE POLICY "pol_booking_consumed_dates__sistema" ON "booking_consumed_dates" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_booking_consumed_dates__lectura_sistema" ON "booking_consumed_dates";
CREATE POLICY "pol_booking_consumed_dates__lectura_sistema" ON "booking_consumed_dates" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_booking_consumed_dates__partes" ON "booking_consumed_dates";
CREATE POLICY "pol_booking_consumed_dates__partes" ON "booking_consumed_dates" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-523:
--| DROP POLICY IF EXISTS "pol_booking_consumed_dates__sistema" ON "booking_consumed_dates";
--| DROP POLICY IF EXISTS "pol_booking_consumed_dates__lectura_sistema" ON "booking_consumed_dates";
--| DROP POLICY IF EXISTS "pol_booking_consumed_dates__partes" ON "booking_consumed_dates";
--| ALTER TABLE "booking_consumed_dates" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "booking_consumed_dates" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-524 | RLS de booking_terms_snapshots | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "booking_terms_snapshots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "booking_terms_snapshots" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_booking_terms_snapshots__sistema" ON "booking_terms_snapshots";
CREATE POLICY "pol_booking_terms_snapshots__sistema" ON "booking_terms_snapshots" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_booking_terms_snapshots__lectura_sistema" ON "booking_terms_snapshots";
CREATE POLICY "pol_booking_terms_snapshots__lectura_sistema" ON "booking_terms_snapshots" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_booking_terms_snapshots__partes" ON "booking_terms_snapshots";
CREATE POLICY "pol_booking_terms_snapshots__partes" ON "booking_terms_snapshots" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-524:
--| DROP POLICY IF EXISTS "pol_booking_terms_snapshots__sistema" ON "booking_terms_snapshots";
--| DROP POLICY IF EXISTS "pol_booking_terms_snapshots__lectura_sistema" ON "booking_terms_snapshots";
--| DROP POLICY IF EXISTS "pol_booking_terms_snapshots__partes" ON "booking_terms_snapshots";
--| ALTER TABLE "booking_terms_snapshots" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "booking_terms_snapshots" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-525 | RLS de booking_status_history | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "booking_status_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "booking_status_history" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_booking_status_history__sistema" ON "booking_status_history";
CREATE POLICY "pol_booking_status_history__sistema" ON "booking_status_history" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_booking_status_history__lectura_sistema" ON "booking_status_history";
CREATE POLICY "pol_booking_status_history__lectura_sistema" ON "booking_status_history" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_booking_status_history__partes" ON "booking_status_history";
CREATE POLICY "pol_booking_status_history__partes" ON "booking_status_history" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-525:
--| DROP POLICY IF EXISTS "pol_booking_status_history__sistema" ON "booking_status_history";
--| DROP POLICY IF EXISTS "pol_booking_status_history__lectura_sistema" ON "booking_status_history";
--| DROP POLICY IF EXISTS "pol_booking_status_history__partes" ON "booking_status_history";
--| ALTER TABLE "booking_status_history" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "booking_status_history" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-526 | RLS de booking_change_proposals | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "booking_change_proposals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "booking_change_proposals" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_booking_change_proposals__sistema" ON "booking_change_proposals";
CREATE POLICY "pol_booking_change_proposals__sistema" ON "booking_change_proposals" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_booking_change_proposals__lectura_sistema" ON "booking_change_proposals";
CREATE POLICY "pol_booking_change_proposals__lectura_sistema" ON "booking_change_proposals" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_booking_change_proposals__partes" ON "booking_change_proposals";
CREATE POLICY "pol_booking_change_proposals__partes" ON "booking_change_proposals" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-526:
--| DROP POLICY IF EXISTS "pol_booking_change_proposals__sistema" ON "booking_change_proposals";
--| DROP POLICY IF EXISTS "pol_booking_change_proposals__lectura_sistema" ON "booking_change_proposals";
--| DROP POLICY IF EXISTS "pol_booking_change_proposals__partes" ON "booking_change_proposals";
--| ALTER TABLE "booking_change_proposals" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "booking_change_proposals" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-527 | RLS de commission_records | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "commission_records" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "commission_records" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_commission_records__sistema" ON "commission_records";
CREATE POLICY "pol_commission_records__sistema" ON "commission_records" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_commission_records__lectura_sistema" ON "commission_records";
CREATE POLICY "pol_commission_records__lectura_sistema" ON "commission_records" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_commission_records__partes" ON "commission_records";
CREATE POLICY "pol_commission_records__partes" ON "commission_records" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-527:
--| DROP POLICY IF EXISTS "pol_commission_records__sistema" ON "commission_records";
--| DROP POLICY IF EXISTS "pol_commission_records__lectura_sistema" ON "commission_records";
--| DROP POLICY IF EXISTS "pol_commission_records__partes" ON "commission_records";
--| ALTER TABLE "commission_records" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "commission_records" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-528 | RLS de rfq_items | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "rfq_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "rfq_items" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_rfq_items__sistema" ON "rfq_items";
CREATE POLICY "pol_rfq_items__sistema" ON "rfq_items" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_rfq_items__lectura_sistema" ON "rfq_items";
CREATE POLICY "pol_rfq_items__lectura_sistema" ON "rfq_items" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_rfq_items__tenant" ON "rfq_items";
CREATE POLICY "pol_rfq_items__tenant" ON "rfq_items" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-528:
--| DROP POLICY IF EXISTS "pol_rfq_items__sistema" ON "rfq_items";
--| DROP POLICY IF EXISTS "pol_rfq_items__lectura_sistema" ON "rfq_items";
--| DROP POLICY IF EXISTS "pol_rfq_items__tenant" ON "rfq_items";
--| ALTER TABLE "rfq_items" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "rfq_items" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-529 | RLS de rfq_cycles | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "rfq_cycles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "rfq_cycles" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_rfq_cycles__sistema" ON "rfq_cycles";
CREATE POLICY "pol_rfq_cycles__sistema" ON "rfq_cycles" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_rfq_cycles__lectura_sistema" ON "rfq_cycles";
CREATE POLICY "pol_rfq_cycles__lectura_sistema" ON "rfq_cycles" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_rfq_cycles__tenant" ON "rfq_cycles";
CREATE POLICY "pol_rfq_cycles__tenant" ON "rfq_cycles" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-529:
--| DROP POLICY IF EXISTS "pol_rfq_cycles__sistema" ON "rfq_cycles";
--| DROP POLICY IF EXISTS "pol_rfq_cycles__lectura_sistema" ON "rfq_cycles";
--| DROP POLICY IF EXISTS "pol_rfq_cycles__tenant" ON "rfq_cycles";
--| ALTER TABLE "rfq_cycles" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "rfq_cycles" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-530 | RLS de rfq_requests | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "rfq_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "rfq_requests" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_rfq_requests__sistema" ON "rfq_requests";
CREATE POLICY "pol_rfq_requests__sistema" ON "rfq_requests" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_rfq_requests__lectura_sistema" ON "rfq_requests";
CREATE POLICY "pol_rfq_requests__lectura_sistema" ON "rfq_requests" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_rfq_requests__partes" ON "rfq_requests";
CREATE POLICY "pol_rfq_requests__partes" ON "rfq_requests" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-530:
--| DROP POLICY IF EXISTS "pol_rfq_requests__sistema" ON "rfq_requests";
--| DROP POLICY IF EXISTS "pol_rfq_requests__lectura_sistema" ON "rfq_requests";
--| DROP POLICY IF EXISTS "pol_rfq_requests__partes" ON "rfq_requests";
--| ALTER TABLE "rfq_requests" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "rfq_requests" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-531 | RLS de magic_link_grants | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "magic_link_grants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "magic_link_grants" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_magic_link_grants__sistema" ON "magic_link_grants";
CREATE POLICY "pol_magic_link_grants__sistema" ON "magic_link_grants" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_magic_link_grants__lectura_sistema" ON "magic_link_grants";
CREATE POLICY "pol_magic_link_grants__lectura_sistema" ON "magic_link_grants" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_magic_link_grants__partes" ON "magic_link_grants";
CREATE POLICY "pol_magic_link_grants__partes" ON "magic_link_grants" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_magic_link_grants__token" ON "magic_link_grants";
CREATE POLICY "pol_magic_link_grants__token" ON "magic_link_grants" FOR SELECT TO pe_api
  USING (token_hash = fn_current_magic_token_hash());
-- rollback SQL-531:
--| DROP POLICY IF EXISTS "pol_magic_link_grants__sistema" ON "magic_link_grants";
--| DROP POLICY IF EXISTS "pol_magic_link_grants__lectura_sistema" ON "magic_link_grants";
--| DROP POLICY IF EXISTS "pol_magic_link_grants__partes" ON "magic_link_grants";
--| DROP POLICY IF EXISTS "pol_magic_link_grants__token" ON "magic_link_grants";
--| ALTER TABLE "magic_link_grants" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "magic_link_grants" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-532 | RLS de rfq_offers | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-B
ALTER TABLE "rfq_offers" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "rfq_offers" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_rfq_offers__sistema" ON "rfq_offers";
CREATE POLICY "pol_rfq_offers__sistema" ON "rfq_offers" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_rfq_offers__lectura_sistema" ON "rfq_offers";
CREATE POLICY "pol_rfq_offers__lectura_sistema" ON "rfq_offers" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_rfq_offers__partes" ON "rfq_offers";
CREATE POLICY "pol_rfq_offers__partes" ON "rfq_offers" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-532:
--| DROP POLICY IF EXISTS "pol_rfq_offers__sistema" ON "rfq_offers";
--| DROP POLICY IF EXISTS "pol_rfq_offers__lectura_sistema" ON "rfq_offers";
--| DROP POLICY IF EXISTS "pol_rfq_offers__partes" ON "rfq_offers";
--| ALTER TABLE "rfq_offers" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "rfq_offers" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-533 | RLS de awards | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "awards" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "awards" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_awards__sistema" ON "awards";
CREATE POLICY "pol_awards__sistema" ON "awards" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_awards__lectura_sistema" ON "awards";
CREATE POLICY "pol_awards__lectura_sistema" ON "awards" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_awards__tenant" ON "awards";
CREATE POLICY "pol_awards__tenant" ON "awards" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-533:
--| DROP POLICY IF EXISTS "pol_awards__sistema" ON "awards";
--| DROP POLICY IF EXISTS "pol_awards__lectura_sistema" ON "awards";
--| DROP POLICY IF EXISTS "pol_awards__tenant" ON "awards";
--| ALTER TABLE "awards" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "awards" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-534 | RLS de quotations | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quotations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quotations" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quotations__sistema" ON "quotations";
CREATE POLICY "pol_quotations__sistema" ON "quotations" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quotations__lectura_sistema" ON "quotations";
CREATE POLICY "pol_quotations__lectura_sistema" ON "quotations" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quotations__tenant" ON "quotations";
CREATE POLICY "pol_quotations__tenant" ON "quotations" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-534:
--| DROP POLICY IF EXISTS "pol_quotations__sistema" ON "quotations";
--| DROP POLICY IF EXISTS "pol_quotations__lectura_sistema" ON "quotations";
--| DROP POLICY IF EXISTS "pol_quotations__tenant" ON "quotations";
--| ALTER TABLE "quotations" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quotations" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-535 | RLS de quotation_items | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quotation_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quotation_items" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quotation_items__sistema" ON "quotation_items";
CREATE POLICY "pol_quotation_items__sistema" ON "quotation_items" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quotation_items__lectura_sistema" ON "quotation_items";
CREATE POLICY "pol_quotation_items__lectura_sistema" ON "quotation_items" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quotation_items__tenant" ON "quotation_items";
CREATE POLICY "pol_quotation_items__tenant" ON "quotation_items" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-535:
--| DROP POLICY IF EXISTS "pol_quotation_items__sistema" ON "quotation_items";
--| DROP POLICY IF EXISTS "pol_quotation_items__lectura_sistema" ON "quotation_items";
--| DROP POLICY IF EXISTS "pol_quotation_items__tenant" ON "quotation_items";
--| ALTER TABLE "quotation_items" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quotation_items" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-536 | RLS de quotation_item_subtypes | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quotation_item_subtypes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quotation_item_subtypes" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quotation_item_subtypes__sistema" ON "quotation_item_subtypes";
CREATE POLICY "pol_quotation_item_subtypes__sistema" ON "quotation_item_subtypes" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quotation_item_subtypes__lectura_sistema" ON "quotation_item_subtypes";
CREATE POLICY "pol_quotation_item_subtypes__lectura_sistema" ON "quotation_item_subtypes" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quotation_item_subtypes__tenant" ON "quotation_item_subtypes";
CREATE POLICY "pol_quotation_item_subtypes__tenant" ON "quotation_item_subtypes" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-536:
--| DROP POLICY IF EXISTS "pol_quotation_item_subtypes__sistema" ON "quotation_item_subtypes";
--| DROP POLICY IF EXISTS "pol_quotation_item_subtypes__lectura_sistema" ON "quotation_item_subtypes";
--| DROP POLICY IF EXISTS "pol_quotation_item_subtypes__tenant" ON "quotation_item_subtypes";
--| ALTER TABLE "quotation_item_subtypes" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quotation_item_subtypes" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-537 | RLS de quotation_item_options | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quotation_item_options" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quotation_item_options" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quotation_item_options__sistema" ON "quotation_item_options";
CREATE POLICY "pol_quotation_item_options__sistema" ON "quotation_item_options" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quotation_item_options__lectura_sistema" ON "quotation_item_options";
CREATE POLICY "pol_quotation_item_options__lectura_sistema" ON "quotation_item_options" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quotation_item_options__tenant" ON "quotation_item_options";
CREATE POLICY "pol_quotation_item_options__tenant" ON "quotation_item_options" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-537:
--| DROP POLICY IF EXISTS "pol_quotation_item_options__sistema" ON "quotation_item_options";
--| DROP POLICY IF EXISTS "pol_quotation_item_options__lectura_sistema" ON "quotation_item_options";
--| DROP POLICY IF EXISTS "pol_quotation_item_options__tenant" ON "quotation_item_options";
--| ALTER TABLE "quotation_item_options" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quotation_item_options" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-538 | RLS de quotation_item_tracking_history | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quotation_item_tracking_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quotation_item_tracking_history" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quotation_item_tracking_history__sistema" ON "quotation_item_tracking_history";
CREATE POLICY "pol_quotation_item_tracking_history__sistema" ON "quotation_item_tracking_history" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quotation_item_tracking_history__lectura_sistema" ON "quotation_item_tracking_history";
CREATE POLICY "pol_quotation_item_tracking_history__lectura_sistema" ON "quotation_item_tracking_history" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quotation_item_tracking_history__tenant" ON "quotation_item_tracking_history";
CREATE POLICY "pol_quotation_item_tracking_history__tenant" ON "quotation_item_tracking_history" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-538:
--| DROP POLICY IF EXISTS "pol_quotation_item_tracking_history__sistema" ON "quotation_item_tracking_history";
--| DROP POLICY IF EXISTS "pol_quotation_item_tracking_history__lectura_sistema" ON "quotation_item_tracking_history";
--| DROP POLICY IF EXISTS "pol_quotation_item_tracking_history__tenant" ON "quotation_item_tracking_history";
--| ALTER TABLE "quotation_item_tracking_history" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quotation_item_tracking_history" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-539 | RLS de quotation_versions | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quotation_versions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quotation_versions" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quotation_versions__sistema" ON "quotation_versions";
CREATE POLICY "pol_quotation_versions__sistema" ON "quotation_versions" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quotation_versions__lectura_sistema" ON "quotation_versions";
CREATE POLICY "pol_quotation_versions__lectura_sistema" ON "quotation_versions" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quotation_versions__tenant" ON "quotation_versions";
CREATE POLICY "pol_quotation_versions__tenant" ON "quotation_versions" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-539:
--| DROP POLICY IF EXISTS "pol_quotation_versions__sistema" ON "quotation_versions";
--| DROP POLICY IF EXISTS "pol_quotation_versions__lectura_sistema" ON "quotation_versions";
--| DROP POLICY IF EXISTS "pol_quotation_versions__tenant" ON "quotation_versions";
--| ALTER TABLE "quotation_versions" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quotation_versions" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-540 | RLS de quotation_documents | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quotation_documents" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quotation_documents" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quotation_documents__sistema" ON "quotation_documents";
CREATE POLICY "pol_quotation_documents__sistema" ON "quotation_documents" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quotation_documents__lectura_sistema" ON "quotation_documents";
CREATE POLICY "pol_quotation_documents__lectura_sistema" ON "quotation_documents" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quotation_documents__tenant" ON "quotation_documents";
CREATE POLICY "pol_quotation_documents__tenant" ON "quotation_documents" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-540:
--| DROP POLICY IF EXISTS "pol_quotation_documents__sistema" ON "quotation_documents";
--| DROP POLICY IF EXISTS "pol_quotation_documents__lectura_sistema" ON "quotation_documents";
--| DROP POLICY IF EXISTS "pol_quotation_documents__tenant" ON "quotation_documents";
--| ALTER TABLE "quotation_documents" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quotation_documents" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-541 | RLS de quick_quotations | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quick_quotations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quick_quotations" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quick_quotations__sistema" ON "quick_quotations";
CREATE POLICY "pol_quick_quotations__sistema" ON "quick_quotations" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quick_quotations__lectura_sistema" ON "quick_quotations";
CREATE POLICY "pol_quick_quotations__lectura_sistema" ON "quick_quotations" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quick_quotations__tenant" ON "quick_quotations";
CREATE POLICY "pol_quick_quotations__tenant" ON "quick_quotations" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-541:
--| DROP POLICY IF EXISTS "pol_quick_quotations__sistema" ON "quick_quotations";
--| DROP POLICY IF EXISTS "pol_quick_quotations__lectura_sistema" ON "quick_quotations";
--| DROP POLICY IF EXISTS "pol_quick_quotations__tenant" ON "quick_quotations";
--| ALTER TABLE "quick_quotations" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quick_quotations" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-542 | RLS de quick_quotation_options | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "quick_quotation_options" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "quick_quotation_options" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_quick_quotation_options__sistema" ON "quick_quotation_options";
CREATE POLICY "pol_quick_quotation_options__sistema" ON "quick_quotation_options" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_quick_quotation_options__lectura_sistema" ON "quick_quotation_options";
CREATE POLICY "pol_quick_quotation_options__lectura_sistema" ON "quick_quotation_options" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_quick_quotation_options__tenant" ON "quick_quotation_options";
CREATE POLICY "pol_quick_quotation_options__tenant" ON "quick_quotation_options" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-542:
--| DROP POLICY IF EXISTS "pol_quick_quotation_options__sistema" ON "quick_quotation_options";
--| DROP POLICY IF EXISTS "pol_quick_quotation_options__lectura_sistema" ON "quick_quotation_options";
--| DROP POLICY IF EXISTS "pol_quick_quotation_options__tenant" ON "quick_quotation_options";
--| ALTER TABLE "quick_quotation_options" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "quick_quotation_options" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-543 | RLS de assisted_response_drafts | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "assisted_response_drafts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "assisted_response_drafts" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_assisted_response_drafts__sistema" ON "assisted_response_drafts";
CREATE POLICY "pol_assisted_response_drafts__sistema" ON "assisted_response_drafts" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_assisted_response_drafts__lectura_sistema" ON "assisted_response_drafts";
CREATE POLICY "pol_assisted_response_drafts__lectura_sistema" ON "assisted_response_drafts" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_assisted_response_drafts__tenant" ON "assisted_response_drafts";
CREATE POLICY "pol_assisted_response_drafts__tenant" ON "assisted_response_drafts" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-543:
--| DROP POLICY IF EXISTS "pol_assisted_response_drafts__sistema" ON "assisted_response_drafts";
--| DROP POLICY IF EXISTS "pol_assisted_response_drafts__lectura_sistema" ON "assisted_response_drafts";
--| DROP POLICY IF EXISTS "pol_assisted_response_drafts__tenant" ON "assisted_response_drafts";
--| ALTER TABLE "assisted_response_drafts" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "assisted_response_drafts" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-544 | RLS de reviews | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-E
ALTER TABLE "reviews" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "reviews" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_reviews__sistema" ON "reviews";
CREATE POLICY "pol_reviews__sistema" ON "reviews" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_reviews__lectura_sistema" ON "reviews";
CREATE POLICY "pol_reviews__lectura_sistema" ON "reviews" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_reviews__lectura" ON "reviews";
CREATE POLICY "pol_reviews__lectura" ON "reviews" FOR SELECT TO pe_api, pe_worker
  USING (status = 'VISIBLE' OR organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_reviews__alta" ON "reviews";
CREATE POLICY "pol_reviews__alta" ON "reviews" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_reviews__cambio" ON "reviews";
CREATE POLICY "pol_reviews__cambio" ON "reviews" FOR UPDATE TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR provider_id = fn_current_provider_id() OR fn_is_platform_admin());
-- rollback SQL-544:
--| DROP POLICY IF EXISTS "pol_reviews__sistema" ON "reviews";
--| DROP POLICY IF EXISTS "pol_reviews__lectura_sistema" ON "reviews";
--| DROP POLICY IF EXISTS "pol_reviews__lectura" ON "reviews";
--| DROP POLICY IF EXISTS "pol_reviews__alta" ON "reviews";
--| DROP POLICY IF EXISTS "pol_reviews__cambio" ON "reviews";
--| ALTER TABLE "reviews" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "reviews" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-545 | RLS de review_reports | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-F
ALTER TABLE "review_reports" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "review_reports" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_review_reports__sistema" ON "review_reports";
CREATE POLICY "pol_review_reports__sistema" ON "review_reports" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_review_reports__lectura_sistema" ON "review_reports";
CREATE POLICY "pol_review_reports__lectura_sistema" ON "review_reports" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_review_reports__lectura" ON "review_reports";
CREATE POLICY "pol_review_reports__lectura" ON "review_reports" FOR SELECT TO pe_api, pe_worker
  USING (reporter_user_id = fn_current_user_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_review_reports__alta" ON "review_reports";
CREATE POLICY "pol_review_reports__alta" ON "review_reports" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (reporter_user_id = fn_current_user_id());
DROP POLICY IF EXISTS "pol_review_reports__cambio" ON "review_reports";
CREATE POLICY "pol_review_reports__cambio" ON "review_reports" FOR UPDATE TO pe_api, pe_worker
  USING (fn_is_platform_admin())
  WITH CHECK (fn_is_platform_admin());
-- rollback SQL-545:
--| DROP POLICY IF EXISTS "pol_review_reports__sistema" ON "review_reports";
--| DROP POLICY IF EXISTS "pol_review_reports__lectura_sistema" ON "review_reports";
--| DROP POLICY IF EXISTS "pol_review_reports__lectura" ON "review_reports";
--| DROP POLICY IF EXISTS "pol_review_reports__alta" ON "review_reports";
--| DROP POLICY IF EXISTS "pol_review_reports__cambio" ON "review_reports";
--| ALTER TABLE "review_reports" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "review_reports" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-546 | RLS de notifications | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-G
ALTER TABLE "notifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "notifications" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_notifications__sistema" ON "notifications";
CREATE POLICY "pol_notifications__sistema" ON "notifications" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_notifications__lectura_sistema" ON "notifications";
CREATE POLICY "pol_notifications__lectura_sistema" ON "notifications" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_notifications__destinatario" ON "notifications";
CREATE POLICY "pol_notifications__destinatario" ON "notifications" FOR ALL TO pe_api, pe_worker
  USING (user_id = fn_current_user_id() OR organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (user_id = fn_current_user_id() OR organization_id = fn_current_organization_id() OR fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_notifications__worker_alta" ON "notifications";
CREATE POLICY "pol_notifications__worker_alta" ON "notifications" FOR INSERT TO pe_worker
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_notifications__worker_cambio" ON "notifications";
CREATE POLICY "pol_notifications__worker_cambio" ON "notifications" FOR UPDATE TO pe_worker
  USING (true)
  WITH CHECK (true);
-- rollback SQL-546:
--| DROP POLICY IF EXISTS "pol_notifications__sistema" ON "notifications";
--| DROP POLICY IF EXISTS "pol_notifications__lectura_sistema" ON "notifications";
--| DROP POLICY IF EXISTS "pol_notifications__destinatario" ON "notifications";
--| DROP POLICY IF EXISTS "pol_notifications__worker_alta" ON "notifications";
--| DROP POLICY IF EXISTS "pol_notifications__worker_cambio" ON "notifications";
--| ALTER TABLE "notifications" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "notifications" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-547 | RLS de audit_logs | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-H
ALTER TABLE "audit_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "audit_logs" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_audit_logs__sistema" ON "audit_logs";
CREATE POLICY "pol_audit_logs__sistema" ON "audit_logs" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_audit_logs__lectura_sistema" ON "audit_logs";
CREATE POLICY "pol_audit_logs__lectura_sistema" ON "audit_logs" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_audit_logs__lectura" ON "audit_logs";
CREATE POLICY "pol_audit_logs__lectura" ON "audit_logs" FOR SELECT TO pe_api, pe_worker
  USING (fn_is_platform_admin());
DROP POLICY IF EXISTS "pol_audit_logs__alta" ON "audit_logs";
CREATE POLICY "pol_audit_logs__alta" ON "audit_logs" FOR INSERT TO pe_api, pe_worker
  WITH CHECK (true);
-- rollback SQL-547:
--| DROP POLICY IF EXISTS "pol_audit_logs__sistema" ON "audit_logs";
--| DROP POLICY IF EXISTS "pol_audit_logs__lectura_sistema" ON "audit_logs";
--| DROP POLICY IF EXISTS "pol_audit_logs__lectura" ON "audit_logs";
--| DROP POLICY IF EXISTS "pol_audit_logs__alta" ON "audit_logs";
--| ALTER TABLE "audit_logs" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "audit_logs" DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SQL-548 | RLS de dispute_resolutions | TDD §5.2 | migración 20_rls
-- -----------------------------------------------------------------------------
-- Perfil RLS-A
ALTER TABLE "dispute_resolutions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "dispute_resolutions" FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pol_dispute_resolutions__sistema" ON "dispute_resolutions";
CREATE POLICY "pol_dispute_resolutions__sistema" ON "dispute_resolutions" FOR ALL TO pe_owner, pe_migrator, pe_retention
  USING (true)
  WITH CHECK (true);
DROP POLICY IF EXISTS "pol_dispute_resolutions__lectura_sistema" ON "dispute_resolutions";
CREATE POLICY "pol_dispute_resolutions__lectura_sistema" ON "dispute_resolutions" FOR SELECT TO pe_worker, pe_readonly
  USING (true);
DROP POLICY IF EXISTS "pol_dispute_resolutions__tenant" ON "dispute_resolutions";
CREATE POLICY "pol_dispute_resolutions__tenant" ON "dispute_resolutions" FOR ALL TO pe_api, pe_worker
  USING (organization_id = fn_current_organization_id() OR fn_is_platform_admin())
  WITH CHECK (organization_id = fn_current_organization_id() OR fn_is_platform_admin());
-- rollback SQL-548:
--| DROP POLICY IF EXISTS "pol_dispute_resolutions__sistema" ON "dispute_resolutions";
--| DROP POLICY IF EXISTS "pol_dispute_resolutions__lectura_sistema" ON "dispute_resolutions";
--| DROP POLICY IF EXISTS "pol_dispute_resolutions__tenant" ON "dispute_resolutions";
--| ALTER TABLE "dispute_resolutions" NO FORCE ROW LEVEL SECURITY;
--| ALTER TABLE "dispute_resolutions" DISABLE ROW LEVEL SECURITY;
