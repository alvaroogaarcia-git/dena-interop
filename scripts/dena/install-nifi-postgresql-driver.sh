#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

JDBC_VERSION="42.7.4"
JDBC_JAR="postgresql-${JDBC_VERSION}.jar"
JDBC_URL="https://repo1.maven.org/maven2/org/postgresql/postgresql/${JDBC_VERSION}/${JDBC_JAR}"
TMP_JAR="/tmp/${JDBC_JAR}"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin curl

echo "Usando KUBECONFIG=$KUBECONFIG"

pod_name="$(kubectl get pod -n datalake -l app=nifi -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$pod_name" ]]; then
  echo "No se ha encontrado el pod de NiFi en datalake" >&2
  exit 1
fi

curl -fsSL "$JDBC_URL" -o "$TMP_JAR"
kubectl cp "$TMP_JAR" "datalake/${pod_name}:/opt/nifi/nifi-current/extensions/${JDBC_JAR}" -c nifi
kubectl exec -n datalake "$pod_name" -c nifi -- test -f "/opt/nifi/nifi-current/extensions/${JDBC_JAR}"

echo "Driver copiado en /opt/nifi/nifi-current/extensions/${JDBC_JAR}"
