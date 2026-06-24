#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"
LOCAL_ENV="$REPO_ROOT/.local/fase12-keycloak.env"
PF_PID=""

cleanup() {
  [[ -n "$PF_PID" ]] && kill "$PF_PID" 2>/dev/null || true
}
trap cleanup EXIT

for bin in kubectl terraform openssl curl; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $bin" >&2
    exit 1
  }
done

mkdir -p "$REPO_ROOT/.local"
if [[ ! -f "$LOCAL_ENV" ]]; then
  testuser_password="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)"
  printf 'TF_VAR_testuser_password=%q\n' "$testuser_password" >"$LOCAL_ENV"
  chmod 600 "$LOCAL_ENV"
fi

set -a
# shellcheck disable=SC1090
. "$LOCAL_ENV"
set +a

export TF_VAR_keycloak_admin_password
TF_VAR_keycloak_admin_password="$(kubectl get secret keycloak-secret -n auth -o jsonpath='{.data.admin-password}' | base64 -d)"

kubectl rollout status deployment/keycloak -n auth --timeout=300s >/dev/null
kubectl port-forward -n auth svc/keycloak 18080:8080 --address 127.0.0.1 \
  >/tmp/fase12-keycloak-port-forward.log 2>&1 &
PF_PID=$!

for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18080/realms/master/.well-known/openid-configuration \
    >/dev/null 2>&1 && break
  sleep 1
done
curl -fsS http://127.0.0.1:18080/realms/master/.well-known/openid-configuration >/dev/null

terraform -chdir="$TF_DIR" init
terraform -chdir="$TF_DIR" apply -auto-approve

client_secret="$(terraform -chdir="$TF_DIR" output -raw apisix_client_secret)"
kubectl create secret generic apisix-oidc -n gateway \
  --from-literal=client-id=apisix-gateway \
  --from-literal=client-secret="$client_secret" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null

echo "Fase 12 aplicada: realm dena, clientes, roles y testuser gestionados por Terraform."
echo "Password de testuser guardada localmente en .local/fase12-keycloak.env."
