#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCAL_ENV="$REPO_ROOT/.local/fase12-keycloak.env"
REALM="${DENA_RECOVERY_REALM:-piloto}"
USERNAME="${DENA_RECOVERY_USERNAME:-recovery-operator}"

for bin in kubectl openssl; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $bin" >&2
    exit 1
  }
done

mkdir -p "$REPO_ROOT/.local"
if [[ ! -f "$LOCAL_ENV" ]]; then
  touch "$LOCAL_ENV"
  chmod 600 "$LOCAL_ENV"
fi
if ! grep -q '^TF_VAR_recovery_operator_password=' "$LOCAL_ENV"; then
  recovery_operator_password="${DENA_RECOVERY_OPERATOR_PASSWORD:-$(openssl rand -base64 24)}"
  printf 'TF_VAR_recovery_operator_password=%q\n' "$recovery_operator_password" >>"$LOCAL_ENV"
fi

set -a
# shellcheck disable=SC1090
. "$LOCAL_ENV"
set +a

: "${TF_VAR_recovery_operator_password:?Falta TF_VAR_recovery_operator_password en $LOCAL_ENV}"

KEYCLOAK_ADMIN_PASSWORD="$(
  kubectl get secret keycloak-secret -n auth -o jsonpath='{.data.admin-password}' | base64 -d
)"

kcadm() {
  kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh "$@" \
    --server http://localhost:8080 \
    --realm master \
    --user admin \
    --password "$KEYCLOAK_ADMIN_PASSWORD"
}

kubectl rollout status deployment/keycloak -n auth --timeout=300s >/dev/null

user_id="$(kcadm get users -r "$REALM" -q username="$USERNAME" --fields id --format csv --noquotes | tail -n 1 | tr -d '\r')"
if [[ -z "$user_id" || "$user_id" == "Logging into "* ]]; then
  kcadm create users -r "$REALM" \
    -s username="$USERNAME" \
    -s enabled=true \
    -s email="$USERNAME@dena.local" \
    -s emailVerified=true \
    -s firstName=Recovery \
    -s lastName=Operator >/dev/null
fi

kcadm set-password -r "$REALM" \
  --username "$USERNAME" \
  --new-password "$TF_VAR_recovery_operator_password" \
  --temporary=false >/dev/null

kcadm add-roles -r "$REALM" \
  --uusername "$USERNAME" \
  --cclientid realm-management \
  --rolename view-users \
  --rolename query-users \
  --rolename manage-users >/dev/null

echo "Operador de recuperacion creado/actualizado en realm $REALM: $USERNAME"
echo "Password guardada localmente en $LOCAL_ENV como TF_VAR_recovery_operator_password."
