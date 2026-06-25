#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

PF_PID=""

cleanup() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

for bin in kubectl curl grep; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $bin" >&2
    exit 1
  }
done

grafana_user="$(kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-user}' | base64 -d)"
grafana_password="$(kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d)"
auth="$grafana_user:$grafana_password"

kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=180s >/dev/null
kubectl port-forward -n monitoring svc/monitoring-grafana 13000:80 --address 127.0.0.1 \
  >/tmp/fase14-grafana-verify-port-forward.log 2>&1 &
PF_PID=$!

for _ in $(seq 1 60); do
  curl -fsS -u "$auth" http://127.0.0.1:13000/api/health >/dev/null 2>&1 && break
  sleep 1
done

echo "[1/4] Salud de Grafana"
health="$(curl -fsS -u "$auth" http://127.0.0.1:13000/api/health)"
grep -E '"database"[[:space:]]*:[[:space:]]*"ok"' <<<"$health" >/dev/null

echo "[2/4] Datasources"
for uid in prometheus loki tempo; do
  datasource="$(curl -fsS -u "$auth" "http://127.0.0.1:13000/api/datasources/uid/$uid")"
  grep -F "\"uid\":\"$uid\"" <<<"$datasource" >/dev/null
done

echo "[3/4] Carpeta DENA"
folder="$(curl -fsS -u "$auth" http://127.0.0.1:13000/api/folders/dena)"
grep -F '"uid":"dena"' <<<"$folder" >/dev/null

echo "[4/4] Dashboards DENA"
for uid in dena-stack-overview dena-postgresql-overview; do
  dashboard="$(curl -fsS -u "$auth" "http://127.0.0.1:13000/api/dashboards/uid/$uid")"
  grep -F "\"uid\":\"$uid\"" <<<"$dashboard" >/dev/null
done

echo "Fase 14 validada: Grafana gestionado por Terraform con datasources y dashboards DENA."
