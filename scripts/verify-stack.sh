#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[1/8] Estado Kubernetes"
kubectl get nodes
kubectl get pods -A

echo
echo "[2/8] Workloads core"
kubectl rollout status deployment/keycloak -n auth --timeout=300s
kubectl rollout status deployment/apisix -n gateway --timeout=180s
kubectl rollout status deployment/postgrest -n datalake --timeout=180s
kubectl rollout status deployment/nifi -n datalake --timeout=300s
kubectl rollout status deployment/mathesar -n verticales --timeout=240s
kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=180s
kubectl rollout status deployment/dena-interop-spa -n app --timeout=180s
kubectl rollout status deployment/dena-admin-console -n app --timeout=180s

echo
echo "[3/8] Verificaciones por fase"
bash "$REPO_ROOT/scripts/verify-fase10.sh"
bash "$REPO_ROOT/scripts/verify-fase11.sh"
bash "$REPO_ROOT/scripts/verify-fase11b.sh"
bash "$REPO_ROOT/scripts/verify-fase15-nifi.sh"
bash "$REPO_ROOT/scripts/verify-fase12-keycloak.sh"
bash "$REPO_ROOT/scripts/verify-fase13.sh"
bash "$REPO_ROOT/scripts/verify-fase14.sh"
bash "$REPO_ROOT/scripts/verify-fase15.sh"

echo
echo "[4/8] Cliente SPA"
curl -fsS http://192.168.56.15:30080/ >/dev/null

echo
echo "[5/8] Portainer"
kubectl rollout status deployment/portainer -n portainer --timeout=180s
curl -kfsS https://192.168.56.15:30779/ >/dev/null
bash "$REPO_ROOT/scripts/dena/init-portainer.sh"

echo
echo "[6/8] API DENA"
bash "$REPO_ROOT/scripts/dena/test-curl.sh"

echo
echo "[7/8] Helm"
helm list -A

echo
echo "[8/8] Stack validado."
