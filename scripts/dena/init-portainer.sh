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
      exit 0
      ;;
    409)
      echo "Portainer ya estaba inicializado."
      exit 0
      ;;
  esac
  sleep 1
done

cat /tmp/portainer-init-response.json >&2 || true
echo "No se pudo inicializar Portainer; ultimo HTTP: ${status:-sin respuesta}" >&2
exit 1
