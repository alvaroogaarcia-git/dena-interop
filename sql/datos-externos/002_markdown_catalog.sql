-- Catalogo documental generado desde /home/dietpi/codex_unzip/codex/semantica-dena.
-- Mantiene trazabilidad entre los Markdown revisados y el esquema fisico creado.

set search_path = dena, public;

insert into dena_source_document (
    source_path,
    document_title,
    document_group,
    suggested_table,
    source_version,
    source_date
)
values
    ('codex/semantica-dena/README.md', 'Semantica DENA para integracion', 'overview', null, 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/INCIDENCIAS.md', 'Incidencias documentales detectadas', 'quality', null, 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/base/data-type-ref.md', 'DataTypeRef', 'base', 'dena_data_type_ref', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/base/language-texts.md', 'LanguageTexts', 'base', 'dena_language_text', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/base/org-admin-ref.md', 'OrgAdminRef', 'base', 'dena_org_admin_ref', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/base/person-ref.md', 'PersonRef', 'base', 'dena_person_ref', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/base/rest-message.md', 'REST Message', 'base', 'dena_rest_message', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/campos-comunes.md', 'Campos comunes de Data-Retrieve', 'data-retrieve', 'dena_common_object', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/cita.md', 'Cita', 'data-retrieve', 'dena_cita', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/expediente.md', 'Expediente', 'data-retrieve', 'dena_expediente', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/notificacion.md', 'Notificacion', 'data-retrieve', 'dena_notificacion', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/pago.md', 'Pago', 'data-retrieve', 'dena_pago', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/persona.md', 'PersonData', 'data-retrieve', 'dena_person_data', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/registro-oficial.md', 'Registro oficial', 'data-retrieve', 'dena_registro_oficial', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/servicio-administrativo.md', 'Servicio administrativo y procedimiento', 'data-retrieve', 'dena_servicio_administrativo', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'Unidad organica', 'data-retrieve', 'dena_unidad_organica', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/metadata-sync/pop-message-after-sync-spec.md', 'PopMessageAfterSyncSpec', 'metadata-sync', 'dena_pop_message_after_sync', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/metadata-sync/sync-metadata-item.md', 'SyncMetadataFromAdminToCoreItem', 'metadata-sync', 'dena_sync_metadata_item', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/person-sync/export-spec.md', 'ExportSpec', 'person-sync', 'dena_person_export_spec', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/person-sync/person-hashes.md', 'PersonHashes', 'person-sync', 'dena_person_hashes', 'v0.3.37', '2026-07-03'),
    ('codex/semantica-dena/person-sync/person-push-data.md', 'PersonPushData', 'person-sync', 'dena_person_push_event', 'v0.3.37', '2026-07-03')
on conflict (source_path) do update
set
    document_title = excluded.document_title,
    document_group = excluded.document_group,
    suggested_table = excluded.suggested_table,
    source_version = excluded.source_version,
    source_date = excluded.source_date,
    loaded_at = now();

with fields(source_path, suggested_table, field_path, field_type, required_level, description) as (
    values
        ('codex/semantica-dena/base/data-type-ref.md', 'dena_data_type_ref', 'oid', 'String', 'Cond.', 'Identificador tecnico interno del tipo.'),
        ('codex/semantica-dena/base/data-type-ref.md', 'dena_data_type_ref', 'id', 'String', 'Cond.', 'Identificador textual del tipo.'),
        ('codex/semantica-dena/base/language-texts.md', 'dena_language_text', 'SPANISH', 'String', 'Recomendado', 'Texto en castellano.'),
        ('codex/semantica-dena/base/language-texts.md', 'dena_language_text', 'BASQUE', 'String', 'Recomendado', 'Texto en euskera.'),
        ('codex/semantica-dena/base/language-texts.md', 'dena_language_text', 'ENGLISH', 'String', 'No', 'Texto en ingles.'),
        ('codex/semantica-dena/base/org-admin-ref.md', 'dena_org_admin_ref', 'oid', 'String', 'Cond.', 'Identificador tecnico interno.'),
        ('codex/semantica-dena/base/org-admin-ref.md', 'dena_org_admin_ref', 'id', 'String', 'Cond.', 'Identificador textual de administracion.'),
        ('codex/semantica-dena/base/person-ref.md', 'dena_person_ref', 'oid', 'String', 'Cond.', 'Identificador tecnico interno.'),
        ('codex/semantica-dena/base/person-ref.md', 'dena_person_ref', 'id', 'String', 'Cond.', 'Identificador externo: NIF, NIE u otro.'),
        ('codex/semantica-dena/base/rest-message.md', 'dena_rest_message', 'context', 'Context', 'Si', 'Metadatos de trazabilidad y referencias de negocio.'),
        ('codex/semantica-dena/base/rest-message.md', 'dena_rest_message', 'data', 'Object', 'Si', 'Payload funcional del endpoint.'),
        ('codex/semantica-dena/base/rest-message.md', 'dena_rest_message', 'context.messageCorrelationId', 'UUID/String', 'Si', 'Correlacion entre request y response.'),
        ('codex/semantica-dena/base/rest-message.md', 'dena_rest_message', 'context.messageType', 'String', 'Si', 'Tipo funcional del mensaje.'),
        ('codex/semantica-dena/base/rest-message.md', 'dena_rest_message', 'context.flowDirection', 'String', 'Si', 'REQUEST o RESPONSE.'),
        ('codex/semantica-dena/base/rest-message.md', 'dena_rest_message', 'context.interopRouteData[]', 'Array', 'Si', 'Trazas de componentes recorridos por el mensaje.'),
        ('codex/semantica-dena/data-retrieve/campos-comunes.md', 'dena_common_object', 'oid', 'String', 'Si', 'Identificador tecnico unico del sistema origen.'),
        ('codex/semantica-dena/data-retrieve/campos-comunes.md', 'dena_common_object', 'id', 'String', 'Si', 'Identificador de negocio visible.'),
        ('codex/semantica-dena/data-retrieve/campos-comunes.md', 'dena_common_object', 'urls[]', 'Array', 'No', 'URLs de consulta o accion.'),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'type', 'String', 'Si', 'administrativeServiceProcedureRecord.'),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'service', 'Servicio administrativo', 'Si', 'Servicio al que pertenece.'),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'procedure', 'Servicio administrativo', 'Si', 'Procedimiento concreto.'),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'createdAt', 'ISO 8601', 'Si', 'Fecha de alta del expediente.'),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'state.stateCode', 'String', 'Si', 'Codigo funcional de estado.'),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'procedureRecord', 'Ref expediente', 'Si', 'Expediente al que pertenece.'),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'issuedAt', 'ISO 8601', 'Si', 'Fecha de emision.'),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'state', 'String', 'Si', 'Estado funcional de lectura.'),
        ('codex/semantica-dena/data-retrieve/registro-oficial.md', 'dena_registro_oficial', 'procedureRecord', 'Ref expediente', 'Si', 'Expediente asociado.'),
        ('codex/semantica-dena/data-retrieve/registro-oficial.md', 'dena_registro_oficial', 'registeredAt', 'ISO 8601', 'Si', 'Fecha y hora de registro.'),
        ('codex/semantica-dena/data-retrieve/registro-oficial.md', 'dena_registro_oficial', 'state.stateCode', 'String', 'Si', 'Estado del registro.'),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'paymentType', 'String', 'Si', 'ONE_OFF_PAYMENT o DIRECT_DEBIT.'),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'paymentDates.dueDate', 'Date', 'Si', 'Vencimiento del pago unico.'),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'amount.amount', 'Number', 'Si', 'Importe numerico.'),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'directDebitData.frequency', 'String', 'Si', 'Frecuencia del cargo domiciliado.'),
        ('codex/semantica-dena/data-retrieve/cita.md', 'dena_cita', 'year', 'Number', 'Si', 'Ano de la cita.'),
        ('codex/semantica-dena/data-retrieve/cita.md', 'dena_cita', 'monthOfYear', 'Number', 'Si', 'Mes 1-12.'),
        ('codex/semantica-dena/data-retrieve/cita.md', 'dena_cita', 'durationMinutes', 'Number', 'Si', 'Duracion en minutos.'),
        ('codex/semantica-dena/data-retrieve/persona.md', 'dena_person_data', 'contactData.partyId', 'String', 'Si', 'NIF, NIE o equivalente.'),
        ('codex/semantica-dena/data-retrieve/persona.md', 'dena_person_data', 'contactData.partyName', 'String', 'Si', 'Nombre.'),
        ('codex/semantica-dena/data-retrieve/persona.md', 'dena_person_data', 'bankDataCollection.bankData[].account.accountId', 'String', 'Si', 'Cuenta bancaria, por ejemplo IBAN.'),
        ('codex/semantica-dena/data-retrieve/servicio-administrativo.md', 'dena_servicio_administrativo', 'originRef.id', 'String', 'Cond.', 'Referencia en catalogo de origen.'),
        ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'dena_unidad_organica', 'orgUnit.id', 'String', 'Si', 'Identificador de negocio.'),
        ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'dena_unidad_organica', 'role', 'String', 'Si', 'Rol funcional.'),
        ('codex/semantica-dena/metadata-sync/sync-metadata-item.md', 'dena_sync_metadata_item', 'admin', 'OrgAdminRef', 'Si', 'Administracion que genera el cambio.'),
        ('codex/semantica-dena/metadata-sync/sync-metadata-item.md', 'dena_sync_metadata_item', 'aboutPerson', 'PersonRef', 'Si', 'Persona afectada.'),
        ('codex/semantica-dena/metadata-sync/sync-metadata-item.md', 'dena_sync_metadata_item', 'someDataWasUpdatedAt', 'ISO 8601', 'Si', 'Momento del cambio.'),
        ('codex/semantica-dena/metadata-sync/pop-message-after-sync-spec.md', 'dena_pop_message_after_sync', 'how', 'String', 'Si', 'Estrategia de entrega del mensaje.'),
        ('codex/semantica-dena/person-sync/export-spec.md', 'dena_person_export_spec', 'personExportSpec', 'String', 'Si', 'data o sync.'),
        ('codex/semantica-dena/person-sync/export-spec.md', 'dena_person_export_spec', 'exportFileFormat', 'String', 'Si', 'Formato de salida.'),
        ('codex/semantica-dena/person-sync/person-hashes.md', 'dena_person_hashes', 'nameHash', 'String', 'Si', 'Hash del nombre.'),
        ('codex/semantica-dena/person-sync/person-hashes.md', 'dena_person_hashes', 'allNamesHash', 'String', 'Si', 'Hash del nombre completo concatenado.'),
        ('codex/semantica-dena/person-sync/person-push-data.md', 'dena_person_push_event', 'personRef', 'PersonRef', 'Si', 'Persona afectada.'),
        ('codex/semantica-dena/person-sync/person-push-data.md', 'dena_person_push_event', 'syncEvent', 'String', 'Si', 'Evento de sincronizacion.')
)
insert into dena_semantic_field (
    source_document_pk,
    suggested_table,
    field_path,
    field_type,
    required_level,
    description
)
select
    d.source_document_pk,
    f.suggested_table,
    f.field_path,
    f.field_type,
    f.required_level,
    f.description
from fields f
join dena_source_document d on d.source_path = f.source_path
on conflict (suggested_table, field_path) do update
set
    field_type = excluded.field_type,
    required_level = excluded.required_level,
    description = excluded.description;

with enums(source_path, suggested_table, enum_name, enum_value, description) as (
    values
        ('codex/semantica-dena/base/data-type-ref.md', 'dena_data_type_ref', 'data_type_id', 'RECORDS', 'Expedientes.'),
        ('codex/semantica-dena/base/data-type-ref.md', 'dena_data_type_ref', 'data_type_id', 'NOTICES', 'Notificaciones.'),
        ('codex/semantica-dena/base/data-type-ref.md', 'dena_data_type_ref', 'data_type_id', 'REGISTRY', 'Registros oficiales.'),
        ('codex/semantica-dena/base/data-type-ref.md', 'dena_data_type_ref', 'data_type_id', 'PAYMENTS', 'Pagos.'),
        ('codex/semantica-dena/base/data-type-ref.md', 'dena_data_type_ref', 'data_type_id', 'SCHEDULE', 'Citas.'),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'expediente_state_code', 'REGISTERED_PENDING_TO_BE_OPENED', null),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'expediente_state_code', 'OPENED', null),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'expediente_state_code', 'IN_PROGRESS', null),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'expediente_state_code', 'WAITING_FOR_INTERESTED_PARTY_RESPONSE', null),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'expediente_state_code', 'WAITING_FOR_OTHER_ORG_WORK', null),
        ('codex/semantica-dena/data-retrieve/expediente.md', 'dena_expediente', 'expediente_state_code', 'CLOSED', null),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'notificacion_state', 'PENDING_TO_BE_READED_BY_DESTINATION', null),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'notificacion_state', 'ACKNOWLEDGED_BY_DESTINATION', null),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'notificacion_state', 'REJECTED_BY_DESTINATION', null),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'notificacion_state', 'EXPIRED', null),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'notificacion_state', 'CANCELLED_BY_ISSUER', null),
        ('codex/semantica-dena/data-retrieve/notificacion.md', 'dena_notificacion', 'notificacion_state', 'DELETED_BY_ISSUER', null),
        ('codex/semantica-dena/data-retrieve/registro-oficial.md', 'dena_registro_oficial', 'registro_state_code', 'PRESENTED', null),
        ('codex/semantica-dena/data-retrieve/registro-oficial.md', 'dena_registro_oficial', 'registro_state_code', 'RECEIVED_FROM_OTHER_ORG_UNIT', null),
        ('codex/semantica-dena/data-retrieve/registro-oficial.md', 'dena_registro_oficial', 'registro_state_code', 'TRANSFERRED_FROM_OTHER_ORG_UNIT', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'payment_status', 'COMPLETED', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'payment_status', 'PENDING', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'payment_status', 'REJECTED_BY_PAYMENT_PROCESSOR', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'payment_status', 'CANCELLED_BY_ISSUER', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'payment_status', 'ERROR_WHEN_PROCESSING_PAYMENT', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_frequency', 'WEEKLY', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_frequency', 'BIWEEKLY', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_frequency', 'MONTHLY', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_frequency', 'BIMONTHLY', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_frequency', 'QUARTERLY', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_frequency', 'BIANNUAL', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_frequency', 'ANNUAL', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_status', 'ACTIVE', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_status', 'CANCELED', null),
        ('codex/semantica-dena/data-retrieve/pago.md', 'dena_pago', 'direct_debit_status', 'EXPIRED', null),
        ('codex/semantica-dena/data-retrieve/cita.md', 'dena_cita', 'cita_priority', 'HIGH', null),
        ('codex/semantica-dena/data-retrieve/cita.md', 'dena_cita', 'cita_priority', 'MEDIUM', null),
        ('codex/semantica-dena/data-retrieve/cita.md', 'dena_cita', 'cita_priority', 'NORMAL', null),
        ('codex/semantica-dena/data-retrieve/cita.md', 'dena_cita', 'cita_priority', 'LOW', null),
        ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'dena_unidad_organica', 'org_unit_role', 'RESPONSIBLE', null),
        ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'dena_unidad_organica', 'org_unit_role', 'MANAGING', null),
        ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'dena_unidad_organica', 'org_unit_role', 'INFORMER', null),
        ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'dena_unidad_organica', 'org_unit_role', 'SOLVER', null),
        ('codex/semantica-dena/data-retrieve/unidad-organica.md', 'dena_unidad_organica', 'org_unit_role', 'OTHER', null),
        ('codex/semantica-dena/metadata-sync/pop-message-after-sync-spec.md', 'dena_pop_message_after_sync', 'pop_message_how', 'PUSH_TO_CLIENT_AT_CORE', null),
        ('codex/semantica-dena/metadata-sync/pop-message-after-sync-spec.md', 'dena_pop_message_after_sync', 'pop_message_how', 'AT_CLIENT_AFTER_SYNC', null),
        ('codex/semantica-dena/person-sync/export-spec.md', 'dena_person_export_spec', 'export_file_format', 'SQLITE', null),
        ('codex/semantica-dena/person-sync/export-spec.md', 'dena_person_export_spec', 'export_file_format', 'CSV', null),
        ('codex/semantica-dena/person-sync/export-spec.md', 'dena_person_export_spec', 'export_file_format', 'ZIP_OF_JSON', null),
        ('codex/semantica-dena/person-sync/export-spec.md', 'dena_person_export_spec', 'export_file_format', 'PARQUET', null),
        ('codex/semantica-dena/person-sync/person-push-data.md', 'dena_person_push_event', 'sync_event', 'CREATED', null),
        ('codex/semantica-dena/person-sync/person-push-data.md', 'dena_person_push_event', 'sync_event', 'DELETED', null),
        ('codex/semantica-dena/person-sync/person-push-data.md', 'dena_person_push_event', 'sync_event', 'UPDATED', null),
        ('codex/semantica-dena/person-sync/person-push-data.md', 'dena_person_push_event', 'sync_event', 'ID_CHANGED', null)
)
insert into dena_semantic_enum_value (
    source_document_pk,
    suggested_table,
    enum_name,
    enum_value,
    description
)
select
    d.source_document_pk,
    e.suggested_table,
    e.enum_name,
    e.enum_value,
    e.description
from enums e
join dena_source_document d on d.source_path = e.source_path
on conflict (enum_name, enum_value) do update
set
    suggested_table = excluded.suggested_table,
    description = excluded.description;
