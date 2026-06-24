#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

POD_NAME="fase13-gateway-check"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl

echo "Usando KUBECONFIG=$KUBECONFIG"

echo
echo "[1/4] Workloads de APISIX y PostgREST"
kubectl rollout status deployment/apisix -n gateway --timeout=180s >/dev/null
kubectl rollout status deployment/postgrest -n datalake --timeout=180s >/dev/null
echo "Workloads disponibles"

echo
echo "[2/4] Ruta persistida en APISIX"
apisix_config="$(kubectl get configmap apisix -n gateway -o jsonpath='{.data.config\.yaml}')"
viewer_key="$(
  awk '
    /name: "viewer"/ { viewer = 1; next }
    viewer && /key:/ { print $2; exit }
  ' <<<"$apisix_config"
)"
[[ -n "$viewer_key" ]] || {
  echo "No se pudo obtener la clave Viewer de APISIX" >&2
  exit 1
}

kubectl delete pod "$POD_NAME" -n gateway --ignore-not-found --wait=true >/dev/null
route_output="$(
  kubectl run "$POD_NAME" \
    --rm -i \
    --restart=Never \
    --image=curlimages/curl:8.12.1 \
    -n gateway \
    -- curl -fsS \
      -H "X-API-KEY: $viewer_key" \
      http://apisix-admin:9180/apisix/admin/routes/fase13-postgrest
)"
grep -F '"name":"fase13-postgrest"' <<<"$route_output" >/dev/null
grep -F 'postgrest.datalake.svc.cluster.local:3000' <<<"$route_output" >/dev/null
echo "Ruta fase13-postgrest presente"

echo
echo "[3/4] Trafico extremo a extremo por el gateway"
gateway_output="$(
  kubectl run "$POD_NAME" \
    --rm -i \
    --restart=Never \
    --image=nginx:alpine \
    -n gateway \
    -- wget -S -O- http://apisix-gateway/api 2>&1
)"
grep -F "HTTP/1.1 200 OK" <<<"$gateway_output" >/dev/null
grep -F "Server: APISIX/3.16.0" <<<"$gateway_output" >/dev/null
grep -F '"swagger":"2.0"' <<<"$gateway_output" >/dev/null
echo "GET /api devuelve el OpenAPI de PostgREST a traves de APISIX"

echo
echo "[4/4] Cierre de fase"
echo "Fase 13 validada: APISIX publica PostgREST en /api con metodos de solo lectura."
