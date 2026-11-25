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
