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

sql_files=(
  "$REPO_ROOT/sql/01-dena-admin-file.sql"
  "$REPO_ROOT/sql/02-dena-rpc.sql"
  "$REPO_ROOT/sql/03-dena-staging.sql"
)

kubectl rollout status statefulset/postgresql-datalake -n datalake --timeout=180s >/dev/null
pg_password="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"

for sql_file in "${sql_files[@]}"; do
  if [[ ! -r "$sql_file" ]]; then
    echo "No se puede leer $sql_file" >&2
    exit 1
  fi
  echo "Aplicando $(basename "$sql_file")"
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -v ON_ERROR_STOP=1 -U postgres -d datalake <"$sql_file"
done

echo "Fase 15 SQL aplicada."
