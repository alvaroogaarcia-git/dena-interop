#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

NIFI_BASE_URL="${NIFI_BASE_URL:-https://localhost:8443}"
NIFI_USERNAME="${NIFI_USERNAME:-admin}"
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
{"revision":{"version":0},"component":{"name":"$name","type":"$type","position":{"x":$x,"y":$y},"properties":$properties,"autoTerminatedRelationships":$auto_terminated}}
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
kubectl exec -n datalake "$(kubectl get pod -n datalake -l app=nifi -o jsonpath='{.items[0].metadata.name}')" -c nifi -- mkdir -p "$OUTPUT_DIR"

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

dbcp_id="$(
  post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/controller-services" "$(create_controller_service_payload \
    "Verticales DBCP" \
    "org.apache.nifi.dbcp.DBCPConnectionPool" \
    "{\"Database Connection URL\":\"jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME\",\"Database Driver Class Name\":\"org.postgresql.Driver\",\"Database Driver Location(s)\":\"$JDBC_JAR\",\"Database User\":\"$DB_USER\",\"Password\":\"$DB_PASSWORD\"}")" | json_get_id
)"

writer_id="$(
  post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/controller-services" "$(create_controller_service_payload \
    "JSON Record Writer" \
    "org.apache.nifi.json.JsonRecordSetWriter" \
    "{}")" | json_get_id
)"

enable_service() {
  local service_id="$1"

  put_json "$NIFI_BASE_URL/nifi-api/controller-services/$service_id/run-status" \
    "{\"revision\":{\"version\":0},\"state\":\"ENABLED\"}" >/dev/null
}

enable_service "$dbcp_id"
enable_service "$writer_id"

query_id="$(
  post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/processors" "$(create_processor_payload \
    "Query Verticales Incremental" \
    "org.apache.nifi.processors.standard.QueryDatabaseTableRecord" \
    150.0 \
    220.0 \
    "{\"Database Connection Pooling Service\":\"$dbcp_id\",\"Table Name\":\"$DB_SCHEMA.$DB_TABLE\",\"Maximum-value Columns\":\"updated_at,id\",\"Record Writer\":\"$writer_id\"}" \
    "[\"failure\",\"retry\"]")" | json_get_id
)"

stamp_id="$(
  post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/processors" "$(create_processor_payload \
    "Stamp Output Filename" \
    "org.apache.nifi.processors.attributes.UpdateAttribute" \
    480.0 \
    220.0 \
    "{\"filename\":\"fase12-\${now():format('yyyyMMdd-HHmmss')}-\${uuid()}.json\"}" \
    "[]")" | json_get_id
)"

putfile_id="$(
  post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/processors" "$(create_processor_payload \
    "Persist Fase 12 Output" \
    "org.apache.nifi.processors.standard.PutFile" \
    810.0 \
    220.0 \
    "{\"Directory\":\"$OUTPUT_DIR\"}" \
    "[\"failure\"]")" | json_get_id
)"

connect_processors() {
  local source_id="$1"
  local source_name="$2"
  local destination_id="$3"
  local destination_name="$4"
  local relationship="$5"

  post_json "$NIFI_BASE_URL/nifi-api/process-groups/$group_id/connections" "$(cat <<EOF
{"revision":{"version":0},"component":{"source":{"id":"$source_id","type":"PROCESSOR","groupId":"$group_id","name":"$source_name"},"destination":{"id":"$destination_id","type":"PROCESSOR","groupId":"$group_id","name":"$destination_name"},"selectedRelationships":["$relationship"]}}
EOF
)" >/dev/null
}

connect_processors "$query_id" "Query Verticales Incremental" "$stamp_id" "Stamp Output Filename" success
connect_processors "$stamp_id" "Stamp Output Filename" "$putfile_id" "Persist Fase 12 Output" success

start_processor() {
  local processor_id="$1"

  put_json "$NIFI_BASE_URL/nifi-api/processors/$processor_id/run-status" \
    "{\"revision\":{\"version\":0},\"state\":\"RUNNING\"}" >/dev/null
}

start_processor "$query_id"
start_processor "$stamp_id"
start_processor "$putfile_id"

echo "Fase 12 aprovisionada."
echo "Grupo: $GROUP_NAME"
echo "Salida: $OUTPUT_DIR"
