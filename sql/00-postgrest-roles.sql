\if :{?postgrest_db_password}
\else
\echo 'Falta la variable postgrest_db_password. Usa: psql -v postgrest_db_password=... -f sql/00-postgrest-roles.sql'
\quit 3
\endif

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
    EXECUTE format(
      'CREATE ROLE postgrest LOGIN PASSWORD %L',
      :'postgrest_db_password'
    );
  ELSE
    EXECUTE format(
      'ALTER ROLE postgrest LOGIN PASSWORD %L',
      :'postgrest_db_password'
    );
  END IF;
END
$$;

GRANT anon TO postgrest;
