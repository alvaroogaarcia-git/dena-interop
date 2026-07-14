#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NAMESPACE="datos-externos"
RELEASE="datos-externos-postgresql"
DATABASE="datos_externos"
ENV_FILE="$REPO_ROOT/.local/fase19-datos-externos.env"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin base64

if [[ -r "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

if [[ -z "${DATOS_EXTERNOS_POSTGRES_PASSWORD:-}" ]]; then
  DATOS_EXTERNOS_POSTGRES_PASSWORD="$(
    kubectl get secret -n "$NAMESPACE" "$RELEASE" -o jsonpath='{.data.postgres-password}' | base64 -d
  )"
fi

if [[ -z "$DATOS_EXTERNOS_POSTGRES_PASSWORD" ]]; then
  echo "No se pudo obtener la password de PostgreSQL datos_externos" >&2
  exit 1
fi

for sql_file in \
  "$REPO_ROOT/sql/datos-externos/005_demo_explorer.sql" \
  "$REPO_ROOT/sql/datos-externos/006_citizen_rich_demo.sql"; do
  echo "Aplicando $(basename "$sql_file")"
  kubectl exec -i -n "$NAMESPACE" "$RELEASE-0" -- \
    env PGPASSWORD="$DATOS_EXTERNOS_POSTGRES_PASSWORD" \
    psql -v ON_ERROR_STOP=1 -U postgres -d "$DATABASE" \
    <"$sql_file"
done

echo "Creando secret de PostgREST para datos_externos"
kubectl create secret generic postgrest-datos-externos-secret \
  -n "$NAMESPACE" \
  --from-literal="db-uri=postgres://postgres:${DATOS_EXTERNOS_POSTGRES_PASSWORD}@${RELEASE}.${NAMESPACE}.svc.cluster.local:5432/${DATABASE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Aplicando PostgREST de datos externos"
kubectl apply -f "$REPO_ROOT/k8s-manifests/datos-externos/postgrest.yaml"
kubectl rollout status deployment/postgrest-datos-externos -n "$NAMESPACE" --timeout=180s >/dev/null

echo "Reaplicando rutas APISIX"
"$REPO_ROOT/scripts/dena/apply-route.sh" >/dev/null

echo "Aplicando consola admin con explorador"
kubectl apply -f "$REPO_ROOT/k8s-manifests/dena-admin-console.yaml"
kubectl rollout restart deployment/dena-admin-console -n app >/dev/null
kubectl rollout status deployment/dena-admin-console -n app --timeout=180s >/dev/null

echo "Fase 21 demo explorer aplicada."
