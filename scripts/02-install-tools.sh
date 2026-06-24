#!/usr/bin/env bash

set -euo pipefail

missing=()
for bin in kubectl helm terraform; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done

if ((${#missing[@]} > 0)); then
  echo "Faltan herramientas locales: ${missing[*]}" >&2
  echo "Instalalas antes de continuar; este script no descarga binarios sin version fijada." >&2
  exit 1
fi

helm repo add bitnami https://repo.broadcom.com/bitnami-files --force-update
helm repo add apiseven https://apache.github.io/apisix-helm-chart --force-update
helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
helm repo update

kubectl version --client
helm version
terraform version
