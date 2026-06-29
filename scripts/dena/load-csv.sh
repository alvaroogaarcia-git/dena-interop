#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

CSV_FILE=""
CSV_HAS_HEADER="false"
PROMOTE="false"

usage() {
  cat <<'EOF'
Uso:
  bash scripts/dena/load-csv.sh --file datos.csv [--header] [--promote]
  cat datos.csv | bash scripts/dena/load-csv.sh [--header] [--promote]

Opciones:
  --file PATH   CSV local a cargar.
  --header      El CSV incluye fila de cabecera.
  --promote     Ejecuta dena.dena_staging_to_main() tras la carga.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      CSV_FILE="${2:-}"
      shift 2
      ;;
    --header)
      CSV_HAS_HEADER="true"
      shift
      ;;
    --promote)
      PROMOTE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$CSV_FILE" && "$1" != --* ]]; then
        CSV_FILE="$1"
        shift
      else
        echo "Argumento desconocido: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl

temp_input=""
remote_csv="/tmp/dena-load-csv.csv"
cleanup() {
  [[ -n "$temp_input" ]] && rm -f "$temp_input"
  kubectl exec -n datalake postgresql-datalake-0 -- rm -f "$remote_csv" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [[ -z "$CSV_FILE" ]]; then
  if [[ -t 0 ]]; then
    usage >&2
    exit 1
  fi
  temp_input="$(mktemp /tmp/dena-load-csv.XXXXXX.csv)"
  cat >"$temp_input"
  CSV_FILE="$temp_input"
fi

if [[ ! -r "$CSV_FILE" ]]; then
  echo "No se puede leer el CSV: $CSV_FILE" >&2
  exit 1
fi

kubectl rollout status statefulset/postgresql-datalake -n datalake --timeout=180s >/dev/null

pg_password="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl cp "$CSV_FILE" "datalake/postgresql-datalake-0:$remote_csv"

copy_opts="FORMAT csv"
if [[ "$CSV_HAS_HEADER" == "true" ]]; then
  copy_opts="$copy_opts, HEADER true"
fi

echo "Usando KUBECONFIG=$KUBECONFIG"
echo "Cargando $CSV_FILE en dena.admin_file_staging"

kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$pg_password" \
  psql -v ON_ERROR_STOP=1 -U postgres -d datalake <<SQL
TRUNCATE dena.admin_file_staging;
\copy dena.admin_file_staging (
  source_id,
  expediente_code,
  title,
  citizen_id,
  source_system,
  status,
  amount_eur,
  opened_at,
  updated_at
) FROM '$remote_csv' WITH ($copy_opts)
SELECT count(*) AS staging_rows FROM dena.admin_file_staging;
SQL

if [[ "$PROMOTE" == "true" ]]; then
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -v ON_ERROR_STOP=1 -U postgres -d datalake <<'SQL'
SELECT dena.dena_staging_to_main();
SELECT count(*) AS main_rows FROM dena.admin_file;
SQL
fi

echo "Carga completada."
