#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

NIFI_LOCAL_PORT="${NIFI_LOCAL_PORT:-8443}"
NIFI_BASE_URL="${NIFI_BASE_URL:-https://192.168.56.15:30821}"
NIFI_USERNAME="${NIFI_USERNAME:-$(kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-username}' | base64 -d)}"
NIFI_PASSWORD="${NIFI_PASSWORD:-$(kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-password}' | base64 -d)}"
GROUP_NAME="${GROUP_NAME:-Fase 15 - DENA staging incremental}"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin curl
require_bin python3

PORT_FORWARD_PID=""

cleanup() {
  if [[ -n "$PORT_FORWARD_PID" ]]; then
    kill "$PORT_FORWARD_PID" 2>/dev/null || true
    wait "$PORT_FORWARD_PID" 2>/dev/null || true
  fi
}

start_port_forward() {
  if curl --http1.1 -sk --max-time 2 "$NIFI_BASE_URL/nifi-api/access/config" >/dev/null; then
    return
  fi

  kubectl port-forward -n datalake svc/nifi "$NIFI_LOCAL_PORT:8443" \
    --address 127.0.0.1 >/tmp/fase15-nifi-port-forward.log 2>&1 &
  PORT_FORWARD_PID=$!
  trap cleanup EXIT

  for _ in $(seq 1 60); do
    if curl --http1.1 -sk --max-time 2 "$NIFI_BASE_URL/nifi-api/access/config" >/dev/null; then
      return
    fi
    if ! kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
      echo "El port-forward de NiFi ha terminado inesperadamente" >&2
      tail -n 20 /tmp/fase15-nifi-port-forward.log >&2 || true
      exit 1
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

echo "Usando KUBECONFIG=$KUBECONFIG"
start_port_forward

nifi_pod="$(kubectl get pod -n datalake -l app=nifi --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$nifi_pod" ]]; then
  echo "No se ha encontrado un pod Running de NiFi en datalake" >&2
  exit 1
fi

token="$(
  curl --http1.1 -skf --max-time 120 \
    -X POST \
    --data-urlencode "username=$NIFI_USERNAME" \
    --data-urlencode "password=$NIFI_PASSWORD" \
    "$NIFI_BASE_URL/nifi-api/access/token"
)"

group_id="$(
  curl --http1.1 -skf --max-time 120 \
    -H "Authorization: Bearer $token" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/root" | json_find_group_id "$GROUP_NAME"
)"

echo "[1/5] Grupo de proceso"
echo "$GROUP_NAME => $group_id"

echo
echo "[2/5] Procesadores"
group_json="$(
  curl --http1.1 -skf --max-time 120 \
    -H "Authorization: Bearer $token" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id"
)"
GROUP_JSON="$group_json" python3 -c 'import json, os
data = json.loads(os.environ["GROUP_JSON"])
processors = data["processGroupFlow"]["flow"].get("processors", [])
expected = {"Query Verticales Incremental", "Persist Staging Batch", "Promote Staging To Main"}
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
    schedule = component.get("config", {}).get("schedulingPeriod")
    print(f"{name}: {validation}/{state} schedule={schedule}")
    if name == "Query Verticales Incremental" and schedule != "30 sec":
        invalid.append(f"{name}=schedulingPeriod:{schedule}")
    if state != "RUNNING" or validation != "VALID":
        invalid.append(f"{name}={validation}/{state}")
if missing:
    raise SystemExit("Faltan procesadores: " + ", ".join(missing))
if invalid:
    raise SystemExit("Procesadores no operativos: " + ", ".join(invalid))
'

echo
echo "[3/5] Servicios de controlador"
controller_json="$(
  curl --http1.1 -skf --max-time 120 \
    -H "Authorization: Bearer $token" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id/controller-services"
)"
python3 -c 'import json, sys
services = json.loads(sys.stdin.read()).get("controllerServices", [])
expected = {"Verticales DBCP", "Datalake DBCP", "JSON Record Writer", "JSON Record Reader"}
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
    raise SystemExit("Servicios no operativos: " + ", ".join(invalid))
' <<<"$controller_json"

echo
echo "[4/5] Datos sincronizados"
verticales_pw="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
datalake_pw="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
source_row="$(
  kubectl exec -i -n verticales postgresql-verticales-0 -- \
    env PGPASSWORD="$verticales_pw" \
    psql -U postgres -d expedientes -Atc "SELECT status, to_char(date_trunc('milliseconds', updated_at), 'YYYY-MM-DD HH24:MI:SS.MS TZ') FROM expedientes.admin_file WHERE id = 1;"
)"
target_row="$(
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$datalake_pw" \
    psql -U postgres -d datalake -Atc "SELECT status, to_char(date_trunc('milliseconds', updated_at), 'YYYY-MM-DD HH24:MI:SS.MS TZ') FROM dena.admin_file WHERE source_id = 1;"
)"
echo "verticales: $source_row"
echo "datalake:   $target_row"
[[ "$source_row" == "$target_row" ]]

source_count="$(
  kubectl exec -i -n verticales postgresql-verticales-0 -- \
    env PGPASSWORD="$verticales_pw" \
    psql -U postgres -d expedientes -Atc "SELECT count(*) FROM expedientes.admin_file;"
)"
target_count="$(
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$datalake_pw" \
    psql -U postgres -d datalake -Atc "SELECT count(*) FROM dena.admin_file;"
)"
echo "rows verticales=$source_count datalake=$target_count"
[[ "$source_count" == "$target_count" ]]

echo
echo "[5/5] Driver JDBC"
kubectl exec -n datalake "$nifi_pod" -c nifi -- test -f /opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar
echo "Driver JDBC presente."
