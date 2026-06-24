#!/usr/bin/env bash

set -euo pipefail

REMOTE_HOST="${DENA_SSH_HOST:-dena}"

command -v ssh >/dev/null 2>&1 || {
  echo "Falta binario requerido: ssh" >&2
  exit 1
}

ssh "$REMOTE_HOST" sudo bash -s <<'REMOTE'
set -euo pipefail

dietpi-update
apt-get update
apt-get install -y curl wget git open-iscsi nfs-common iptables

modprobe overlay
modprobe br_netfilter

cat >/etc/modules-load.d/k3s.conf <<'EOF'
overlay
br_netfilter
EOF

cat >/etc/sysctl.d/99-k3s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF
sysctl --system

swapoff -a
sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab
REMOTE

echo "DietPi preparado para la instalacion inicial de k3s."
echo "En el nodo de 4 GiB, la optimizacion posterior puede reactivar swap controlada."
