#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NAMESPACE="datos-externos"
RELEASE="datos-externos-postgresql"
DATABASE="datos_externos"
ENV_FILE="$REPO_ROOT/.local/fase19-datos-externos.env"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin helm
require_bin openssl
require_bin base64

mkdir -p "$REPO_ROOT/.local"

if [[ -r "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

if [[ -z "${DATOS_EXTERNOS_POSTGRES_PASSWORD:-}" ]]; then
  if kubectl get secret -n "$NAMESPACE" "$RELEASE" >/dev/null 2>&1; then
    DATOS_EXTERNOS_POSTGRES_PASSWORD="$(
      kubectl get secret -n "$NAMESPACE" "$RELEASE" -o jsonpath='{.data.postgres-password}' | base64 -d
    )"
  else
    DATOS_EXTERNOS_POSTGRES_PASSWORD="$(openssl rand -base64 24 | tr -d '\n')"
  fi
  umask 077
  printf "DATOS_EXTERNOS_POSTGRES_PASSWORD='%s'\n" "$DATOS_EXTERNOS_POSTGRES_PASSWORD" >"$ENV_FILE"
fi

echo "Usando KUBECONFIG=$KUBECONFIG"
echo "Aplicando namespace aislado $NAMESPACE"
kubectl apply -f "$REPO_ROOT/k8s-manifests/datos-externos/namespace.yaml"

echo "Instalando/actualizando release Helm $RELEASE"
helm upgrade --install "$RELEASE" bitnami/postgresql \
  --namespace "$NAMESPACE" \
  --version 18.7.5 \
  --values "$REPO_ROOT/helm-values/datos-externos-postgresql-values.yaml" \
  --set auth.postgresPassword="$DATOS_EXTERNOS_POSTGRES_PASSWORD"

kubectl rollout status "statefulset/$RELEASE" -n "$NAMESPACE" --timeout=240s >/dev/null

mapfile -t sql_files < <(find "$REPO_ROOT/sql/datos-externos" -maxdepth 1 -type f -name '*.sql' | sort)

if (( ${#sql_files[@]} == 0 )); then
  echo "No hay SQL en $REPO_ROOT/sql/datos-externos" >&2
  exit 1
fi

for sql_file in "${sql_files[@]}"; do
  if [[ ! -r "$sql_file" ]]; then
    echo "No se puede leer $sql_file" >&2
    exit 1
  fi

  echo "Aplicando $(basename "$sql_file")"
  kubectl exec -i -n "$NAMESPACE" "$RELEASE-0" -- \
    env PGPASSWORD="$DATOS_EXTERNOS_POSTGRES_PASSWORD" \
    psql -v ON_ERROR_STOP=1 -U postgres -d "$DATABASE" <"$sql_file"
done

echo "Fase 19 datos externos aplicada en namespace $NAMESPACE."
