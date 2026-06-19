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

echo "Usando KUBECONFIG=$KUBECONFIG"

echo
echo "[1/5] Workloads de Fase 11"
kubectl get deployment nifi -n datalake >/dev/null
kubectl get service nifi -n datalake >/dev/null
kubectl get pvc nifi-extensions -n datalake >/dev/null
kubectl rollout status deployment/nifi -n datalake --timeout=300s >/dev/null
kubectl get pods,svc,pvc -n datalake -l app=nifi -o wide
kubectl get pvc nifi-extensions -n datalake

echo
echo "[2/5] Secret de single-user"
kubectl get secret nifi-secret -n datalake >/dev/null
kubectl get secret nifi-secret -n datalake -o jsonpath='{.data.single-user-username}' | base64 -d
echo
kubectl get secret nifi-secret -n datalake -o jsonpath='{.data.single-user-password}' | base64 -d | wc -c | awk '{print "Password length: " $1}'

echo
echo "[3/5] Endpoint HTTPS interno"
https_output="$(
  kubectl run nifi-check \
    --rm -i \
    --restart=Never \
    --image=nginx:alpine \
    -n datalake \
    -- wget --server-response --no-check-certificate -O- \
    --header='Host: localhost:8443' \
    https://nifi.datalake.svc.cluster.local:8443/nifi/ 2>&1
)"
printf '%s\n' "$https_output"
grep -F "HTTP/1.1 200 OK" <<<"$https_output" >/dev/null

echo
echo "[4/5] Logs recientes"
kubectl logs -n datalake deploy/nifi --tail=40

echo
echo "[5/5] Cierre de fase"
echo "Acceso esperado por operador: kubectl port-forward -n datalake svc/nifi 8443:8443"
echo "La UI debe abrir en https://localhost:8443/nifi"
