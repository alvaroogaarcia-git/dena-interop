-- DENA interoperability schema
-- Target engine: PostgreSQL 15+
--
-- Design criteria:
-- 1. Main business entities are normalized.
-- 2. LanguageTexts and unstable source fragments are stored as JSONB.
-- 3. Repeated arrays with operational value are split into child tables.
-- 4. Ambiguities detected in the public documentation are preserved through
--    raw fields instead of over-constraining the model.

create schema if not exists dena;
set search_path = dena, public;

-- ============================================================================
-- Shared master data
-- ============================================================================

create table if not exists dena_admin (
    admin_pk bigint generated always as identity primary key,
    external_oid text,
    external_id text,
    dir3_code text,
    display_name text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists ux_dena_admin_external_oid
    on dena_admin (external_oid)
    where external_oid is not null;

create unique index if not exists ux_dena_admin_external_id
    on dena_admin (external_id)
    where external_id is not null;

create unique index if not exists ux_dena_admin_dir3_code
    on dena_admin (dir3_code)
    where dir3_code is not null;

create table if not exists dena_person (
    person_pk bigint generated always as identity primary key,
    external_oid text,
    external_id text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists ux_dena_person_external_oid
    on dena_person (external_oid)
    where external_oid is not null;

create unique index if not exists ux_dena_person_external_id
    on dena_person (external_id)
    where external_id is not null;

create table if not exists dena_data_type (
    data_type_pk bigint generated always as identity primary key,
    external_oid text,
    external_id text,
    canonical_code text,
    description text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create unique index if not exists ux_dena_data_type_external_oid
    on dena_data_type (external_oid)
    where external_oid is not null;

create unique index if not exists ux_dena_data_type_external_id
    on dena_data_type (external_id)
    where external_id is not null;

insert into dena_data_type (external_id, canonical_code, description)
values
    ('RECORDS',  'RECORDS',  'Expedientes'),
    ('NOTICES',  'NOTICES',  'Notificaciones'),
    ('REGISTRY', 'REGISTRY', 'Registros oficiales'),
    ('PAYMENTS', 'PAYMENTS', 'Pagos'),
    ('SCHEDULE', 'SCHEDULE', 'Citas')
on conflict do nothing;

-- ============================================================================
-- Message envelope and traceability
-- ============================================================================

create table if not exists dena_interop_message (
    message_pk bigint generated always as identity primary key,
    message_correlation_id text not null,
    message_type text not null,
    flow_direction text not null check (flow_direction in ('REQUEST', 'RESPONSE')),
    user_agent text,
    origin_party_id text,
    destination_party_id text,
    client_device_oid text,
    subject_person_pk bigint references dena_person (person_pk),
    administration_pk bigint references dena_admin (admin_pk),
    data_type_pk bigint references dena_data_type (data_type_pk),
    consent_oid text,
    protocol_urls jsonb,
    protocol_timeout text,
    status_code text,
    error_id text,
    details jsonb,
    raw_context jsonb not null default '{}'::jsonb,
    raw_data jsonb,
    received_at timestamptz not null default now()
);

create index if not exists ix_dena_interop_message_corr
    on dena_interop_message (message_correlation_id);

create index if not exists ix_dena_interop_message_type
    on dena_interop_message (message_type);

create table if not exists dena_interop_message_route (
    route_pk bigint generated always as identity primary key,
    message_pk bigint not null references dena_interop_message (message_pk) on delete cascade,
    route_order integer not null,
    dena_component_id text not null,
    route_timestamp_ts timestamptz,
    route_timestamp_epoch_ms bigint,
    route_timestamp_raw text,
    created_at timestamptz not null default now(),
    unique (message_pk, route_order)
);

-- ============================================================================
-- Common business object base for DATA-RETRIEVE entities
-- ============================================================================

create table if not exists dena_business_object (
    business_object_pk bigint generated always as identity primary key,
    source_message_pk bigint references dena_interop_message (message_pk),
    object_kind text not null check (
        object_kind in (
            'EXPEDIENTE',
            'NOTIFICACION',
            'REGISTRO_OFICIAL',
            'PAGO_UNICO',
            'DOMICILIACION',
            'CITA',
            'PERSONA'
        )
    ),
    raw_type text not null,
    external_oid text not null,
    external_id text not null,
    origin_admin_pk bigint references dena_admin (admin_pk),
    about_person_pk bigint references dena_person (person_pk),
    raw_payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (object_kind, external_oid)
);

create index if not exists ix_dena_business_object_external_id
    on dena_business_object (object_kind, external_id);

create table if not exists dena_business_object_url (
    object_url_pk bigint generated always as identity primary key,
    business_object_pk bigint not null references dena_business_object (business_object_pk) on delete cascade,
    url text not null,
    language_code text,
    tags text[] not null default '{}'::text[],
    created_at timestamptz not null default now()
);

-- ============================================================================
-- Administrative catalog context
-- ============================================================================

create table if not exists dena_org_unit (
    org_unit_pk bigint generated always as identity primary key,
    external_oid text,
    external_id text not null,
    dir3_id text,
    display_name_by_language jsonb not null default '{}'::jsonb,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists ux_dena_org_unit_external_oid
    on dena_org_unit (external_oid)
    where external_oid is not null;

create unique index if not exists ux_dena_org_unit_external_id
    on dena_org_unit (external_id);

create table if not exists dena_org_unit_url (
    org_unit_url_pk bigint generated always as identity primary key,
    org_unit_pk bigint not null references dena_org_unit (org_unit_pk) on delete cascade,
    url text not null,
    language_code text,
    created_at timestamptz not null default now()
);

create table if not exists dena_service (
    service_pk bigint generated always as identity primary key,
    service_name_by_language jsonb not null default '{}'::jsonb,
    origin_ref_oid text,
    origin_ref_id text not null,
    dena_ref_oid text,
    dena_ref_id text,
    sia_ref_oid text,
    sia_ref_id text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (origin_ref_id)
);

create table if not exists dena_service_ref_url (
    service_ref_url_pk bigint generated always as identity primary key,
    service_pk bigint not null references dena_service (service_pk) on delete cascade,
    ref_scope text not null check (ref_scope in ('ORIGIN', 'DENA', 'SIA', 'SERVICE')),
    url text not null,
    language_code text,
    created_at timestamptz not null default now()
);

create table if not exists dena_service_org_unit (
    service_org_unit_pk bigint generated always as identity primary key,
    service_pk bigint not null references dena_service (service_pk) on delete cascade,
    org_unit_pk bigint not null references dena_org_unit (org_unit_pk),
    role_code text not null check (role_code in ('RESPONSIBLE', 'MANAGING', 'INFORMER', 'SOLVER', 'OTHER')),
    created_at timestamptz not null default now(),
    unique (service_pk, org_unit_pk, role_code)
);

create table if not exists dena_procedure (
    procedure_pk bigint generated always as identity primary key,
    service_pk bigint references dena_service (service_pk),
    procedure_name_by_language jsonb not null default '{}'::jsonb,
    origin_ref_oid text,
    origin_ref_id text not null,
    dena_ref_oid text,
    dena_ref_id text,
    sia_ref_oid text,
    sia_ref_id text,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (origin_ref_id)
);

create table if not exists dena_procedure_ref_url (
    procedure_ref_url_pk bigint generated always as identity primary key,
    procedure_pk bigint not null references dena_procedure (procedure_pk) on delete cascade,
    ref_scope text not null check (ref_scope in ('ORIGIN', 'DENA', 'SIA', 'PROCEDURE')),
    url text not null,
    language_code text,
    created_at timestamptz not null default now()
);

create table if not exists dena_procedure_org_unit (
    procedure_org_unit_pk bigint generated always as identity primary key,
    procedure_pk bigint not null references dena_procedure (procedure_pk) on delete cascade,
    org_unit_pk bigint not null references dena_org_unit (org_unit_pk),
    role_code text not null check (role_code in ('RESPONSIBLE', 'MANAGING', 'INFORMER', 'SOLVER', 'OTHER')),
    created_at timestamptz not null default now(),
    unique (procedure_pk, org_unit_pk, role_code)
);

-- ============================================================================
-- DATA-RETRIEVE domain tables
-- ============================================================================

create table if not exists dena_expediente (
    business_object_pk bigint primary key references dena_business_object (business_object_pk) on delete cascade,
    service_pk bigint not null references dena_service (service_pk),
    procedure_pk bigint not null references dena_procedure (procedure_pk),
    created_at_ts timestamptz not null,
    last_updated_at_ts timestamptz,
    application_at_ts timestamptz,
    reg_number text,
    state_code text not null check (
        state_code in (
            'REGISTERED_PENDING_TO_BE_OPENED',
            'OPENED',
            'IN_PROGRESS',
            'WAITING_FOR_INTERESTED_PARTY_RESPONSE',
            'WAITING_FOR_OTHER_ORG_WORK',
            'CLOSED'
        )
    ),
    state_description_by_language jsonb,
    interested_party_id text,
    interested_party_name text,
    description_by_language jsonb,
    constraint ck_dena_expediente_last_updated
        check (last_updated_at_ts is null or last_updated_at_ts >= created_at_ts)
);

create table if not exists dena_notificacion (
    business_object_pk bigint primary key references dena_business_object (business_object_pk) on delete cascade,
    expediente_object_pk bigint not null references dena_expediente (business_object_pk),
    notice_kind text check (notice_kind in ('OFFICIAL_NOTICE', 'COMMUNICATION')),
    issued_at_ts timestamptz not null,
    read_at_ts timestamptz,
    state_code text not null check (
        state_code in (
            'PENDING_TO_BE_READED_BY_DESTINATION',
            'ACKNOWLEDGED_BY_DESTINATION',
            'REJECTED_BY_DESTINATION',
            'EXPIRED',
            'CANCELLED_BY_ISSUER',
            'DELETED_BY_ISSUER'
        )
    ),
    act_subject_by_language jsonb not null default '{}'::jsonb
);

create table if not exists dena_registro_oficial (
    business_object_pk bigint primary key references dena_business_object (business_object_pk) on delete cascade,
    expediente_object_pk bigint not null references dena_expediente (business_object_pk),
    registered_at_ts timestamptz not null,
    subject_by_language jsonb not null default '{}'::jsonb,
    state_code text not null check (
        state_code in (
            'PRESENTED',
            'RECEIVED_FROM_OTHER_ORG_UNIT',
            'TRANSFERRED_FROM_OTHER_ORG_UNIT'
        )
    ),
    state_description_by_language jsonb
);

create table if not exists dena_pago (
    business_object_pk bigint primary key references dena_business_object (business_object_pk) on delete cascade,
    expediente_object_pk bigint not null references dena_expediente (business_object_pk),
    payment_variant text not null check (payment_variant in ('ONE_OFF', 'DIRECT_DEBIT')),
    payment_type text not null check (payment_type in ('ONE_OFF_PAYMENT', 'DIRECT_DEBIT')),
    payment_subject_by_language jsonb not null default '{}'::jsonb,

    -- One-off payment fields
    one_off_format_code text,
    one_off_schema_json jsonb,
    one_off_due_date date,
    one_off_surcharged_at date,
    one_off_paid_at date,
    one_off_amount numeric(18,2),
    one_off_currency char(3),
    one_off_amount_if_surcharged numeric(18,2),
    one_off_surcharged_currency char(3),
    one_off_status text check (
        one_off_status in (
            'COMPLETED',
            'PENDING',
            'REJECTED_BY_PAYMENT_PROCESSOR',
            'CANCELLED_BY_ISSUER',
            'ERROR_WHEN_PROCESSING_PAYMENT'
        )
    ),
    one_off_status_at timestamptz,
    one_off_medium text check (
        one_off_medium in (
            'PAYMENT_CARD',
            'ACCOUNT_TRANSFER',
            'BIZUM',
            'CASH',
            'DIRECT_DEBIT'
        )
    ),
    one_off_device text check (
        one_off_device in (
            'WEB_BROWSER',
            'MOBILE_APP',
            'IN_PERSON_FINANCIAL_ENTITY',
            'IN_PERSON_OTHER',
            'ATM'
        )
    ),
    payment_processor_id text,
    payment_processor_tx_id text,
    one_off_message_by_language jsonb,

    -- Direct debit fields
    dd_start_date date,
    dd_expires_at date,
    dd_frequency text check (
        dd_frequency in (
            'WEEKLY',
            'BIWEEKLY',
            'MONTHLY',
            'BIMONTHLY',
            'QUARTERLY',
            'BIANNUAL',
            'ANNUAL'
        )
    ),
    dd_medium text check (
        dd_medium in (
            'PAYMENT_CARD',
            'ACCOUNT_TRANSFER',
            'BIZUM',
            'CASH',
            'DIRECT_DEBIT'
        )
    ),
    dd_medium_hint text,
    next_charge_at date,
    next_charge_amount_eur numeric(18,2),
    dd_status text check (dd_status in ('ACTIVE', 'CANCELED', 'EXPIRED')),

    constraint ck_dena_pago_variant_one_off check (
        payment_variant <> 'ONE_OFF'
        or (
            one_off_due_date is not null
            and one_off_amount is not null
            and one_off_currency is not null
            and one_off_status is not null
        )
    ),
    constraint ck_dena_pago_variant_direct_debit check (
        payment_variant <> 'DIRECT_DEBIT'
        or (
            dd_start_date is not null
            and dd_frequency is not null
        )
    )
);

create table if not exists dena_pago_historial (
    pago_historial_pk bigint generated always as identity primary key,
    business_object_pk bigint not null references dena_pago (business_object_pk) on delete cascade,
    charged_at date not null,
    amount_eur numeric(18,2) not null,
    created_at timestamptz not null default now()
);

create table if not exists dena_pago_org_unit (
    pago_org_unit_pk bigint generated always as identity primary key,
    business_object_pk bigint not null references dena_pago (business_object_pk) on delete cascade,
    org_unit_pk bigint not null references dena_org_unit (org_unit_pk),
    role_code text not null check (role_code in ('RESPONSIBLE', 'MANAGING', 'INFORMER', 'SOLVER', 'OTHER')),
    created_at timestamptz not null default now(),
    unique (business_object_pk, org_unit_pk, role_code)
);

create table if not exists dena_cita (
    business_object_pk bigint primary key references dena_business_object (business_object_pk) on delete cascade,
    year_num integer not null,
    month_of_year integer not null check (month_of_year between 1 and 12),
    day_of_month integer not null check (day_of_month between 1 and 31),
    hour_of_day integer not null check (hour_of_day between 0 and 23),
    minute_of_hour integer not null check (minute_of_hour between 0 and 59),
    duration_minutes integer not null check (duration_minutes >= 0),
    priority_code text check (priority_code in ('HIGH', 'MEDIUM', 'NORMAL', 'LOW')),
    subject_by_language jsonb not null default '{}'::jsonb,
    details_by_language jsonb,
    location_country_id text,
    location_country_name text,
    location_area_level1_id text,
    location_area_level1_name text,
    location_area_level3_id text,
    location_area_level3_name text,
    location_zip_code text,
    location_address text,
    location_directions_by_language jsonb
);

create table if not exists dena_person_data (
    business_object_pk bigint primary key references dena_business_object (business_object_pk) on delete cascade,
    person_pk bigint references dena_person (person_pk),
    org_unit_pk bigint references dena_org_unit (org_unit_pk),
    party_id text not null,
    party_name text not null,
    party_surname text not null,
    birth_date_ts timestamptz,
    phone_1 text,
    phone_2 text,
    email text,
    contact_language text,
    contact_mode text check (contact_mode in ('POSTAL', 'ELECTRONIC'))
);

create table if not exists dena_person_address (
    person_address_pk bigint generated always as identity primary key,
    business_object_pk bigint not null references dena_person_data (business_object_pk) on delete cascade,
    address_role text not null check (address_role in ('MAIN', 'OTHER')),
    address_order integer not null default 1,
    address_description_by_language jsonb,
    country_nora_code text,
    country_desc_by_language jsonb,
    province_nora_code text,
    province_desc_by_language jsonb,
    municipality_nora_code text,
    municipality_desc_by_language jsonb,
    locality_nora_code text,
    locality_desc_by_language jsonb,
    address_line text,
    postal_code text,
    created_at timestamptz not null default now(),
    unique (business_object_pk, address_role, address_order)
);

create table if not exists dena_person_bank_account (
    bank_account_pk bigint generated always as identity primary key,
    business_object_pk bigint not null references dena_person_data (business_object_pk) on delete cascade,
    account_id text not null,
    account_id_type text not null check (account_id_type in ('IBAN', 'CUSTOM')),
    entity_name text,
    created_at timestamptz not null default now()
);

-- ============================================================================
-- METADATA-SYNC domain
-- ============================================================================

create table if not exists dena_sync_metadata_item (
    sync_metadata_pk bigint generated always as identity primary key,
    source_message_pk bigint references dena_interop_message (message_pk),
    admin_pk bigint not null references dena_admin (admin_pk),
    person_pk bigint not null references dena_person (person_pk),
    data_type_pk bigint references dena_data_type (data_type_pk),
    data_type_external_id text,
    some_data_was_updated_at timestamptz not null,
    pop_message_how text check (pop_message_how in ('PUSH_TO_CLIENT_AT_CORE', 'AT_CLIENT_AFTER_SYNC')),
    pop_message_by_language jsonb,
    raw_payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists ix_dena_sync_metadata_person_updated
    on dena_sync_metadata_item (person_pk, some_data_was_updated_at desc);

-- ============================================================================
-- PERSON-SYNC domain
-- ============================================================================

create table if not exists dena_person_push_event (
    person_push_pk bigint generated always as identity primary key,
    source_message_pk bigint references dena_interop_message (message_pk),
    person_pk bigint not null references dena_person (person_pk),
    target_admin_pk bigint references dena_admin (admin_pk),
    sync_event text not null check (sync_event in ('CREATED', 'DELETED', 'UPDATED', 'ID_CHANGED')),
    create_date_ts timestamptz not null,
    last_update_date_ts timestamptz,
    name_hash text not null,
    surname1_hash text not null,
    surname2_hash text,
    all_names_hash text not null,
    raw_payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists ix_dena_person_push_event_person
    on dena_person_push_event (person_pk, create_date_ts desc);

create table if not exists dena_person_export_request (
    person_export_request_pk bigint generated always as identity primary key,
    source_message_pk bigint references dena_interop_message (message_pk),
    admin_pk bigint not null references dena_admin (admin_pk),
    person_export_spec text not null check (person_export_spec in ('data', 'sync')),
    export_file_format text not null check (export_file_format in ('SQLITE', 'CSV', 'ZIP_OF_JSON', 'PARQUET')),
    last_update_range_text text,
    sync_event text check (sync_event in ('CREATED', 'DELETED', 'UPDATED', 'ID_CHANGED')),
    raw_payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

-- ============================================================================
-- Markdown source catalog
-- ============================================================================

create table if not exists dena_source_document (
    source_document_pk bigint generated always as identity primary key,
    source_path text not null unique,
    document_title text not null,
    document_group text not null,
    suggested_table text,
    source_version text,
    source_date date,
    content_sha256 text,
    loaded_at timestamptz not null default now()
);

create table if not exists dena_semantic_field (
    semantic_field_pk bigint generated always as identity primary key,
    source_document_pk bigint not null references dena_source_document (source_document_pk) on delete cascade,
    suggested_table text not null,
    field_path text not null,
    field_type text not null,
    required_level text not null,
    description text,
    created_at timestamptz not null default now(),
    unique (suggested_table, field_path)
);

create table if not exists dena_semantic_enum_value (
    semantic_enum_value_pk bigint generated always as identity primary key,
    source_document_pk bigint references dena_source_document (source_document_pk) on delete cascade,
    suggested_table text,
    enum_name text not null,
    enum_value text not null,
    description text,
    created_at timestamptz not null default now(),
    unique (enum_name, enum_value)
);

-- ============================================================================
-- Recommended comments for operators
-- ============================================================================

comment on schema dena is 'Esquema de consolidacion para la semantica DENA revisada a partir de DENA Docs v0.3.37 (2026-07-03).';
comment on table dena_interop_message is 'Cabecera comun de mensajes REST DENA. Permite auditar request/response y conservar payloads originales.';
comment on table dena_business_object is 'Clase base fisica de los objetos de DATA-RETRIEVE. Unifica oid/id, persona, administracion y raw payload.';
comment on table dena_notificacion is 'La especificacion publica es ambigua en el campo type; se conserva raw_type en dena_business_object y notice_kind separado aqui.';
comment on column dena_cita.location_directions_by_language is 'La documentacion oficial describe un bug de serializacion con address/directionsByLanguage. Mantener revision manual al integrar.';
comment on table dena_source_document is 'Inventario de Markdown usados para deducir el modelo fisico de datos externos.';
comment on table dena_semantic_field is 'Diccionario de campos extraido de las tablas de cada Markdown fuente.';
comment on table dena_semantic_enum_value is 'Valores enumerados publicados en los Markdown fuente.';
