CREATE OR REPLACE FUNCTION public.dena_data_retrieve(
  p_status text DEFAULT NULL,
  p_updated_since timestamptz DEFAULT NULL,
  p_limit integer DEFAULT 100
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
  updated_at timestamptz
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
    af.updated_at
  FROM dena.admin_file AS af
  WHERE (p_status IS NULL OR af.status = p_status)
    AND (p_updated_since IS NULL OR af.updated_at > p_updated_since)
  ORDER BY af.updated_at, af.source_id
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 100), 1), 1000);
$$;

REVOKE ALL ON FUNCTION public.dena_data_retrieve(text, timestamptz, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dena_data_retrieve(text, timestamptz, integer) TO anon;

NOTIFY pgrst, 'reload schema';
