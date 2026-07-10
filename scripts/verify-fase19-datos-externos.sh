#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/dena-config}"
export KUBECONFIG="$KUBECONFIG_PATH"

NAMESPACE="datos-externos"
RELEASE="datos-externos-postgresql"
DATABASE="datos_externos"

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta binario requerido: $1" >&2
    exit 1
  }
}

require_bin kubectl
require_bin base64

echo "Usando KUBECONFIG=$KUBECONFIG"

kubectl get namespace "$NAMESPACE" >/dev/null
kubectl get statefulset "$RELEASE" -n "$NAMESPACE" >/dev/null
kubectl get service "$RELEASE" -n "$NAMESPACE" >/dev/null
kubectl get pvc "data-$RELEASE-0" -n "$NAMESPACE" >/dev/null
kubectl rollout status "statefulset/$RELEASE" -n "$NAMESPACE" --timeout=180s >/dev/null

pg_password="$(kubectl get secret -n "$NAMESPACE" "$RELEASE" -o jsonpath='{.data.postgres-password}' | base64 -d)"

check_sql="$(
  cat <<'SQL'
select to_regclass('dena.dena_business_object');
select to_regclass('dena.dena_expediente');
select to_regclass('dena.dena_notificacion');
select to_regclass('dena.dena_pago');
select to_regclass('dena.dena_source_document');
select count(*) from dena.dena_source_document;
select count(*) from dena.dena_semantic_field;
select count(*) from dena.dena_semantic_enum_value;
select string_agg(external_id, ',' order by external_id) from dena.dena_data_type;
select count(*) from dena.dena_expediente;
select count(*) from dena.dena_notificacion;
select count(*) from dena.dena_pago;
select count(*) from dena.dena_cita;
select count(*) from dena.dena_person_data;
select count(*) from dena.dena_interop_message where message_correlation_id like 'corr-demo-%';
SQL
)"

schema_output="$(
  kubectl exec -i -n "$NAMESPACE" "$RELEASE-0" -- \
    env PGPASSWORD="$pg_password" \
    psql -U postgres -d "$DATABASE" -Atc "$check_sql"
)"

printf '%s\n' "$schema_output"

grep -Fx "dena.dena_business_object" <<<"$schema_output" >/dev/null
grep -Fx "dena.dena_expediente" <<<"$schema_output" >/dev/null
grep -Fx "dena.dena_notificacion" <<<"$schema_output" >/dev/null
grep -Fx "dena.dena_pago" <<<"$schema_output" >/dev/null
grep -Fx "dena.dena_source_document" <<<"$schema_output" >/dev/null
grep -Fx "21" <<<"$(sed -n '6p' <<<"$schema_output")" >/dev/null

semantic_fields="$(sed -n '7p' <<<"$schema_output")"
enum_values="$(sed -n '8p' <<<"$schema_output")"

if (( semantic_fields < 45 )); then
  echo "Diccionario de campos incompleto: $semantic_fields" >&2
  exit 1
fi

if (( enum_values < 50 )); then
  echo "Catalogo de enumerados incompleto: $enum_values" >&2
  exit 1
fi

grep -F "PAYMENTS" <<<"$(sed -n '9p' <<<"$schema_output")" >/dev/null
grep -F "RECORDS" <<<"$(sed -n '9p' <<<"$schema_output")" >/dev/null

grep -Fx "50" <<<"$(sed -n '10p' <<<"$schema_output")" >/dev/null
grep -Fx "30" <<<"$(sed -n '11p' <<<"$schema_output")" >/dev/null
grep -Fx "25" <<<"$(sed -n '12p' <<<"$schema_output")" >/dev/null
grep -Fx "10" <<<"$(sed -n '13p' <<<"$schema_output")" >/dev/null
grep -Fx "20" <<<"$(sed -n '14p' <<<"$schema_output")" >/dev/null
grep -Fx "50" <<<"$(sed -n '15p' <<<"$schema_output")" >/dev/null

echo "Fase 19 verificada: PostgreSQL datos-externos, catalogo Markdown y datos demo operativos."
