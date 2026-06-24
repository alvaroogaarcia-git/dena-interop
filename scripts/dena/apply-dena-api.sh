#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQL_FILE="$REPO_ROOT/sql/datalake/01-dena-api.sql"
CSV_FILE="$(mktemp /tmp/dena-admin-file.XXXXXX.csv)"
REMOTE_CSV="/tmp/dena-admin-file.csv"

cleanup() {
  rm -f "$CSV_FILE"
  kubectl exec -n datalake postgresql-datalake-0 -- rm -f "$REMOTE_CSV" \
    >/dev/null 2>&1 || true
}
trap cleanup EXIT

command -v kubectl >/dev/null 2>&1 || {
  echo "Falta binario requerido: kubectl" >&2
  exit 1
}

kubectl rollout status statefulset/postgresql-verticales -n verticales --timeout=180s >/dev/null
kubectl rollout status statefulset/postgresql-datalake -n datalake --timeout=180s >/dev/null
kubectl rollout status deployment/postgrest -n datalake --timeout=180s >/dev/null

verticales_password="$(kubectl get secret postgresql-verticales -n verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
datalake_password="$(kubectl get secret postgresql-datalake -n datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$datalake_password" \
  psql -v ON_ERROR_STOP=1 -U postgres -d datalake <"$SQL_FILE"

kubectl exec -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$verticales_password" \
  psql -v ON_ERROR_STOP=1 -U postgres -d expedientes -Atc \
    "COPY (
      SELECT id, expediente_code, title, citizen_id, source_system, status,
             amount_eur, opened_at, updated_at
      FROM expedientes.admin_file
      ORDER BY id
    ) TO STDOUT WITH (FORMAT csv)" >"$CSV_FILE"

kubectl cp "$CSV_FILE" "datalake/postgresql-datalake-0:$REMOTE_CSV"

kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$datalake_password" \
  psql -v ON_ERROR_STOP=1 -U postgres -d datalake <<SQL
CREATE TEMP TABLE dena_admin_file_stage (
  source_id bigint,
  expediente_code text,
  title text,
  citizen_id text,
  source_system text,
  status text,
  amount_eur numeric(12,2),
  opened_at timestamptz,
  updated_at timestamptz
);

\copy dena_admin_file_stage FROM '$REMOTE_CSV' WITH (FORMAT csv)

INSERT INTO dena.admin_file (
  source_id, expediente_code, title, citizen_id, source_system, status,
  amount_eur, opened_at, updated_at, ingested_at
)
SELECT
  source_id, expediente_code, title, citizen_id, source_system, status,
  amount_eur, opened_at, updated_at, now()
FROM dena_admin_file_stage
ON CONFLICT (source_id) DO UPDATE
SET
  expediente_code = EXCLUDED.expediente_code,
  title = EXCLUDED.title,
  citizen_id = EXCLUDED.citizen_id,
  source_system = EXCLUDED.source_system,
  status = EXCLUDED.status,
  amount_eur = EXCLUDED.amount_eur,
  opened_at = EXCLUDED.opened_at,
  updated_at = EXCLUDED.updated_at,
  ingested_at = now();

NOTIFY pgrst, 'reload schema';
SELECT count(*) AS dena_admin_files FROM dena.admin_file;
SQL

echo "API DENA aplicada y datos de verticales sincronizados al datalake."
