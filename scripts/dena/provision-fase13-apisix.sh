#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROUTE_FILE="${ROUTE_FILE:-$REPO_ROOT/apisix/routes/fase13-postgrest.json}"
ROUTE_ID="fase13-postgrest"
POD_NAME="fase13-apisix-provision"
CURL_IMAGE="${CURL_IMAGE:-curlimages/curl:8.12.1}"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl

[[ -r "$ROUTE_FILE" ]] || {
  echo "No se puede leer la definicion de ruta: $ROUTE_FILE" >&2
  exit 1
}

echo "Usando KUBECONFIG=$KUBECONFIG"

kubectl rollout status deployment/apisix -n gateway --timeout=180s >/dev/null
kubectl rollout status deployment/postgrest -n datalake --timeout=180s >/dev/null

apisix_config="$(kubectl get configmap apisix -n gateway -o jsonpath='{.data.config\.yaml}')"
admin_key="$(
  awk '
    /name: "admin"/ { admin = 1; next }
    admin && /key:/ { print $2; exit }
  ' <<<"$apisix_config"
)"

[[ -n "$admin_key" ]] || {
  echo "No se pudo obtener la clave Admin de APISIX desde configmap/apisix" >&2
  exit 1
}

route_json="$(<"$ROUTE_FILE")"

kubectl delete pod "$POD_NAME" -n gateway --ignore-not-found --wait=true >/dev/null
response="$(
  kubectl run "$POD_NAME" \
    --rm -i \
    --restart=Never \
    --image="$CURL_IMAGE" \
    -n gateway \
    -- curl -fsS -X PUT \
      -H "X-API-KEY: $admin_key" \
      -H "Content-Type: application/json" \
      --data "$route_json" \
      "http://apisix-admin:9180/apisix/admin/routes/$ROUTE_ID"
)"

grep -F "\"key\":\"/apisix/routes/$ROUTE_ID\"" <<<"$response" >/dev/null

echo "Fase 13 aprovisionada: /api y /api/* enrutan a PostgREST en modo solo lectura."
