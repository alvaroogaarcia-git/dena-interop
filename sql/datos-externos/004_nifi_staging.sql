-- Staging para sincronizar cambios de verticales.expedientes.admin_file
-- hacia el modelo DENA de datos_externos mediante NiFi.

set search_path = dena, public;

create table if not exists dena_admin_file_staging (
    source_id bigint not null,
    expediente_code text not null,
    title text not null,
    citizen_id text not null,
    source_system text not null,
    status text not null,
    amount_eur numeric(12,2) not null,
    opened_at timestamptz not null,
    updated_at timestamptz not null,
    staged_at timestamptz not null default now()
);

do $$
begin
    if exists (
        select 1
        from pg_constraint
        where conrelid = 'dena.dena_admin_file_staging'::regclass
          and contype in ('p', 'u')
    ) then
        alter table dena.dena_admin_file_staging
            drop constraint if exists dena_admin_file_staging_pkey,
            drop constraint if exists dena_admin_file_staging_expediente_code_key;
    end if;
end;
$$;

create index if not exists dena_admin_file_staging_updated_at_idx
    on dena_admin_file_staging (updated_at, source_id);

create index if not exists dena_admin_file_staging_source_id_idx
    on dena_admin_file_staging (source_id);

create or replace function dena_status_from_verticales(p_status text)
returns text
language sql
immutable
as $$
    select case lower(coalesce(p_status, ''))
        when 'archivado' then 'CLOSED'
        when 'resuelto' then 'CLOSED'
        when 'pendiente_documentacion' then 'WAITING_FOR_INTERESTED_PARTY_RESPONSE'
        when 'en_tramitacion' then 'IN_PROGRESS'
        when 'abierto' then 'OPENED'
        else 'OPENED'
    end;
$$;

create or replace function dena_admin_file_staging_to_dena()
returns integer
language plpgsql
security invoker
set search_path = pg_catalog, public, dena
as $$
declare
    v_rows integer := 0;
begin
    insert into dena_person (external_id, metadata)
    select distinct
        s.citizen_id,
        jsonb_build_object(
            'demo', true,
            'source', 'verticales',
            'lastTitle', s.title
        )
    from dena_admin_file_staging s
    on conflict (external_id) where external_id is not null do update
    set
        metadata = dena_person.metadata || excluded.metadata,
        updated_at = now();

    insert into dena_admin (external_oid, external_id, dir3_code, display_name, metadata)
    values (
        'adm-oid-verticales',
        'VERTICALES',
        'DEMO-VERT',
        'Sistema vertical demo',
        '{"demo": true, "source": "verticales"}'::jsonb
    )
    on conflict (external_oid) where external_oid is not null do update
    set
        external_id = excluded.external_id,
        dir3_code = excluded.dir3_code,
        display_name = excluded.display_name,
        metadata = excluded.metadata,
        updated_at = now();

    insert into dena_service (
        origin_ref_oid,
        origin_ref_id,
        dena_ref_id,
        sia_ref_id,
        service_name_by_language,
        metadata
    )
    values (
        'svc-oid-verticales',
        'SVC-VERTICALES',
        'DENA-SVC-VERTICALES',
        'SIA-VERTICALES',
        '{"SPANISH": "Expedientes del sistema vertical", "BASQUE": "Sistema bertikaleko espedienteak"}'::jsonb,
        '{"demo": true, "source": "verticales"}'::jsonb
    )
    on conflict (origin_ref_id) do update
    set
        service_name_by_language = excluded.service_name_by_language,
        metadata = excluded.metadata,
        updated_at = now();

    insert into dena_procedure (
        service_pk,
        procedure_name_by_language,
        origin_ref_oid,
        origin_ref_id,
        dena_ref_id,
        sia_ref_id,
        metadata
    )
    select
        service_pk,
        '{"SPANISH": "Tramitacion demo desde verticales", "BASQUE": "Bertikaletatik demo izapidetzea"}'::jsonb,
        'proc-oid-verticales',
        'PROC-VERTICALES',
        'DENA-PROC-VERTICALES',
        'SIA-PROC-VERTICALES',
        '{"demo": true, "source": "verticales"}'::jsonb
    from dena_service
    where origin_ref_id = 'SVC-VERTICALES'
    on conflict (origin_ref_id) do update
    set
        service_pk = excluded.service_pk,
        procedure_name_by_language = excluded.procedure_name_by_language,
        metadata = excluded.metadata,
        updated_at = now();

    with staged as (
        select
            s.*,
            dena_status_from_verticales(s.status) as dena_state_code
        from dena_admin_file_staging s
    ),
    resolved as (
        select
            staged.*,
            p.person_pk,
            a.admin_pk,
            svc.service_pk,
            proc.procedure_pk
        from staged
        join dena_person p on p.external_id = staged.citizen_id
        join dena_admin a on a.external_id = 'VERTICALES'
        join dena_service svc on svc.origin_ref_id = 'SVC-VERTICALES'
        join dena_procedure proc on proc.origin_ref_id = 'PROC-VERTICALES'
    ),
    upsert_objects as (
        insert into dena_business_object (
            object_kind,
            raw_type,
            external_oid,
            external_id,
            origin_admin_pk,
            about_person_pk,
            raw_payload,
            created_at,
            updated_at
        )
        select
            'EXPEDIENTE',
            'administrativeServiceProcedureRecord',
            'bo-exp-oid-' || lpad(source_id::text, 4, '0'),
            expediente_code,
            admin_pk,
            person_pk,
            jsonb_build_object(
                'demo', true,
                'source', 'verticales',
                'source_id', source_id,
                'id', expediente_code,
                'title', title,
                'source_status', status,
                'state', dena_state_code,
                'amount_eur', amount_eur,
                'updated_at', updated_at
            ),
            opened_at,
            updated_at
        from resolved
        on conflict (object_kind, external_oid) do update
        set
            external_id = excluded.external_id,
            origin_admin_pk = excluded.origin_admin_pk,
            about_person_pk = excluded.about_person_pk,
            raw_payload = excluded.raw_payload,
            updated_at = excluded.updated_at
        returning business_object_pk, external_oid
    )
    insert into dena_expediente (
        business_object_pk,
        service_pk,
        procedure_pk,
        created_at_ts,
        last_updated_at_ts,
        application_at_ts,
        reg_number,
        state_code,
        state_description_by_language,
        interested_party_id,
        interested_party_name,
        description_by_language
    )
    select
        bo.business_object_pk,
        r.service_pk,
        r.procedure_pk,
        r.opened_at,
        r.updated_at,
        r.opened_at,
        'REG-' || lpad(r.source_id::text, 6, '0'),
        r.dena_state_code,
        jsonb_build_object(
            'SPANISH', r.status,
            'BASQUE', r.status
        ),
        r.citizen_id,
        r.citizen_id,
        jsonb_build_object(
            'SPANISH', r.title,
            'BASQUE', r.title
        )
    from resolved r
    join upsert_objects bo on bo.external_oid = 'bo-exp-oid-' || lpad(r.source_id::text, 4, '0')
    on conflict (business_object_pk) do update
    set
        service_pk = excluded.service_pk,
        procedure_pk = excluded.procedure_pk,
        created_at_ts = excluded.created_at_ts,
        last_updated_at_ts = excluded.last_updated_at_ts,
        application_at_ts = excluded.application_at_ts,
        reg_number = excluded.reg_number,
        state_code = excluded.state_code,
        state_description_by_language = excluded.state_description_by_language,
        interested_party_id = excluded.interested_party_id,
        interested_party_name = excluded.interested_party_name,
        description_by_language = excluded.description_by_language;

    get diagnostics v_rows = row_count;

    truncate dena_admin_file_staging;
    return v_rows;
end;
$$;

create or replace function dena_apply_admin_file_row_to_dena()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, dena
as $$
declare
    v_state_code text;
    v_person_pk bigint;
    v_admin_pk bigint;
    v_service_pk bigint;
    v_procedure_pk bigint;
    v_business_object_pk bigint;
begin
    v_state_code := dena_status_from_verticales(new.status);

    delete from dena_admin_file_staging
    where source_id = new.source_id
      and staged_at < new.staged_at;

    insert into dena_person (external_id, metadata)
    values (
        new.citizen_id,
        jsonb_build_object(
            'demo', true,
            'source', 'verticales',
            'lastTitle', new.title
        )
    )
    on conflict (external_id) where external_id is not null do update
    set
        metadata = dena_person.metadata || excluded.metadata,
        updated_at = now()
    returning person_pk into v_person_pk;

    if v_person_pk is null then
        select person_pk into v_person_pk
        from dena_person
        where external_id = new.citizen_id;
    end if;

    insert into dena_admin (external_oid, external_id, dir3_code, display_name, metadata)
    values (
        'adm-oid-verticales',
        'VERTICALES',
        'DEMO-VERT',
        'Sistema vertical demo',
        '{"demo": true, "source": "verticales"}'::jsonb
    )
    on conflict (external_oid) where external_oid is not null do update
    set
        external_id = excluded.external_id,
        dir3_code = excluded.dir3_code,
        display_name = excluded.display_name,
        metadata = excluded.metadata,
        updated_at = now()
    returning admin_pk into v_admin_pk;

    if v_admin_pk is null then
        select admin_pk into v_admin_pk
        from dena_admin
        where external_id = 'VERTICALES';
    end if;

    insert into dena_service (
        origin_ref_oid,
        origin_ref_id,
        dena_ref_id,
        sia_ref_id,
        service_name_by_language,
        metadata
    )
    values (
        'svc-oid-verticales',
        'SVC-VERTICALES',
        'DENA-SVC-VERTICALES',
        'SIA-VERTICALES',
        '{"SPANISH": "Expedientes del sistema vertical", "BASQUE": "Sistema bertikaleko espedienteak"}'::jsonb,
        '{"demo": true, "source": "verticales"}'::jsonb
    )
    on conflict (origin_ref_id) do update
    set
        service_name_by_language = excluded.service_name_by_language,
        metadata = excluded.metadata,
        updated_at = now()
    returning service_pk into v_service_pk;

    if v_service_pk is null then
        select service_pk into v_service_pk
        from dena_service
        where origin_ref_id = 'SVC-VERTICALES';
    end if;

    insert into dena_procedure (
        service_pk,
        procedure_name_by_language,
        origin_ref_oid,
        origin_ref_id,
        dena_ref_id,
        sia_ref_id,
        metadata
    )
    values (
        v_service_pk,
        '{"SPANISH": "Tramitacion demo desde verticales", "BASQUE": "Bertikaletatik demo izapidetzea"}'::jsonb,
        'proc-oid-verticales',
        'PROC-VERTICALES',
        'DENA-PROC-VERTICALES',
        'SIA-PROC-VERTICALES',
        '{"demo": true, "source": "verticales"}'::jsonb
    )
    on conflict (origin_ref_id) do update
    set
        service_pk = excluded.service_pk,
        procedure_name_by_language = excluded.procedure_name_by_language,
        metadata = excluded.metadata,
        updated_at = now()
    returning procedure_pk into v_procedure_pk;

    if v_procedure_pk is null then
        select procedure_pk into v_procedure_pk
        from dena_procedure
        where origin_ref_id = 'PROC-VERTICALES';
    end if;

    insert into dena_business_object (
        object_kind,
        raw_type,
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        raw_payload,
        created_at,
        updated_at
    )
    values (
        'EXPEDIENTE',
        'administrativeServiceProcedureRecord',
        'bo-exp-oid-' || lpad(new.source_id::text, 4, '0'),
        new.expediente_code,
        v_admin_pk,
        v_person_pk,
        jsonb_build_object(
            'demo', true,
            'source', 'verticales',
            'source_id', new.source_id,
            'id', new.expediente_code,
            'title', new.title,
            'source_status', new.status,
            'state', v_state_code,
            'amount_eur', new.amount_eur,
            'updated_at', new.updated_at
        ),
        new.opened_at,
        new.updated_at
    )
    on conflict (object_kind, external_oid) do update
    set
        external_id = excluded.external_id,
        origin_admin_pk = excluded.origin_admin_pk,
        about_person_pk = excluded.about_person_pk,
        raw_payload = excluded.raw_payload,
        updated_at = excluded.updated_at
    returning business_object_pk into v_business_object_pk;

    insert into dena_expediente (
        business_object_pk,
        service_pk,
        procedure_pk,
        created_at_ts,
        last_updated_at_ts,
        application_at_ts,
        reg_number,
        state_code,
        state_description_by_language,
        interested_party_id,
        interested_party_name,
        description_by_language
    )
    values (
        v_business_object_pk,
        v_service_pk,
        v_procedure_pk,
        new.opened_at,
        new.updated_at,
        new.opened_at,
        'REG-' || lpad(new.source_id::text, 6, '0'),
        v_state_code,
        jsonb_build_object('SPANISH', new.status, 'BASQUE', new.status),
        new.citizen_id,
        new.citizen_id,
        jsonb_build_object('SPANISH', new.title, 'BASQUE', new.title)
    )
    on conflict (business_object_pk) do update
    set
        service_pk = excluded.service_pk,
        procedure_pk = excluded.procedure_pk,
        created_at_ts = excluded.created_at_ts,
        last_updated_at_ts = excluded.last_updated_at_ts,
        application_at_ts = excluded.application_at_ts,
        reg_number = excluded.reg_number,
        state_code = excluded.state_code,
        state_description_by_language = excluded.state_description_by_language,
        interested_party_id = excluded.interested_party_id,
        interested_party_name = excluded.interested_party_name,
        description_by_language = excluded.description_by_language;

    return new;
end;
$$;

drop trigger if exists trg_dena_admin_file_staging_to_dena
    on dena_admin_file_staging;

create trigger trg_dena_admin_file_staging_to_dena
after insert on dena_admin_file_staging
for each row
execute function dena_apply_admin_file_row_to_dena();

revoke all on table dena_admin_file_staging from public;
revoke all on function dena_status_from_verticales(text) from public;
revoke all on function dena_admin_file_staging_to_dena() from public;
revoke all on function dena_apply_admin_file_row_to_dena() from public;
