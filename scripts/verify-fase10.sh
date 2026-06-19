#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl

echo "Usando KUBECONFIG=$KUBECONFIG"

echo
echo "[1/5] Workloads de Fase 10"
kubectl get statefulset postgresql-datalake -n datalake >/dev/null
kubectl get deployment postgrest -n datalake >/dev/null
kubectl rollout status statefulset/postgresql-datalake -n datalake --timeout=180s >/dev/null
kubectl rollout status deployment/postgrest -n datalake --timeout=180s >/dev/null
kubectl get pods,svc -n datalake -o wide

echo
echo "[2/5] Secret de conexion de PostgREST"
db_uri="$(kubectl get secret -n datalake postgrest-secret -o jsonpath='{.data.db-uri}' | base64 -d)"
if [[ "$db_uri" != postgres://postgrest:*@postgresql-datalake.datalake.svc.cluster.local:5432/datalake ]]; then
  echo "El secret postgrest-secret no apunta al DSN esperado" >&2
  exit 1
fi
echo "DSN OK"

echo
echo "[3/5] Roles de base de datos"
pg_password="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
roles_output="$(
  kubectl exec -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -U postgres -d datalake -Atc "
      select rolname || '|' || case when rolcanlogin then 't' else 'f' end
      from pg_roles
      where rolname in ('anon', 'postgrest')
      order by rolname;

      select pg_get_userbyid(member) || '->' || pg_get_userbyid(roleid)
      from pg_auth_members
      where pg_get_userbyid(member) = 'postgrest'
        and pg_get_userbyid(roleid) = 'anon';
    "
)"
printf '%s\n' "$roles_output"
grep -Fx "anon|f" <<<"$roles_output" >/dev/null
grep -Fx "postgrest|t" <<<"$roles_output" >/dev/null
grep -Fx "postgrest->anon" <<<"$roles_output" >/dev/null

echo
echo "[4/5] Respuesta HTTP de PostgREST"
openapi_output="$(
  kubectl run postgrest-check \
    --rm -i \
    --restart=Never \
    --image=nginx:alpine \
    -n datalake \
    -- wget -S -O- http://postgrest.datalake.svc.cluster.local:3000/ 2>&1
)"
printf '%s\n' "$openapi_output"
grep -F "HTTP/1.1 200 OK" <<<"$openapi_output" >/dev/null
grep -F '"swagger":"2.0"' <<<"$openapi_output" >/dev/null

echo
echo "[5/5] Cierre de fase"
echo "Fase 10 validada: PostgreSQL datalake y PostgREST estan operativos."
