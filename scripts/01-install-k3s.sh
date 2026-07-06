#!/usr/bin/env bash

set -euo pipefail

REMOTE_HOST="${DENA_SSH_HOST:-dena}"
TLS_SAN="${DENA_NODE_IP:-192.168.56.15}"

command -v ssh >/dev/null 2>&1 || {
  echo "Falta binario requerido: ssh" >&2
  exit 1
}

if ssh "$REMOTE_HOST" sudo systemctl is-active --quiet k3s; then
  ssh "$REMOTE_HOST" sudo k3s kubectl wait --for=condition=Ready node --all --timeout=120s
  echo "k3s ya estaba instalado y el nodo esta Ready."
  exit 0
fi

ssh "$REMOTE_HOST" sudo bash -s -- "$TLS_SAN" <<'REMOTE'
set -euo pipefail
tls_san="$1"

if grep -q '^SOFTWARE_K3S_EXEC=' /boot/dietpi.txt; then
  sed -i 's/^SOFTWARE_K3S_EXEC=.*/SOFTWARE_K3S_EXEC=server/' /boot/dietpi.txt
else
  echo 'SOFTWARE_K3S_EXEC=server' >>/boot/dietpi.txt
fi

cat >/boot/dietpi-k3s.yaml <<EOF
write-kubeconfig-mode: "0644"
disable:
  - traefik
  - servicelb
tls-san:
  - "$tls_san"
node-ip: "$tls_san"
EOF

/boot/dietpi/dietpi-software install 193
KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl wait \
  --for=condition=Ready node --all --timeout=120s
REMOTE

echo "k3s instalado mediante dietpi-software ID 193."
