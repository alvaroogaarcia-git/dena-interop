CREATE SCHEMA IF NOT EXISTS dena;

CREATE TABLE IF NOT EXISTS dena.admin_file (
  source_id bigint PRIMARY KEY,
  expediente_code text NOT NULL UNIQUE,
  title text NOT NULL,
  citizen_id text NOT NULL,
  source_system text NOT NULL,
  status text NOT NULL,
  amount_eur numeric(12,2) NOT NULL,
  opened_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  ingested_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS dena_admin_file_updated_at_idx
  ON dena.admin_file (updated_at, source_id);

CREATE OR REPLACE VIEW dena."adminFile" AS
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
  ingested_at
FROM dena.admin_file;

REVOKE ALL ON SCHEMA dena FROM PUBLIC;
REVOKE ALL ON TABLE dena.admin_file FROM PUBLIC;
REVOKE ALL ON TABLE dena."adminFile" FROM PUBLIC;

GRANT USAGE ON SCHEMA dena TO anon;
GRANT SELECT ON dena.admin_file TO anon;
GRANT SELECT ON dena."adminFile" TO anon;

NOTIFY pgrst, 'reload schema';
