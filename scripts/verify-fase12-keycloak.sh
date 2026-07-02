#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_ENV="$REPO_ROOT/.local/fase12-keycloak.env"
PF_PID=""

cleanup() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

[[ -r "$LOCAL_ENV" ]] || {
  echo "Falta $LOCAL_ENV; ejecuta apply-fase12-keycloak.sh" >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
. "$LOCAL_ENV"
set +a
: "${TF_VAR_testuser_password:?Falta TF_VAR_testuser_password en $LOCAL_ENV}"

client_secret="$(kubectl get secret apisix-oidc -n gateway -o jsonpath='{.data.client-secret}' | base64 -d)"

kubectl port-forward -n auth svc/keycloak 18080:8080 --address 127.0.0.1 \
  >/tmp/fase12-keycloak-verify-port-forward.log 2>&1 &
PF_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18080/realms/piloto/.well-known/openid-configuration \
    >/dev/null 2>&1 && break
  sleep 1
done

token_response="$(curl -fsS -X POST \
  http://127.0.0.1:18080/realms/piloto/protocol/openid-connect/token \
  --data-urlencode grant_type=password \
  --data-urlencode client_id=apisix-gateway \
  --data-urlencode client_secret="$client_secret" \
  --data-urlencode username=testuser \
  --data-urlencode password="$TF_VAR_testuser_password")"

grep -F '"access_token"' <<<"$token_response" >/dev/null
kubectl get secret apisix-oidc -n gateway >/dev/null
echo "Fase 12 validada: discovery OIDC y token de testuser operativos."
