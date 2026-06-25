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

for bin in kubectl helm terraform curl; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $bin" >&2
    exit 1
  }
done

if [[ -r "$LOCAL_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$LOCAL_ENV"
  set +a
fi

export TF_VAR_keycloak_admin_password
TF_VAR_keycloak_admin_password="$(
  kubectl get secret keycloak-secret -n auth -o jsonpath='{.data.admin-password}' | base64 -d
)"
export TF_VAR_testuser_password="${TF_VAR_testuser_password:-unused-by-fase14}"

export TF_VAR_grafana_admin_username
TF_VAR_grafana_admin_username="$(
  kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-user}' | base64 -d
)"
export TF_VAR_grafana_admin_password
TF_VAR_grafana_admin_password="$(
  kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
)"

helm upgrade monitoring prometheus-community/kube-prometheus-stack -n monitoring \
  --values "$REPO_ROOT/helm-values/monitoring-values.yaml" >/dev/null
kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=180s >/dev/null
kubectl port-forward -n monitoring svc/monitoring-grafana 13000:80 --address 127.0.0.1 \
  >/tmp/fase14-grafana-port-forward.log 2>&1 &
PF_PID=$!

for _ in $(seq 1 60); do
  curl -fsS -u "$TF_VAR_grafana_admin_username:$TF_VAR_grafana_admin_password" \
    http://127.0.0.1:13000/api/health >/dev/null 2>&1 && break
  sleep 1
done
curl -fsS -u "$TF_VAR_grafana_admin_username:$TF_VAR_grafana_admin_password" \
  http://127.0.0.1:13000/api/health >/dev/null

terraform -chdir="$TF_DIR" init

import_if_missing() {
  local resource="$1"
  local id="$2"

  if terraform -chdir="$TF_DIR" state show "$resource" >/dev/null 2>&1; then
    return 0
  fi

  terraform -chdir="$TF_DIR" import "$resource" "$id" >/dev/null 2>&1 || {
    echo "No se pudo importar $resource con id $id; se creara si no existe."
  }
}

import_if_missing grafana_data_source.prometheus prometheus
import_if_missing grafana_data_source.loki loki
import_if_missing grafana_data_source.tempo tempo
import_if_missing grafana_folder.dena dena
import_if_missing grafana_dashboard.dena_stack_overview dena-stack-overview
import_if_missing grafana_dashboard.dena_postgresql_overview dena-postgresql-overview

terraform -chdir="$TF_DIR" apply -auto-approve \
  -target=grafana_data_source.prometheus \
  -target=grafana_data_source.loki \
  -target=grafana_data_source.tempo \
  -target=grafana_folder.dena \
  -target=grafana_dashboard.dena_stack_overview \
  -target=grafana_dashboard.dena_postgresql_overview

echo "Fase 14 aplicada: datasources, carpeta y dashboards de Grafana gestionados por Terraform."
