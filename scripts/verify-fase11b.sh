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
echo "[1/5] Workloads de Fase 11b"
kubectl get statefulset postgresql-verticales -n verticales >/dev/null
kubectl get deployment mathesar -n verticales >/dev/null
kubectl rollout status statefulset/postgresql-verticales -n verticales --timeout=180s >/dev/null
kubectl rollout status deployment/mathesar -n verticales --timeout=240s >/dev/null
kubectl get pods,svc,pvc -n verticales -o wide

echo
echo "[2/5] Secretos y exposicion"
kubectl get secret postgresql-verticales -n verticales >/dev/null
kubectl get secret mathesar-secret -n verticales >/dev/null
kubectl get service mathesar -n verticales -o jsonpath='{.spec.type} {.spec.ports[0].nodePort}'
echo

echo
echo "[3/5] Esquema origen y carga inicial"
pg_password="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
source_output="$(
  kubectl exec -n verticales postgresql-verticales-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -U postgres -d expedientes -Atc "
      select to_regclass('expedientes.admin_file');
      select count(*) from expedientes.admin_file;
      select string_agg(distinct status, ',' order by status) from expedientes.admin_file;
      select count(*) from pg_indexes where schemaname = 'expedientes' and tablename = 'admin_file' and indexname = 'admin_file_updated_at_idx';
      select count(*) from pg_constraint where conname = 'admin_file_status_check';
    "
)"
printf '%s\n' "$source_output"
grep -Fx "expedientes.admin_file" <<<"$source_output" >/dev/null
grep -Fx "50" <<<"$source_output" >/dev/null
grep -F "abierto" <<<"$source_output" >/dev/null
grep -F "archivado" <<<"$source_output" >/dev/null
grep -Fx "1" <<<"$source_output" >/dev/null

echo
echo "[4/5] Escucha interna de Mathesar"
mathesar_output="$(
  kubectl run mathesar-check \
    --rm -i \
    --restart=Never \
    --image=busybox:1.36 \
    -n verticales \
    -- nc -zvw5 mathesar.verticales.svc.cluster.local 8000 2>&1
)"
printf '%s\n' "$mathesar_output"
grep -E "open|succeeded" <<<"$mathesar_output" >/dev/null

echo
echo "[5/5] Driver JDBC en NiFi"
nifi_pod="$(kubectl get pod -n datalake -l app=nifi -o jsonpath='{.items[0].metadata.name}')"
kubectl exec -n datalake "$nifi_pod" -c nifi -- test -f /opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar
echo "Driver JDBC presente en el PVC de extensiones de NiFi."
echo "Mathesar expuesto en http://192.168.56.15:30900"
