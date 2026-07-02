#!/usr/bin/env bash

set -euo pipefail

NODE_IP="${DENA_NODE_IP:-192.168.56.15}"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

echo "KUBECONFIG=$KUBECONFIG"
echo
echo "Nodos:"
kubectl get nodes -o wide
echo
echo "Workloads principales:"
kubectl get deploy,statefulset -A \
  -o custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name,READY:.status.readyReplicas,DESIRED:.status.replicas
echo
echo "Servicios demo:"
cat <<EOF
SPA:        http://${NODE_IP}:30080/
Grafana:    http://${NODE_IP}:31803/login
Mathesar:   http://${NODE_IP}:30900
Portainer:  https://${NODE_IP}:30779
EOF
echo
echo "Verificacion completa:"
echo "  bash scripts/verify-stack.sh"
