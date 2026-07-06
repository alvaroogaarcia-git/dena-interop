#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

echo "Esperando nodo Ready..."
kubectl wait --for=condition=Ready node --all --timeout=180s

deployments=(
  "auth/keycloak"
  "gateway/apisix"
  "datalake/postgrest"
  "datalake/nifi"
  "verticales/mathesar"
  "monitoring/monitoring-grafana"
  "monitoring/monitoring-kube-prometheus-operator"
  "app/dena-interop-spa"
  "app/dena-admin-console"
  "portainer/portainer"
)

for item in "${deployments[@]}"; do
  namespace="${item%%/*}"
  name="${item##*/}"
  if kubectl get deployment "$name" -n "$namespace" >/dev/null 2>&1; then
    kubectl rollout status deployment/"$name" -n "$namespace" --timeout=300s
  fi
done

statefulsets=(
  "auth/postgresql"
  "gateway/apisix-etcd"
  "datalake/postgresql-datalake"
  "verticales/postgresql-verticales"
  "monitoring/loki"
  "monitoring/tempo"
  "monitoring/prometheus-monitoring-kube-prometheus-prometheus"
)

for item in "${statefulsets[@]}"; do
  namespace="${item%%/*}"
  name="${item##*/}"
  if kubectl get statefulset "$name" -n "$namespace" >/dev/null 2>&1; then
    kubectl rollout status statefulset/"$name" -n "$namespace" --timeout=300s
  fi
done

kubectl get pods -A
