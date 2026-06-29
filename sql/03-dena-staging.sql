CREATE TABLE IF NOT EXISTS dena.admin_file_staging (
  source_id bigint PRIMARY KEY,
  expediente_code text NOT NULL UNIQUE,
  title text NOT NULL,
  citizen_id text NOT NULL,
  source_system text NOT NULL,
  status text NOT NULL,
  amount_eur numeric(12,2) NOT NULL,
  opened_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  staged_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS dena_admin_file_staging_updated_at_idx
  ON dena.admin_file_staging (updated_at, source_id);

CREATE OR REPLACE FUNCTION dena.dena_staging_to_main()
RETURNS integer
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, public, dena
AS $$
DECLARE
  v_rows integer := 0;
BEGIN
  INSERT INTO dena.admin_file (
    source_id,
    expediente_code,
    title,
    citizen_id,
    source_system,
    status,
    amount_eur,
    opened_at,
    updated_at,
    ingested_at
  )
  SELECT
    source_id,
    expediente_code,
    title,
    citizen_id,
    source_system,
    status,
    amount_eur,
    opened_at,
    updated_at,
    now()
  FROM dena.admin_file_staging
  ON CONFLICT (source_id) DO UPDATE
  SET
    expediente_code = EXCLUDED.expediente_code,
    title = EXCLUDED.title,
    citizen_id = EXCLUDED.citizen_id,
    source_system = EXCLUDED.source_system,
    status = EXCLUDED.status,
    amount_eur = EXCLUDED.amount_eur,
    opened_at = EXCLUDED.opened_at,
    updated_at = EXCLUDED.updated_at,
    ingested_at = now();

  GET DIAGNOSTICS v_rows = ROW_COUNT;

  TRUNCATE dena.admin_file_staging;
  PERFORM pg_notify('pgrst', 'reload schema');

  RETURN v_rows;
END;
$$;

REVOKE ALL ON TABLE dena.admin_file_staging FROM PUBLIC;
REVOKE ALL ON FUNCTION dena.dena_staging_to_main() FROM PUBLIC;

NOTIFY pgrst, 'reload schema';
