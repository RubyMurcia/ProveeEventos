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
