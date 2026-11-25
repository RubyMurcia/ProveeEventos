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
