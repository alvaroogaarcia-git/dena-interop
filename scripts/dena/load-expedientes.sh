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

kubectl rollout status statefulset/postgresql-verticales -n verticales --timeout=180s >/dev/null

pg_password="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$pg_password" \
  psql -U postgres -d expedientes <<'SQL'
INSERT INTO expedientes.admin_file (
  expediente_code,
  title,
  citizen_id,
  source_system,
  status,
  amount_eur,
  opened_at,
  updated_at
)
SELECT
  'EXP-' || lpad(gs::text, 4, '0'),
  format('Expediente demo %s', gs),
  'CIT-' || lpad((10000 + gs)::text, 5, '0'),
  'verticales-local',
  CASE
    WHEN gs % 5 = 0 THEN 'archivado'
    WHEN gs % 4 = 0 THEN 'resuelto'
    WHEN gs % 3 = 0 THEN 'pendiente_documentacion'
    WHEN gs % 2 = 0 THEN 'en_tramitacion'
    ELSE 'abierto'
  END,
  round((750 + gs * 23.45)::numeric, 2),
  now() - make_interval(days => gs),
  now() - make_interval(hours => gs)
FROM generate_series(1, 50) AS gs
ON CONFLICT (expediente_code) DO UPDATE
SET
  title = EXCLUDED.title,
  citizen_id = EXCLUDED.citizen_id,
  source_system = EXCLUDED.source_system,
  status = EXCLUDED.status,
  amount_eur = EXCLUDED.amount_eur,
  opened_at = EXCLUDED.opened_at,
  updated_at = EXCLUDED.updated_at;

SELECT count(*) AS expedientes_total FROM expedientes.admin_file;
SQL
