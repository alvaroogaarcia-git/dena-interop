CREATE SCHEMA IF NOT EXISTS expedientes;

CREATE TABLE IF NOT EXISTS expedientes.admin_file (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  expediente_code text NOT NULL UNIQUE,
  title text NOT NULL,
  citizen_id text NOT NULL,
  source_system text NOT NULL DEFAULT 'verticales-local',
  status text NOT NULL DEFAULT 'abierto',
  amount_eur numeric(12,2) NOT NULL DEFAULT 0,
  opened_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS admin_file_updated_at_idx
  ON expedientes.admin_file (updated_at, id);

CREATE OR REPLACE FUNCTION expedientes.touch_admin_file_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_admin_file_updated_at ON expedientes.admin_file;

CREATE TRIGGER trg_touch_admin_file_updated_at
BEFORE UPDATE ON expedientes.admin_file
FOR EACH ROW
EXECUTE FUNCTION expedientes.touch_admin_file_updated_at();

CREATE OR REPLACE VIEW expedientes.admin_file_nifi AS
SELECT
  id AS source_id,
  expediente_code,
  title,
  citizen_id,
  source_system,
  status,
  amount_eur,
  opened_at,
  updated_at
FROM expedientes.admin_file;
