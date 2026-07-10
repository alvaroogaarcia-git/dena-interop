#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl

bash "$REPO_ROOT/scripts/dena/install-nifi-postgresql-driver.sh"

kubectl rollout status statefulset/datos-externos-postgresql -n datos-externos --timeout=180s >/dev/null
datos_externos_password="$(
  kubectl get secret -n datos-externos datos-externos-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d
)"

kubectl exec -i -n datos-externos datos-externos-postgresql-0 -- \
  env PGPASSWORD="$datos_externos_password" \
  psql -v ON_ERROR_STOP=1 -U postgres -d datos_externos \
  < "$REPO_ROOT/sql/datos-externos/004_nifi_staging.sql"

export GROUP_NAME="${GROUP_NAME:-Fase 20 - DENA datos externos incremental}"
export STAGING_DB_NAME="${STAGING_DB_NAME:-datos_externos}"
export STAGING_DB_SCHEMA="${STAGING_DB_SCHEMA:-dena}"
export STAGING_DB_TABLE="${STAGING_DB_TABLE:-dena_admin_file_staging}"
export STAGING_DB_HOST="${STAGING_DB_HOST:-datos-externos-postgresql.datos-externos.svc.cluster.local}"
export STAGING_DB_PORT="${STAGING_DB_PORT:-5432}"
export STAGING_DB_PASSWORD="${STAGING_DB_PASSWORD:-$datos_externos_password}"
export PROMOTE_SQL="${PROMOTE_SQL:-SELECT dena.dena_admin_file_staging_to_dena();}"

bash "$REPO_ROOT/scripts/dena/provision-fase15-nifi.sh"
