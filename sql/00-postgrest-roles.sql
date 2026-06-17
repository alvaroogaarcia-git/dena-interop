DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgrest') THEN
    CREATE ROLE postgrest LOGIN PASSWORD 'contrasena';
  ELSE
    ALTER ROLE postgrest LOGIN PASSWORD 'contrasena';
  END IF;
END
$$;

GRANT anon TO postgrest;
