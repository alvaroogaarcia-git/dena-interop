#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

USERNAME="${PORTAINER_ADMIN_USERNAME:-admin}"
PASSWORD="${PORTAINER_ADMIN_PASSWORD:-T]8zJMh3U:ADu@L}"
LOCAL_PORT="${PORTAINER_LOCAL_PORT:-19443}"
PF_PID=""

cleanup() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

kubectl rollout status deployment/portainer -n portainer --timeout=180s >/dev/null
kubectl port-forward -n portainer svc/portainer "$LOCAL_PORT:9443" --address 127.0.0.1 \
  >/tmp/portainer-init-port-forward.log 2>&1 &
PF_PID=$!

export USERNAME PASSWORD
payload="$(python3 -c 'import json,os; print(json.dumps({"Username": os.environ["USERNAME"], "Password": os.environ["PASSWORD"]}))' )"

for _ in $(seq 1 30); do
  status="$(
    curl -ksS -o /tmp/portainer-init-response.json -w '%{http_code}' \
      -X POST "https://127.0.0.1:$LOCAL_PORT/api/users/admin/init" \
      -H 'Content-Type: application/json' \
      --data "$payload" 2>/tmp/portainer-init-curl.err || true
  )"
  case "$status" in
    200|204)
      echo "Portainer inicializado con usuario $USERNAME."
      break
      ;;
    409)
      echo "Portainer ya estaba inicializado."
      break
      ;;
  esac
  sleep 1
done

if [[ "${status:-}" != "200" && "${status:-}" != "204" && "${status:-}" != "409" ]]; then
  cat /tmp/portainer-init-response.json >&2 || true
  echo "No se pudo inicializar Portainer; ultimo HTTP: ${status:-sin respuesta}" >&2
  exit 1
fi

auth_payload="$(python3 -c 'import json,os; print(json.dumps({"Username": os.environ["USERNAME"], "Password": os.environ["PASSWORD"]}))')"
token="$(
  curl -kfsS -X POST "https://127.0.0.1:$LOCAL_PORT/api/auth" \
    -H 'Content-Type: application/json' \
    --data "$auth_payload" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["jwt"])'
)"

endpoints_json="$(
  curl -kfsS -H "Authorization: Bearer $token" \
    "https://127.0.0.1:$LOCAL_PORT/api/endpoints"
)"
endpoint_id="$(
  python3 -c 'import json,sys
data=json.load(sys.stdin)
for endpoint in data:
    if endpoint.get("Name") == "local" and endpoint.get("Type") == 5:
        print(endpoint["Id"])
        break
' <<<"$endpoints_json"
)"

if [[ -z "$endpoint_id" ]]; then
  curl -kfsS -X POST "https://127.0.0.1:$LOCAL_PORT/api/endpoints" \
    -H "Authorization: Bearer $token" \
    -F "Name=local" \
    -F "EndpointCreationType=5" \
    -F "URL=https://kubernetes.default.svc" \
    -F "TLS=true" \
    -F "TLSSkipVerify=true" \
    >/tmp/portainer-endpoint-create.json
  endpoint_id="$(python3 -c 'import json; print(json.load(open("/tmp/portainer-endpoint-create.json"))["Id"])')"
  echo "Environment Kubernetes local creado en Portainer (id=$endpoint_id)."
else
  echo "Environment Kubernetes local ya existe en Portainer (id=$endpoint_id)."
fi

curl -kfsS -X POST \
  -H "Authorization: Bearer $token" \
  "https://127.0.0.1:$LOCAL_PORT/api/endpoints/$endpoint_id/snapshot" \
  >/dev/null

namespaces_count="$(
  curl -kfsS -H "Authorization: Bearer $token" \
    "https://127.0.0.1:$LOCAL_PORT/api/endpoints/$endpoint_id/kubernetes/api/v1/namespaces" |
    python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("items", [])))'
)"
deployments_count="$(
  curl -kfsS -H "Authorization: Bearer $token" \
    "https://127.0.0.1:$LOCAL_PORT/api/endpoints/$endpoint_id/kubernetes/apis/apps/v1/deployments" |
    python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("items", [])))'
)"

if [[ "$namespaces_count" -lt 1 || "$deployments_count" -lt 1 ]]; then
  echo "Portainer responde, pero no ve recursos Kubernetes: namespaces=$namespaces_count deployments=$deployments_count" >&2
  exit 1
fi

echo "Portainer ve el cluster: namespaces=$namespaces_count deployments=$deployments_count."
