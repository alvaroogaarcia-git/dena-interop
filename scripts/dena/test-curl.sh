#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${DENA_GATEWAY_URL:-http://192.168.56.15:30080}"
USERNAME="${DENA_TEST_USERNAME:-testuser}"
PASSWORD="${DENA_TEST_PASSWORD:-Test1234!}"

ok=0
ko=0

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

token_json="$(
  curl -fsS --max-time 10 -X POST \
    "$BASE_URL/realms/piloto/protocol/openid-connect/token" \
    --data-urlencode client_id=react-frontend \
    --data-urlencode grant_type=password \
    --data-urlencode username="$USERNAME" \
    --data-urlencode password="$PASSWORD" \
    --data-urlencode scope=openid
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

echo "$ok OK · $ko KO"
[[ "$ko" -eq 0 ]]
