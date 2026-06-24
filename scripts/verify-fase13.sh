#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_ENV="$REPO_ROOT/.local/fase12-keycloak.env"
PF_PID=""

cleanup() {
  [[ -n "$PF_PID" ]] && kill "$PF_PID" 2>/dev/null || true
}
trap cleanup EXIT

run_pod() {
  local pod_name="$1"
  local image="$2"
  shift 2

  kubectl delete pod "$pod_name" -n gateway --ignore-not-found --wait=true >/dev/null
  kubectl run "$pod_name" --restart=Never --image="$image" -n gateway -- "$@" >/dev/null
  if ! kubectl wait pod/"$pod_name" -n gateway \
    --for=jsonpath='{.status.phase}'=Succeeded --timeout=90s >/dev/null; then
    kubectl logs "$pod_name" -n gateway >&2 || true
    kubectl delete pod "$pod_name" -n gateway --wait=false >/dev/null || true
    return 1
  fi
  kubectl logs "$pod_name" -n gateway
  kubectl delete pod "$pod_name" -n gateway --wait=false >/dev/null
}

[[ -r "$LOCAL_ENV" ]] || {
  echo "Falta $LOCAL_ENV" >&2
  exit 1
}
set -a
# shellcheck disable=SC1090
. "$LOCAL_ENV"
set +a

client_secret="$(kubectl get secret apisix-oidc -n gateway -o jsonpath='{.data.client-secret}' | base64 -d)"

echo "[1/5] Workloads"
kubectl rollout status deployment/apisix -n gateway --timeout=180s >/dev/null
kubectl rollout status deployment/keycloak -n auth --timeout=300s >/dev/null
kubectl rollout status deployment/postgrest -n datalake --timeout=180s >/dev/null

echo "[2/5] Discovery publico de Keycloak"
discovery="$(
  run_pod fase13-discovery-check curlimages/curl:8.12.1 \
    curl -fsS http://apisix-gateway/realms/dena/.well-known/openid-configuration
)"
grep -F '/realms/dena"' <<<"$discovery" >/dev/null

echo "[3/5] Rechazo sin token"
unauthorized="$(
  run_pod fase13-unauthorized-check curlimages/curl:8.12.1 \
    curl -sS -o /dev/null -w '%{http_code}' http://apisix-gateway/api
)"
grep -E "401|403" <<<"$unauthorized" >/dev/null

echo "[4/5] Token de testuser y API protegida"
kubectl port-forward -n auth svc/keycloak 18080:8080 --address 127.0.0.1 \
  >/tmp/fase13-keycloak-port-forward.log 2>&1 &
PF_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18080/realms/dena/.well-known/openid-configuration \
    >/dev/null 2>&1 && break
  sleep 1
done
token_json="$(curl -fsS -X POST \
  -H 'Host: 192.168.56.15:30080' \
  http://127.0.0.1:18080/realms/dena/protocol/openid-connect/token \
  --data-urlencode grant_type=password \
  --data-urlencode client_id=apisix-gateway \
  --data-urlencode client_secret="$client_secret" \
  --data-urlencode username=testuser \
  --data-urlencode password="$TF_VAR_testuser_password")"
access_token="$(sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p' <<<"$token_json")"
[[ -n "$access_token" ]] || {
  echo "No se obtuvo access token" >&2
  exit 1
}

api_output="$(
  run_pod fase13-api-check curlimages/curl:8.12.1 \
    curl -fsS -H "Authorization: Bearer $access_token" http://apisix-gateway/api
)"
grep -F '"swagger":"2.0"' <<<"$api_output" >/dev/null

echo "[5/5] RPC DENA protegido"
dena_output="$(
  run_pod fase13-dena-check curlimages/curl:8.12.1 \
    curl -fsS -X POST \
      -H "Authorization: Bearer $access_token" \
      -H "Content-Type: application/json" \
      --data '{"p_limit":2}' \
      http://apisix-gateway/dena/admin-files
)"
grep -F '"expediente_code"' <<<"$dena_output" >/dev/null

echo "Fase 13 validada: Keycloak publico, OIDC obligatorio y RPC DENA operativo."
