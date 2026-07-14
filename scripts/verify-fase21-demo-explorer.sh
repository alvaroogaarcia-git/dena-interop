#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

NAMESPACE="datos-externos"
RELEASE="datos-externos-postgresql"
DATABASE="datos_externos"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin base64

echo "Usando KUBECONFIG=$KUBECONFIG"

kubectl rollout status deployment/postgrest-datos-externos -n "$NAMESPACE" --timeout=180s >/dev/null
kubectl get service postgrest-datos-externos -n "$NAMESPACE" >/dev/null
kubectl get secret postgrest-datos-externos-secret -n "$NAMESPACE" >/dev/null

pg_password="$(kubectl get secret -n "$NAMESPACE" "$RELEASE" -o jsonpath='{.data.postgres-password}' | base64 -d)"

check_sql="$(
  cat <<'SQL'
select to_regclass('public.dena_external_folders');
select to_regclass('public.dena_external_expedientes');
select to_regclass('public.dena_external_notificaciones');
select to_regclass('public.dena_external_pagos');
select to_regclass('public.dena_external_citas');
select to_regclass('public.dena_external_personas');
select to_regclass('public.dena_external_semantica');
select count(*) from public.dena_external_folders;
select count(*) from public.dena_external_expedientes where persona_id = 'CIT-10001';
select count(*) from public.dena_external_notificaciones where persona_id = 'CIT-10001';
select count(*) from public.dena_external_pagos where persona_id = 'CIT-10001';
select count(*) from public.dena_external_citas where persona_id = 'CIT-10001';
select count(*) from public.dena_external_personas where persona_id = 'CIT-10001';
SQL
)"

output="$(
  kubectl exec -i -n "$NAMESPACE" "$RELEASE-0" -- \
    env PGPASSWORD="$pg_password" \
    psql -U postgres -d "$DATABASE" -Atc "$check_sql"
)"

printf '%s\n' "$output"

grep -Fx "dena_external_folders" <<<"$(sed -n '1p' <<<"$output")" >/dev/null
grep -Fx "dena_external_expedientes" <<<"$(sed -n '2p' <<<"$output")" >/dev/null
grep -Fx "dena_external_notificaciones" <<<"$(sed -n '3p' <<<"$output")" >/dev/null
grep -Fx "dena_external_pagos" <<<"$(sed -n '4p' <<<"$output")" >/dev/null
grep -Fx "dena_external_citas" <<<"$(sed -n '5p' <<<"$output")" >/dev/null
grep -Fx "dena_external_personas" <<<"$(sed -n '6p' <<<"$output")" >/dev/null
grep -Fx "dena_external_semantica" <<<"$(sed -n '7p' <<<"$output")" >/dev/null
grep -Fx "6" <<<"$(sed -n '8p' <<<"$output")" >/dev/null
grep -Fx "6" <<<"$(sed -n '9p' <<<"$output")" >/dev/null
grep -Fx "2" <<<"$(sed -n '10p' <<<"$output")" >/dev/null
grep -Fx "3" <<<"$(sed -n '11p' <<<"$output")" >/dev/null
grep -Fx "2" <<<"$(sed -n '12p' <<<"$output")" >/dev/null
grep -Fx "1" <<<"$(sed -n '13p' <<<"$output")" >/dev/null

echo "Fase 21 verificada: explorador demo y vistas de datos externos operativos."
