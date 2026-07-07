CREATE TABLE IF NOT EXISTS dena.recovery_backup_code (
  id bigserial PRIMARY KEY,
  realm text NOT NULL,
  username text NOT NULL,
  code_hash text NOT NULL UNIQUE,
  code_hint text NOT NULL,
  status text NOT NULL DEFAULT 'issued',
  issued_at timestamptz NOT NULL DEFAULT now(),
  issued_by text NOT NULL,
  used_at timestamptz,
  used_by text,
  notes text
);

CREATE INDEX IF NOT EXISTS dena_recovery_backup_code_lookup_idx
  ON dena.recovery_backup_code (realm, username, status, issued_at DESC);

CREATE TABLE IF NOT EXISTS dena.recovery_event (
  id bigserial PRIMARY KEY,
  realm text NOT NULL,
  username text NOT NULL,
  recovery_backup_code_id bigint REFERENCES dena.recovery_backup_code(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  operator_username text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS dena_recovery_event_lookup_idx
  ON dena.recovery_event (realm, username, created_at DESC);

REVOKE ALL ON TABLE dena.recovery_backup_code FROM PUBLIC;
REVOKE ALL ON TABLE dena.recovery_event FROM PUBLIC;

NOTIFY pgrst, 'reload schema';
