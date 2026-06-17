#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin helm

echo "Usando KUBECONFIG=$KUBECONFIG"

kubectl version --client >/dev/null
kubectl get nodes >/dev/null

echo
echo "[1/5] Nodo"
kubectl wait --for=condition=Ready node --all --timeout=60s >/dev/null
kubectl get nodes -o wide

echo
echo "[2/5] Namespaces base"
for ns in auth gateway monitoring datalake verticales; do
  kubectl get ns "$ns" >/dev/null
done
kubectl get ns auth gateway monitoring datalake verticales

echo
echo "[3/5] Releases Helm esperados"
helm list -A
for release in postgresql apisix monitoring loki tempo; do
  if ! helm list -A -q | grep -Fx "$release" >/dev/null; then
    echo "Falta release Helm: $release" >&2
    exit 1
  fi
done

echo
echo "[4/5] Workloads que deben estar sanos antes de Fase 8"
kubectl get deploy,statefulset,daemonset -n kube-system
kubectl get deploy,statefulset,daemonset -n auth
kubectl get deploy,statefulset,daemonset -n gateway
kubectl get deploy,statefulset,daemonset -n monitoring

not_ready="$(
  kubectl get deploy,statefulset,daemonset -A \
    -o custom-columns=KIND:.kind,NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.readyReplicas,DESIRED:.status.replicas \
    --no-headers \
  | awk '
      {
        ready = ($4 == "<none>" || $4 == "") ? 0 : $4
        desired = ($5 == "<none>" || $5 == "") ? 0 : $5
        if (ready != desired) {
          print
        }
      }
    '
)"
if [[ -n "$not_ready" ]]; then
  echo
  echo "Hay workloads no listos. No empieces la Fase 8 todavia." >&2
  echo "$not_ready" >&2
  echo
  echo "Recuperacion sugerida:"
  echo "  bash scripts/recover-fase7.sh"
  exit 2
fi

echo
echo "[5/5] Endpoints previos a Fase 8"
kubectl get svc -n monitoring monitoring-grafana loki tempo
kubectl get svc -n gateway apisix-gateway

echo
echo "Preflight OK. Puedes empezar Fase 8 con:"
echo "  helm install otel-collector open-telemetry/opentelemetry-collector -n monitoring --values helm-values/otel-collector-values.yaml"
