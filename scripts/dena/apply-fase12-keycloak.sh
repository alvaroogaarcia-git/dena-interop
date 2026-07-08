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
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
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
  testuser_password="${DENA_TESTUSER_PASSWORD:-Test1234!}"
  printf 'TF_VAR_testuser_password=%q\n' "$testuser_password" >"$LOCAL_ENV"
  chmod 600 "$LOCAL_ENV"
fi
if ! grep -q '^TF_VAR_adminuser_password=' "$LOCAL_ENV"; then
  adminuser_password="${DENA_ADMINUSER_PASSWORD:-Admin1234!}"
  printf 'TF_VAR_adminuser_password=%q\n' "$adminuser_password" >>"$LOCAL_ENV"
fi
if ! grep -q '^TF_VAR_recovery_operator_password=' "$LOCAL_ENV"; then
  recovery_operator_password="${DENA_RECOVERY_OPERATOR_PASSWORD:-$(openssl rand -base64 24)}"
  printf 'TF_VAR_recovery_operator_password=%q\n' "$recovery_operator_password" >>"$LOCAL_ENV"
fi

set -a
# shellcheck disable=SC1090
. "$LOCAL_ENV"
set +a

export TF_VAR_keycloak_admin_password
TF_VAR_keycloak_admin_password="$(kubectl get secret keycloak-secret -n auth -o jsonpath='{.data.admin-password}' | base64 -d)"
export TF_VAR_grafana_admin_password="${TF_VAR_grafana_admin_password:-unused-by-fase12}"

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
terraform -chdir="$TF_DIR" apply -auto-approve \
  -target=keycloak_realm.dena \
  -target=keycloak_openid_client.react_frontend \
  -target=keycloak_openid_client.apisix_gateway \
  -target=keycloak_role.reader \
  -target=keycloak_role.writer \
  -target=keycloak_role.admin \
  -target=keycloak_user.testuser \
  -target=keycloak_user_roles.testuser \
  -target=keycloak_user.adminuser \
  -target=keycloak_user_roles.adminuser \
  -target=keycloak_realm.piloto \
  -target=keycloak_openid_client.piloto_react_frontend \
  -target=keycloak_openid_client.piloto_apisix_gateway \
  -target=keycloak_role.piloto_reader \
  -target=keycloak_role.piloto_writer \
  -target=keycloak_role.piloto_admin \
  -target=keycloak_user.piloto_testuser \
  -target=keycloak_user_roles.piloto_testuser \
  -target=keycloak_user.piloto_adminuser \
  -target=keycloak_user_roles.piloto_adminuser

reconcile_keycloak_user() {
  local username="$1"
  local password="$2"
  local realm="${3:-piloto}"
  local user_id

  user_id="$(
    kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh get users \
      -r "$realm" \
      -q username="$username" \
      --fields id \
      --format csv \
      --noquotes \
      --server http://localhost:8080 \
      --realm master \
      --user admin \
      --password "$TF_VAR_keycloak_admin_password" | tail -n 1 | tr -d '\r'
  )"
  [[ -n "$user_id" ]] || {
    echo "No se encontro el usuario $username en el realm $realm" >&2
    exit 1
  }

  kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh set-password \
    -r "$realm" \
    --username "$username" \
    --new-password "$password" \
    --temporary=false \
    --server http://localhost:8080 \
    --realm master \
    --user admin \
    --password "$TF_VAR_keycloak_admin_password" >/dev/null

  kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh update "users/$user_id" \
    -r "$realm" \
    -s 'requiredActions=[]' \
    --server http://localhost:8080 \
    --realm master \
    --user admin \
    --password "$TF_VAR_keycloak_admin_password" >/dev/null
}

reconcile_keycloak_user testuser "$TF_VAR_testuser_password"
reconcile_keycloak_user adminuser "$TF_VAR_adminuser_password"

bash "$REPO_ROOT/scripts/dena/apply-recovery-operator.sh"

client_secret="$(terraform -chdir="$TF_DIR" output -raw apisix_client_secret)"
kubectl create secret generic apisix-oidc -n gateway \
  --from-literal=client-id=apisix-gateway \
  --from-literal=client-secret="$client_secret" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null

echo "Fase 12 aplicada: realm piloto, clientes, roles y testuser gestionados por Terraform."
echo "Passwords de testuser, adminuser y recovery-operator guardadas localmente en .local/fase12-keycloak.env."
