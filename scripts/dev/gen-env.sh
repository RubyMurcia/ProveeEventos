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
