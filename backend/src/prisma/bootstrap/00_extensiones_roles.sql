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
