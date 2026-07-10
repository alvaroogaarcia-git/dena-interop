#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

NIFI_BASE_URL="${NIFI_BASE_URL:-https://192.168.56.15:30821}"
NIFI_USERNAME="${NIFI_USERNAME:-$(kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-username}' | base64 -d)}"
NIFI_PASSWORD="${NIFI_PASSWORD:-$(kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-password}' | base64 -d)}"
GROUP_NAME="${GROUP_NAME:-Fase 20 - DENA datos externos incremental}"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin curl
require_bin python3

echo "Usando KUBECONFIG=$KUBECONFIG"

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
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/root" | \
    python3 -c 'import json,sys; data=json.load(sys.stdin); name=sys.argv[1]
for group in data["processGroupFlow"]["flow"].get("processGroups", []):
    component = group.get("component", {})
    if component.get("name") == name:
        print(component.get("id") or group.get("id") or "")
        raise SystemExit(0)
raise SystemExit(1)' "$GROUP_NAME"
)"

echo "[1/4] Grupo NiFi"
echo "$GROUP_NAME => $group_id"

group_json="$(
  curl --http1.1 -skf --max-time 120 \
    -H "Authorization: Bearer $token" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id"
)"

echo
echo "[2/4] Procesadores"
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
echo "[3/4] Servicios de controlador"
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
echo "[4/4] Datos sincronizados"
verticales_pw="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
datos_pw="$(kubectl get secret -n datos-externos datos-externos-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)"

source_row="$(
  kubectl exec -i -n verticales postgresql-verticales-0 -- \
    env PGPASSWORD="$verticales_pw" \
    psql -U postgres -d expedientes -Atc "
      select expediente_code || '|' || title || '|' || status || '|' || amount_eur
      from expedientes.admin_file
      where id = 1;
    "
)"

target_row="$(
  kubectl exec -i -n datos-externos datos-externos-postgresql-0 -- \
    env PGPASSWORD="$datos_pw" \
    psql -U postgres -d datos_externos -Atc "
      select bo.external_id || '|' ||
             coalesce(e.description_by_language->>'SPANISH', '') || '|' ||
             lower(coalesce(e.state_description_by_language->>'SPANISH', '')) || '|' ||
             coalesce(bo.raw_payload->>'amount_eur', '')
      from dena.dena_expediente e
      join dena.dena_business_object bo on bo.business_object_pk = e.business_object_pk
      where bo.external_id = 'EXP-0001';
    "
)"

echo "verticales:     $source_row"
echo "datos-externos: $target_row"

IFS='|' read -r source_code source_title source_status source_amount <<<"$source_row"
IFS='|' read -r target_code target_title target_status target_amount <<<"$target_row"

[[ "$source_code" == "$target_code" ]]
[[ "$source_title" == "$target_title" ]]
[[ "$source_status" == "$target_status" ]]
[[ "$source_amount" == "$target_amount" ]]

echo "Fase 20 verificada: cambios de verticales reflejados en datos_externos."
