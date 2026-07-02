#!/usr/bin/env bash

set -euo pipefail

poweroff=false
if [[ "${1:-}" == "--poweroff" ]]; then
  poweroff=true
fi

if command -v systemctl >/dev/null 2>&1; then
  echo "Parando k3s..."
  systemctl stop k3s
fi

if "$poweroff"; then
  echo "Apagando VM..."
  poweroff
fi
