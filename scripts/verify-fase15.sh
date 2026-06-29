#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl

echo "Usando KUBECONFIG=$KUBECONFIG"

kubectl rollout status statefulset/postgresql-datalake -n datalake --timeout=180s >/dev/null

pg_password="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"

check_sql="$(
  cat <<'SQL'
SELECT to_regclass('dena.admin_file');
SELECT to_regclass('dena.admin_file_staging');
SELECT EXISTS (
  SELECT 1
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'dena'
    AND c.relname = 'adminFile'
    AND c.relkind = 'v'
);
SELECT EXISTS (
  SELECT 1
  FROM pg_proc
  WHERE proname = 'dena_data_retrieve'
);
SELECT EXISTS (
  SELECT 1
  FROM pg_proc
  WHERE proname = 'dena_staging_to_main'
);
SQL
)"

schema_output="$(
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -U postgres -d datalake -Atc "$check_sql"
)"

printf '%s\n' "$schema_output"
grep -Fx "dena.admin_file" <<<"$schema_output" >/dev/null
grep -Fx "dena.admin_file_staging" <<<"$schema_output" >/dev/null
grep -Fx "t" <<<"$(sed -n '3p' <<<"$schema_output")" >/dev/null
grep -Fx "t" <<<"$(sed -n '4p' <<<"$schema_output")" >/dev/null
grep -Fx "t" <<<"$(sed -n '5p' <<<"$schema_output")" >/dev/null

staging_rows="$(
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -U postgres -d datalake -Atc "SELECT count(*) FROM dena.admin_file_staging;"
)"

main_rows="$(
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -U postgres -d datalake -Atc "SELECT count(*) FROM dena.admin_file;"
)"

echo "Staging rows: $staging_rows"
echo "Main rows: $main_rows"

echo "Fase 15 verificada: esquema DENA y staging operativos."
