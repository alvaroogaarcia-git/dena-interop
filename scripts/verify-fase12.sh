#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

NIFI_LOCAL_PORT="${NIFI_LOCAL_PORT:-8443}"
NIFI_BASE_URL="${NIFI_BASE_URL:-https://localhost:$NIFI_LOCAL_PORT}"
NIFI_USERNAME="${NIFI_USERNAME:-$(kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-username}' | base64 -d)}"
NIFI_PASSWORD="${NIFI_PASSWORD:-$(kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-password}' | base64 -d)}"
GROUP_NAME="${GROUP_NAME:-Fase 12 - JDBC incremental}"
OUTPUT_DIR="${OUTPUT_DIR:-/opt/nifi/nifi-current/extensions/fase12-output}"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

PORT_FORWARD_PID=""

cleanup() {
  if [[ -n "$PORT_FORWARD_PID" ]]; then
    kill "$PORT_FORWARD_PID" 2>/dev/null || true
    wait "$PORT_FORWARD_PID" 2>/dev/null || true
  fi
}

start_port_forward() {
  if curl -sk --max-time 2 "$NIFI_BASE_URL/nifi-api/access/config" >/dev/null; then
    return
  fi

  echo "Abriendo acceso local a NiFi en localhost:$NIFI_LOCAL_PORT"
  kubectl port-forward -n datalake svc/nifi "$NIFI_LOCAL_PORT:8443" \
    --address 127.0.0.1 >/tmp/fase12-nifi-port-forward.log 2>&1 &
  PORT_FORWARD_PID=$!
  trap cleanup EXIT

  for _ in $(seq 1 60); do
    if curl -sk --max-time 2 "$NIFI_BASE_URL/nifi-api/access/config" >/dev/null; then
      return
    fi
    sleep 2
  done

  echo "NiFi no ha respondido a tiempo" >&2
  exit 1
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

get_nifi_pod() {
  kubectl get pod -n datalake -l app=nifi \
    --field-selector=status.phase=Running \
    -o jsonpath='{.items[0].metadata.name}'
}

echo "Usando KUBECONFIG=$KUBECONFIG"
start_port_forward

nifi_pod="$(get_nifi_pod)"
if [[ -z "$nifi_pod" ]]; then
  echo "No se ha encontrado un pod Running de NiFi en datalake" >&2
  exit 1
fi

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

echo "[1/5] Grupo de proceso"
echo "$GROUP_NAME => $group_id"

echo
echo "[2/5] Procesadores"
curl -skf --max-time 30 \
  -H "Authorization: Bearer $TOKEN" \
  "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id" | \
  python3 -c 'import json,sys
data = json.load(sys.stdin)
processors = data["processGroupFlow"]["flow"].get("processors", [])
expected = {"Query Verticales Incremental", "Stamp Output Filename", "Persist Fase 12 Output"}
found = {proc.get("component", {}).get("name") for proc in processors}
missing = sorted(expected - found)
invalid = []
for proc in processors:
    component = proc.get("component", {})
    name = component.get("name")
    if name not in expected:
        continue
    state = component.get("state")
    validation = component.get("validationStatus")
    print(f"{name}: {validation}/{state}")
    if state != "RUNNING" or validation != "VALID":
        invalid.append(f"{name}={validation}/{state}")
if missing:
    raise SystemExit("Faltan procesadores: " + ", ".join(missing))
if invalid:
    raise SystemExit("Procesadores no operativos: " + ", ".join(invalid))'

echo
echo "[3/5] Servicios de controlador"
curl -skf --max-time 30 \
  -H "Authorization: Bearer $TOKEN" \
  "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id/controller-services" | \
  python3 -c 'import json,sys
services = json.load(sys.stdin).get("controllerServices", [])
expected = {"Verticales DBCP", "JSON Record Writer"}
found = {service.get("component", {}).get("name") for service in services}
missing = sorted(expected - found)
invalid = []
for service in services:
    component = service.get("component", {})
    name = component.get("name")
    if name not in expected:
        continue
    state = component.get("state")
    validation = component.get("validationStatus")
    print(f"{name}: {validation}/{state}")
    if state != "ENABLED" or validation != "VALID":
        invalid.append(f"{name}={validation}/{state}")
if missing:
    raise SystemExit("Faltan servicios: " + ", ".join(missing))
if invalid:
    raise SystemExit("Servicios no operativos: " + ", ".join(invalid))'

echo
echo "[4/5] Servicio de salida"
kubectl exec -n datalake "$nifi_pod" -c nifi -- test -d "$OUTPUT_DIR"
kubectl exec -n datalake "$nifi_pod" -c nifi -- sh -c "find '$OUTPUT_DIR' -maxdepth 1 -type f | head -n 5"

echo
echo "[5/5] Driver JDBC"
kubectl exec -n datalake "$nifi_pod" -c nifi -- test -f /opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar
echo "Driver JDBC presente."
