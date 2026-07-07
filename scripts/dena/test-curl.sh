#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${DENA_GATEWAY_URL:-http://192.168.56.15:30080}"
USERNAME="${DENA_TEST_USERNAME:-testuser}"
PASSWORD="${DENA_TEST_PASSWORD:-Test1234!}"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCAL_ENV="$REPO_ROOT/.local/fase12-keycloak.env"
PF_PID=""

ok=0
ko=0

cleanup() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

check_status() {
  local name="$1"
  local expected="$2"
  shift 2
  local status
  status="$("$@" -o /tmp/dena-test-curl.out -w '%{http_code}' 2>/tmp/dena-test-curl.err || true)"
  if [[ "$status" == "$expected" ]]; then
    echo "OK  $name ($status)"
    ok=$((ok + 1))
  else
    echo "KO  $name (esperado $expected, recibido ${status:-sin respuesta})"
    cat /tmp/dena-test-curl.err >&2 || true
    ko=$((ko + 1))
  fi
}

check_status "discovery OIDC" 200 \
  curl -sS --max-time 10 "$BASE_URL/realms/piloto/.well-known/openid-configuration"

check_status "API sin token" 401 \
  curl -sS --max-time 10 "$BASE_URL/api/"

if [[ -r "$LOCAL_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$LOCAL_ENV"
  set +a
  PASSWORD="${DENA_TEST_PASSWORD:-${TF_VAR_testuser_password:-$PASSWORD}}"
fi

client_secret="$(kubectl get secret apisix-oidc -n gateway -o jsonpath='{.data.client-secret}' | base64 -d)"
kubectl port-forward -n auth svc/keycloak 18080:8080 --address 127.0.0.1 \
  >/tmp/dena-test-curl-keycloak-port-forward.log 2>&1 &
PF_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18080/realms/piloto/.well-known/openid-configuration \
    >/dev/null 2>&1 && break
  sleep 1
done

token_json="$(
  curl -fsS --max-time 10 -X POST \
    -H 'Host: 192.168.56.15:30080' \
    "http://127.0.0.1:18080/realms/piloto/protocol/openid-connect/token" \
    --data-urlencode grant_type=password \
    --data-urlencode client_id=apisix-gateway \
    --data-urlencode client_secret="$client_secret" \
    --data-urlencode username="$USERNAME" \
    --data-urlencode password="$PASSWORD"
)"
token="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])' <<<"$token_json")"

check_status "API con token" 200 \
  curl -sS --max-time 10 -H "Authorization: Bearer $token" "$BASE_URL/api/"

check_status "RPC DENA" 200 \
  curl -sS --max-time 10 -X POST \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data '{"p_limit":2}' \
    "$BASE_URL/dena/admin-files"

check_status "SPA cliente" 200 \
  curl -sS --max-time 10 "$BASE_URL/"

check_status "Consola admin" 200 \
  curl -sS --max-time 10 "$BASE_URL/dena/admin-console"

echo "$ok OK · $ko KO"
[[ "$ko" -eq 0 ]]
