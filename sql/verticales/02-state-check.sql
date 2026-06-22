ALTER TABLE expedientes.admin_file
  DROP CONSTRAINT IF EXISTS admin_file_status_check;

ALTER TABLE expedientes.admin_file
  ADD CONSTRAINT admin_file_status_check
  CHECK (
    status IN (
      'abierto',
      'en_tramitacion',
      'pendiente_documentacion',
      'resuelto',
      'archivado'
    )
  );
