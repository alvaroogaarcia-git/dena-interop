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

DROP FUNCTION IF EXISTS public.dena_data_retrieve(text, timestamptz, integer);
DROP FUNCTION IF EXISTS public.dena_data_retrieve(text, timestamptz, integer, text, text, timestamptz, timestamptz);

CREATE OR REPLACE FUNCTION public.dena_data_retrieve(
  p_status text DEFAULT NULL,
  p_updated_since timestamptz DEFAULT NULL,
  p_limit integer DEFAULT 100,
  p_code text DEFAULT NULL,
  p_title text DEFAULT NULL,
  p_opened_from timestamptz DEFAULT NULL,
  p_opened_to timestamptz DEFAULT NULL
)
RETURNS TABLE (
  id bigint,
  expediente_code text,
  title text,
  citizen_id text,
  source_system text,
  status text,
  amount_eur numeric,
  opened_at timestamptz,
  updated_at timestamptz,
  ingested_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, dena
AS $$
  SELECT
    af.source_id,
    af.expediente_code,
    af.title,
    af.citizen_id,
    af.source_system,
    af.status,
    af.amount_eur,
    af.opened_at,
    af.updated_at,
    af.ingested_at
  FROM dena.admin_file AS af
  WHERE (p_status IS NULL OR af.status = p_status)
    AND (p_updated_since IS NULL OR af.updated_at > p_updated_since)
    AND (NULLIF(btrim(p_code), '') IS NULL OR af.expediente_code ILIKE '%' || btrim(p_code) || '%')
    AND (NULLIF(btrim(p_title), '') IS NULL OR af.title ILIKE '%' || btrim(p_title) || '%')
    AND (p_opened_from IS NULL OR af.opened_at >= p_opened_from)
    AND (p_opened_to IS NULL OR af.opened_at <= p_opened_to)
  ORDER BY af.updated_at DESC, af.source_id DESC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 100), 1), 1000);
$$;

REVOKE ALL ON SCHEMA dena FROM PUBLIC;
REVOKE ALL ON TABLE dena.admin_file FROM PUBLIC;
GRANT USAGE ON SCHEMA dena TO anon;
GRANT SELECT ON dena.admin_file TO anon;
GRANT EXECUTE ON FUNCTION public.dena_data_retrieve(text, timestamptz, integer, text, text, timestamptz, timestamptz) TO anon;

NOTIFY pgrst, 'reload schema';
