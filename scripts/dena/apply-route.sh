#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADMIN_PORT="${APISIX_ADMIN_PORT:-19180}"
ADMIN_URL="http://127.0.0.1:$ADMIN_PORT/apisix/admin"
PF_PID=""

cleanup() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

for bin in kubectl curl sed awk; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $bin" >&2
    exit 1
  }
done

kubectl rollout status deployment/apisix -n gateway --timeout=180s >/dev/null
kubectl rollout status deployment/keycloak -n auth --timeout=300s >/dev/null
kubectl rollout status deployment/postgrest -n datalake --timeout=180s >/dev/null

apisix_config="$(kubectl get configmap apisix -n gateway -o jsonpath='{.data.config\.yaml}')"
admin_key="$(
  awk '
    /name: "admin"/ { admin = 1; next }
    admin && /key:/ { print $2; exit }
  ' <<<"$apisix_config"
)"
oidc_secret="$(kubectl get secret apisix-oidc -n gateway -o jsonpath='{.data.client-secret}' | base64 -d)"

[[ -n "$admin_key" && -n "$oidc_secret" ]] || {
  echo "Faltan credenciales de APISIX u OIDC" >&2
  exit 1
}

kubectl port-forward -n gateway svc/apisix-admin "$ADMIN_PORT:9180" --address 127.0.0.1 \
  >/tmp/fase13-apisix-admin-port-forward.log 2>&1 &
PF_PID=$!

for _ in $(seq 1 60); do
  curl -fsS -H "X-API-KEY: $admin_key" "$ADMIN_URL/routes" >/dev/null 2>&1 && break
  sleep 1
done
curl -fsS -H "X-API-KEY: $admin_key" "$ADMIN_URL/routes" >/dev/null

put_file() {
  local resource="$1"
  local id="$2"
  local file="$3"
  curl -fsS -X PUT \
    -H "X-API-KEY: $admin_key" \
    -H "Content-Type: application/json" \
    --data-binary "@$file" \
    "$ADMIN_URL/$resource/$id" >/dev/null
}

put_template() {
  local id="$1"
  local file="$2"
  sed "s|__OIDC_CLIENT_SECRET__|$oidc_secret|g" "$file" | \
    curl -fsS -X PUT \
      -H "X-API-KEY: $admin_key" \
      -H "Content-Type: application/json" \
      --data-binary @- \
      "$ADMIN_URL/routes/$id" >/dev/null
}

put_file upstreams 1 "$REPO_ROOT/apisix/upstreams/1-postgrest.json"
put_file upstreams 2 "$REPO_ROOT/apisix/upstreams/2-keycloak.json"
put_file upstreams 3 "$REPO_ROOT/apisix/upstreams/3-dena-interop-spa.json"

put_file routes keycloak-realms "$REPO_ROOT/apisix/routes/keycloak-realms.json"
put_file routes keycloak-resources "$REPO_ROOT/apisix/routes/keycloak-resources.json"
put_file routes keycloak-admin "$REPO_ROOT/apisix/routes/keycloak-admin.json"
put_file routes keycloak-auth-root "$REPO_ROOT/apisix/routes/keycloak-auth-root.json"
put_file routes keycloak-auth-prefix "$REPO_ROOT/apisix/routes/keycloak-auth-prefix.json"
put_template postgrest-api-oidc "$REPO_ROOT/apisix/routes/postgrest-api.template.json"
put_template dena-admin-files-oidc "$REPO_ROOT/apisix/routes/dena-admin-files.template.json"
put_file routes dena-interop-spa-fallback "$REPO_ROOT/apisix/routes/dena-interop-spa.json"

curl -fsS -X DELETE -H "X-API-KEY: $admin_key" \
  "$ADMIN_URL/routes/fase13-postgrest" >/dev/null 2>&1 || true

echo "Fase 13 aplicada: upstreams, rutas Keycloak, API OIDC y endpoint DENA configurados."
