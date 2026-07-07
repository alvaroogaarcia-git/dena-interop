#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REALM="${DENA_RECOVERY_REALM:-piloto}"
USERNAME="${DENA_RECOVERY_USERNAME:-adminuser}"
ISSUED_BY="${DENA_RECOVERY_ISSUED_BY:-recovery-operator}"
RECOVERY_CODE="${DENA_RECOVERY_CODE:-}"

for bin in kubectl sha256sum; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $bin" >&2
    exit 1
  }
done

if [[ -z "$RECOVERY_CODE" ]]; then
  echo "Falta DENA_RECOVERY_CODE" >&2
  exit 1
fi

backup_code_hash="$(printf '%s' "$RECOVERY_CODE" | sha256sum | awk '{print $1}')"

kubectl rollout status statefulset/postgresql-datalake -n datalake --timeout=180s >/dev/null
kubectl rollout status deployment/keycloak -n auth --timeout=300s >/dev/null
pg_password="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
keycloak_admin_password="$(kubectl get secret keycloak-secret -n auth -o jsonpath='{.data.admin-password}' | base64 -d)"

kcadm() {
  kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh "$@" \
    --server http://localhost:8080 \
    --realm master \
    --user admin \
    --password "$keycloak_admin_password"
}

code_row="$(
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -v ON_ERROR_STOP=1 -U postgres -d datalake -Atc "
      WITH updated AS (
        UPDATE dena.recovery_backup_code
        SET status = 'used',
            used_at = now(),
            used_by = '$ISSUED_BY'
        WHERE realm = '$REALM'
          AND username = '$USERNAME'
          AND code_hash = '$backup_code_hash'
          AND status = 'issued'
        RETURNING id
      )
      SELECT id FROM updated;
    "
)"

if [[ -z "${code_row:-}" ]]; then
  echo "Codigo de respaldo invalido, agotado o no emitido para $REALM/$USERNAME." >&2
  exit 1
fi

kcadm set-password -r "$REALM" \
  --username "$USERNAME" \
  --new-password "$RECOVERY_CODE" \
  --temporary=true >/dev/null

kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$pg_password" \
  psql -v ON_ERROR_STOP=1 -U postgres -d datalake <<SQL
INSERT INTO dena.recovery_event (
  realm, username, recovery_backup_code_id, event_type, operator_username, details
) VALUES (
  '$REALM',
  '$USERNAME',
  $code_row,
  'backup_code_consumed',
  '$ISSUED_BY',
  jsonb_build_object('temporary_password_set', true)
);
SQL

echo "Codigo de respaldo consumido y password temporal aplicada a $REALM/$USERNAME."
echo "El usuario puede entrar una vez con ese codigo y registrar una nueva passkey."
