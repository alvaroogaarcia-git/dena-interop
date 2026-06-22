#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

NIFI_BASE_URL="${NIFI_BASE_URL:-https://localhost:8443}"
NIFI_USERNAME="${NIFI_USERNAME:-admin}"
NIFI_PASSWORD="${NIFI_PASSWORD:-$(kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-password}' | base64 -d)}"
GROUP_NAME="${GROUP_NAME:-Fase 12 - JDBC incremental}"
OUTPUT_DIR="${OUTPUT_DIR:-/opt/nifi/nifi-current/extensions/fase12-output}"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

json_find_group_id() {
  local group_name="$1"

  python3 -c 'import json,sys; group_name=sys.argv[1]; data=json.load(sys.stdin)
for group in data["processGroupFlow"]["flow"].get("processGroups", []):
    component = group.get("component", {})
    if component.get("name") == group_name:
        print(component.get("id") or group.get("id") or "")
        raise SystemExit(0)
raise SystemExit(1)' "$group_name"
}

require_bin kubectl
require_bin curl
require_bin python3

echo "Usando KUBECONFIG=$KUBECONFIG"

TOKEN="$(
  curl -skf --max-time 30 \
    -X POST \
    --data-urlencode "username=$NIFI_USERNAME" \
    --data-urlencode "password=$NIFI_PASSWORD" \
    "$NIFI_BASE_URL/nifi-api/access/token"
)"

group_id="$(
  curl -skf --max-time 30 \
    -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/root" | json_find_group_id "$GROUP_NAME"
)"

echo "[1/4] Grupo de proceso"
echo "$GROUP_NAME => $group_id"

echo
echo "[2/4] Procesadores"
curl -skf --max-time 30 \
  -H "Authorization: Bearer $TOKEN" \
  "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id" | \
  python3 -c 'import json,sys
data = json.load(sys.stdin)
processors = data["processGroupFlow"]["flow"].get("processors", [])
expected = {"Query Verticales Incremental", "Stamp Output Filename", "Persist Fase 12 Output"}
found = {proc.get("component", {}).get("name") for proc in processors}
missing = sorted(expected - found)
for name in sorted(found & expected):
    print(name)
if missing:
    raise SystemExit("Faltan procesadores: " + ", ".join(missing))'

echo
echo "[3/4] Servicio de salida"
kubectl exec -n datalake "$(kubectl get pod -n datalake -l app=nifi -o jsonpath='{.items[0].metadata.name}')" -c nifi -- test -d "$OUTPUT_DIR"
kubectl exec -n datalake "$(kubectl get pod -n datalake -l app=nifi -o jsonpath='{.items[0].metadata.name}')" -c nifi -- sh -c "find '$OUTPUT_DIR' -maxdepth 1 -type f | head -n 5"

echo
echo "[4/4] Driver JDBC"
kubectl exec -n datalake "$(kubectl get pod -n datalake -l app=nifi -o jsonpath='{.items[0].metadata.name}')" -c nifi -- test -f /opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar
echo "Driver JDBC presente."
