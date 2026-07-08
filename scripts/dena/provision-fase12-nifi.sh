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
DB_NAME="${DB_NAME:-expedientes}"
DB_SCHEMA="${DB_SCHEMA:-expedientes}"
DB_TABLE="${DB_TABLE:-admin_file}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-postgresql-verticales.verticales.svc.cluster.local}"
DB_PORT="${DB_PORT:-5432}"
DB_PASSWORD="${DB_PASSWORD:-$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)}"
JDBC_JAR="${JDBC_JAR:-/opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar}"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

get_nifi_pod() {
  kubectl get pod -n datalake -l app=nifi \
    --field-selector=status.phase=Running \
    -o jsonpath='{.items[0].metadata.name}'
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
    if ! kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
      echo "El port-forward de NiFi ha terminado inesperadamente" >&2
      tail -n 20 /tmp/fase12-nifi-port-forward.log >&2 || true
      exit 1
    fi
    sleep 2
  done

  echo "NiFi no ha respondido a tiempo" >&2
  exit 1
}

json_get_id() {
  python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("id") or data.get("component", {}).get("id") or "")'
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

json_find_component_id() {
  local list_path="$1"
  local component_name="$2"

  python3 -c 'import json,sys
path, name = sys.argv[1:]
data = json.load(sys.stdin)
for key in path.split("."):
    data = data.get(key, {})
for entity in data if isinstance(data, list) else []:
    component = entity.get("component", {})
    if component.get("name") == name:
        print(component.get("id") or entity.get("id") or "")
        raise SystemExit(0)
raise SystemExit(1)' "$list_path" "$component_name"
}

create_group_payload() {
  cat <<EOF
{"revision":{"version":0},"component":{"name":"$GROUP_NAME","position":{"x":200.0,"y":200.0}}}
EOF
}

create_controller_service_payload() {
  local name="$1"
  local type="$2"
  local properties="$3"

  cat <<EOF
{"revision":{"version":0},"component":{"name":"$name","type":"$type","properties":$properties}}
EOF
}

create_processor_payload() {
  local name="$1"
  local type="$2"
  local x="$3"
  local y="$4"
  local properties="$5"
  local auto_terminated="${6:-[]}"

  cat <<EOF
{"revision":{"version":0},"component":{"name":"$name","type":"$type","position":{"x":$x,"y":$y},"config":{"properties":$properties,"autoTerminatedRelationships":$auto_terminated}}}
EOF
}

post_json() {
  local url="$1"
  local payload="$2"

  curl -skf --max-time 120 \
    -X POST "$url" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$payload"
}

put_json() {
  local url="$1"
  local payload="$2"

  curl -skf --max-time 120 \
    -X PUT "$url" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$payload"
}

require_bin kubectl
require_bin curl
require_bin python3

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

if [[ -z "$TOKEN" ]]; then
  echo "No se ha podido obtener token de NiFi" >&2
  exit 1
fi

kubectl get pod -n datalake -l app=nifi >/dev/null
kubectl exec -n datalake "$nifi_pod" -c nifi -- mkdir -p "$OUTPUT_DIR"

group_id="$(
  curl -skf --max-time 30 \
    -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/root" | json_find_group_id "$GROUP_NAME" || true
)"

if [[ -z "$group_id" ]]; then
  echo "Creando grupo de proceso: $GROUP_NAME"
  group_id="$(
    post_json "$NIFI_BASE_URL/nifi-api/process-groups/root/process-groups" "$(create_group_payload)" | json_get_id
  )"
else
  echo "Grupo ya existente: $GROUP_NAME ($group_id)"
fi

echo "Grupo de proceso: $group_id"

find_controller_service_id() {
  local name="$1"
  curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id/controller-services" | \
    json_find_component_id controllerServices "$name"
}

dbcp_id="$(find_controller_service_id "Verticales DBCP" || true)"
if [[ -z "$dbcp_id" ]]; then
  dbcp_id="$(
    post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/controller-services" "$(create_controller_service_payload \
      "Verticales DBCP" \
      "org.apache.nifi.dbcp.DBCPConnectionPool" \
      "{\"Database Connection URL\":\"jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME\",\"Database Driver Class Name\":\"org.postgresql.Driver\",\"Database Driver Locations\":\"$JDBC_JAR\",\"Database User\":\"$DB_USER\",\"Password\":\"$DB_PASSWORD\"}")" | json_get_id
  )"
fi

writer_id="$(find_controller_service_id "JSON Record Writer" || true)"
if [[ -z "$writer_id" ]]; then
  writer_id="$(
    post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/controller-services" "$(create_controller_service_payload \
      "JSON Record Writer" \
      "org.apache.nifi.json.JsonRecordSetWriter" \
      "{}")" | json_get_id
  )"
fi

enable_service() {
  local service_id="$1"
  local entity
  local state
  local version

  entity="$(curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/controller-services/$service_id")"
  state="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["component"]["state"])' <<<"$entity")"
  if [[ "$state" == "ENABLED" || "$state" == "ENABLING" ]]; then
    return
  fi
  version="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"]["version"])' <<<"$entity")"

  put_json "$NIFI_BASE_URL/nifi-api/controller-services/$service_id/run-status" \
    "{\"revision\":{\"version\":$version},\"state\":\"ENABLED\"}" >/dev/null
}

find_processor_id() {
  local name="$1"
  curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id" | \
    json_find_component_id processGroupFlow.flow.processors "$name"
}

query_id="$(find_processor_id "Query Verticales Incremental" || true)"
if [[ -z "$query_id" ]]; then
  query_id="$(
    post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/processors" "$(create_processor_payload \
      "Query Verticales Incremental" \
      "org.apache.nifi.processors.standard.QueryDatabaseTableRecord" \
      150.0 220.0 \
      "{\"Database Connection Pooling Service\":\"$dbcp_id\",\"Table Name\":\"$DB_SCHEMA.$DB_TABLE\",\"Maximum-value Columns\":\"updated_at\",\"Record Writer\":\"$writer_id\"}" \
      "[\"failure\",\"retry\"]")" | json_get_id
  )"
fi

stamp_id="$(find_processor_id "Stamp Output Filename" || true)"
if [[ -z "$stamp_id" ]]; then
  stamp_id="$(
    post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/processors" "$(create_processor_payload \
      "Stamp Output Filename" \
      "org.apache.nifi.processors.attributes.UpdateAttribute" \
      480.0 220.0 \
      "{\"filename\":\"fase12-\${now():format('yyyyMMdd-HHmmss')}-\${UUID()}.json\"}" \
      "[]")" | json_get_id
  )"
fi

putfile_id="$(find_processor_id "Persist Fase 12 Output" || true)"
if [[ -z "$putfile_id" ]]; then
  putfile_id="$(
    post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/processors" "$(create_processor_payload \
      "Persist Fase 12 Output" \
      "org.apache.nifi.processors.standard.PutFile" \
      810.0 220.0 \
      "{\"Directory\":\"$OUTPUT_DIR\"}" \
      "[\"success\",\"failure\"]")" | json_get_id
  )"
fi

configure_processor() {
  local processor_id="$1"
  local properties="$2"
  local auto_terminated="$3"
  local version

  version="$(curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/processors/$processor_id" | \
    python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"]["version"])')"
  put_json "$NIFI_BASE_URL/nifi-api/processors/$processor_id" \
    "{\"revision\":{\"version\":$version},\"component\":{\"id\":\"$processor_id\",\"config\":{\"properties\":$properties,\"autoTerminatedRelationships\":$auto_terminated}}}" >/dev/null
}

stop_processor() {
  local processor_id="$1"
  local entity
  local physical_state
  local state
  local version

  entity="$(curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/processors/$processor_id")"
  state="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["component"]["state"])' <<<"$entity")"
  physical_state="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("physicalState", "STOPPED"))' <<<"$entity")"
  if [[ "$state" == "STOPPED" && "$physical_state" == "STOPPED" ]]; then
    return
  fi
  version="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"]["version"])' <<<"$entity")"
  put_json "$NIFI_BASE_URL/nifi-api/processors/$processor_id/run-status" \
    "{\"revision\":{\"version\":$version},\"state\":\"STOPPED\"}" >/dev/null

  for _ in $(seq 1 30); do
    entity="$(curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
      "$NIFI_BASE_URL/nifi-api/processors/$processor_id")"
    state="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["component"]["state"])' <<<"$entity")"
    physical_state="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("physicalState", "STOPPED"))' <<<"$entity")"
    [[ "$state" == "STOPPED" && "$physical_state" == "STOPPED" ]] && return
    sleep 1
  done

  echo "El procesador $processor_id no se ha detenido a tiempo" >&2
  exit 1
}

stop_processor "$query_id"
stop_processor "$stamp_id"
stop_processor "$putfile_id"

configure_controller_service() {
  local service_id="$1"
  local properties="$2"
  local entity
  local state
  local version

  entity="$(curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/controller-services/$service_id")"
  state="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["component"]["state"])' <<<"$entity")"
  if [[ "$state" != "DISABLED" ]]; then
    version="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"]["version"])' <<<"$entity")"
    put_json "$NIFI_BASE_URL/nifi-api/controller-services/$service_id/run-status" \
      "{\"revision\":{\"version\":$version},\"state\":\"DISABLED\"}" >/dev/null
    for _ in $(seq 1 30); do
      entity="$(curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
        "$NIFI_BASE_URL/nifi-api/controller-services/$service_id")"
      state="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["component"]["state"])' <<<"$entity")"
      [[ "$state" == "DISABLED" ]] && break
      sleep 1
    done
  fi

  [[ "$state" == "DISABLED" ]] || {
    echo "El servicio $service_id no se ha deshabilitado a tiempo" >&2
    exit 1
  }
  version="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"]["version"])' <<<"$entity")"
  put_json "$NIFI_BASE_URL/nifi-api/controller-services/$service_id" \
    "{\"revision\":{\"version\":$version},\"component\":{\"id\":\"$service_id\",\"properties\":$properties}}" >/dev/null
}

echo "Configurando servicios de controlador"
configure_controller_service "$dbcp_id" \
  "{\"Database Connection URL\":\"jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME\",\"Database Driver Class Name\":\"org.postgresql.Driver\",\"Database Driver Locations\":\"$JDBC_JAR\",\"Database User\":\"$DB_USER\",\"Password\":\"$DB_PASSWORD\"}"

echo "Habilitando servicios de controlador"
enable_service "$dbcp_id"
enable_service "$writer_id"

echo "Aplicando propiedades de procesadores"
configure_processor "$query_id" \
  "{\"Database Connection Pooling Service\":\"$dbcp_id\",\"Table Name\":\"$DB_SCHEMA.$DB_TABLE\",\"Maximum-value Columns\":\"updated_at\",\"Record Writer\":\"$writer_id\"}" \
  "[\"failure\",\"retry\"]"
configure_processor "$stamp_id" \
  "{\"filename\":\"fase12-\${now():format('yyyyMMdd-HHmmss')}-\${UUID()}.json\"}" \
  "[]"
configure_processor "$putfile_id" \
  "{\"Directory\":\"$OUTPUT_DIR\"}" \
  "[\"success\",\"failure\"]"

connect_processors() {
  local source_id="$1"
  local source_name="$2"
  local destination_id="$3"
  local destination_name="$4"
  local relationship="$5"

  if curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/flow/process-groups/$group_id" | \
    python3 -c 'import json,sys
source_id, destination_id = sys.argv[1:]
connections = json.load(sys.stdin)["processGroupFlow"]["flow"].get("connections", [])
raise SystemExit(0 if any(c.get("component", {}).get("source", {}).get("id") == source_id and c.get("component", {}).get("destination", {}).get("id") == destination_id for c in connections) else 1)' \
    "$source_id" "$destination_id"; then
    return
  fi

  post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/connections" "$(cat <<EOF
{"revision":{"version":0},"component":{"source":{"id":"$source_id","type":"PROCESSOR","groupId":"$group_id","name":"$source_name"},"destination":{"id":"$destination_id","type":"PROCESSOR","groupId":"$group_id","name":"$destination_name"},"selectedRelationships":["$relationship"]}}
EOF
)" >/dev/null
}

connect_processors "$query_id" "Query Verticales Incremental" "$stamp_id" "Stamp Output Filename" success
connect_processors "$stamp_id" "Stamp Output Filename" "$putfile_id" "Persist Fase 12 Output" success

start_processor() {
  local processor_id="$1"
  local entity
  local state
  local version

  entity="$(curl -skf --max-time 30 -H "Authorization: Bearer $TOKEN" \
    "$NIFI_BASE_URL/nifi-api/processors/$processor_id")"
  state="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["component"]["state"])' <<<"$entity")"
  if [[ "$state" == "RUNNING" ]]; then
    return
  fi
  version="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"]["version"])' <<<"$entity")"

  put_json "$NIFI_BASE_URL/nifi-api/processors/$processor_id/run-status" \
    "{\"revision\":{\"version\":$version},\"state\":\"RUNNING\"}" >/dev/null
}

echo "Arrancando procesadores"
start_processor "$query_id"
start_processor "$stamp_id"
start_processor "$putfile_id"

echo "Fase 12 aprovisionada."
echo "Grupo: $GROUP_NAME"
echo "Salida: $OUTPUT_DIR"
