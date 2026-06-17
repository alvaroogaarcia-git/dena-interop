#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

restart_if_present() {
  local kind="$1"
  local name="$2"
  local namespace="$3"

  if kubectl get "$kind" "$name" -n "$namespace" >/dev/null 2>&1; then
    kubectl rollout restart "$kind/$name" -n "$namespace"
  fi
}

echo "Usando KUBECONFIG=$KUBECONFIG"
echo "Reiniciando workloads de Fase 7 y componentes base que ahora estan degradados..."

restart_if_present deployment coredns kube-system
restart_if_present deployment metrics-server kube-system

restart_if_present deployment keycloak auth
restart_if_present statefulset postgresql auth

restart_if_present deployment apisix gateway
restart_if_present statefulset apisix-etcd gateway

restart_if_present deployment monitoring-grafana monitoring
restart_if_present deployment monitoring-kube-prometheus-operator monitoring
restart_if_present deployment monitoring-kube-state-metrics monitoring
restart_if_present daemonset monitoring-prometheus-node-exporter monitoring
restart_if_present statefulset prometheus-monitoring-kube-prometheus-prometheus monitoring
restart_if_present statefulset loki monitoring
restart_if_present statefulset tempo monitoring

echo
echo "Esperando readiness basico..."
kubectl rollout status deployment/coredns -n kube-system --timeout=180s || true
kubectl rollout status deployment/metrics-server -n kube-system --timeout=180s || true
kubectl rollout status deployment/keycloak -n auth --timeout=300s || true
kubectl rollout status deployment/apisix -n gateway --timeout=300s || true
kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=300s || true
kubectl rollout status deployment/monitoring-kube-prometheus-operator -n monitoring --timeout=300s || true
kubectl rollout status deployment/monitoring-kube-state-metrics -n monitoring --timeout=300s || true
kubectl rollout status daemonset/monitoring-prometheus-node-exporter -n monitoring --timeout=300s || true
kubectl rollout status statefulset/loki -n monitoring --timeout=300s || true
kubectl rollout status statefulset/tempo -n monitoring --timeout=300s || true

echo
kubectl get pods -A -o wide
echo
echo "Si sigue habiendo CreateContainerError tras esto, el siguiente paso operativo es reiniciar k3s en el nodo DietPi."
