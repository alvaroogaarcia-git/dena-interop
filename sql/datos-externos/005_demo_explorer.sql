-- Browser-friendly views for the DENA external data demo explorer.
-- They intentionally flatten the normalized DENA model into stable list/detail
-- records consumable from PostgREST and the admin console.

do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'dena_external_anon') then
        create role dena_external_anon nologin;
    end if;
end
$$;

drop view if exists public.dena_external_folders;
drop view if exists public.dena_external_semantica;
drop view if exists public.dena_external_personas;
drop view if exists public.dena_external_citas;
drop view if exists public.dena_external_pagos;
drop view if exists public.dena_external_notificaciones;
drop view if exists public.dena_external_expedientes;

create or replace view public.dena_external_expedientes as
select
    bo.external_id as id,
    bo.external_oid as oid,
    e.reg_number as referencia,
    coalesce(e.description_by_language ->> 'SPANISH', bo.external_id) as titulo,
    e.description_by_language as titulo_by_language,
    e.state_code as estado,
    e.state_description_by_language as estado_by_language,
    coalesce(e.last_updated_at_ts, e.created_at_ts) as fecha,
    e.created_at_ts as creado_en,
    e.application_at_ts as solicitado_en,
    e.interested_party_id as persona_id,
    e.interested_party_name as persona_nombre,
    coalesce(s.service_name_by_language ->> 'SPANISH', s.origin_ref_id) as servicio,
    s.service_name_by_language as servicio_by_language,
    coalesce(p.procedure_name_by_language ->> 'SPANISH', p.origin_ref_id) as procedimiento,
    p.procedure_name_by_language as procedimiento_by_language,
    a.display_name as administracion,
    bo.updated_at as sincronizado_en,
    jsonb_build_object(
        'tabla', 'dena_expediente',
        'expediente_pk', e.business_object_pk,
        'raw_payload', bo.raw_payload,
        'estado_descripcion', e.state_description_by_language
    ) as detalle
from dena.dena_expediente e
join dena.dena_business_object bo on bo.business_object_pk = e.business_object_pk
left join dena.dena_service s on s.service_pk = e.service_pk
left join dena.dena_procedure p on p.procedure_pk = e.procedure_pk
left join dena.dena_admin a on a.admin_pk = bo.origin_admin_pk;

create or replace view public.dena_external_notificaciones as
select
    bo.external_id as id,
    exp_bo.external_id as expediente_id,
    n.notice_kind as tipo,
    coalesce(n.act_subject_by_language ->> 'SPANISH', bo.external_id) as titulo,
    n.act_subject_by_language as titulo_by_language,
    n.state_code as estado,
    n.issued_at_ts as fecha,
    n.read_at_ts as leido_en,
    e.interested_party_id as persona_id,
    e.interested_party_name as persona_nombre,
    a.display_name as administracion,
    bo.updated_at as sincronizado_en,
    jsonb_build_object(
        'tabla', 'dena_notificacion',
        'notificacion_pk', n.business_object_pk,
        'expediente_pk', n.expediente_object_pk,
        'raw_payload', bo.raw_payload
    ) as detalle
from dena.dena_notificacion n
join dena.dena_business_object bo on bo.business_object_pk = n.business_object_pk
join dena.dena_expediente e on e.business_object_pk = n.expediente_object_pk
join dena.dena_business_object exp_bo on exp_bo.business_object_pk = e.business_object_pk
left join dena.dena_admin a on a.admin_pk = bo.origin_admin_pk;

create or replace view public.dena_external_pagos as
select
    bo.external_id as id,
    exp_bo.external_id as expediente_id,
    p.payment_type as tipo,
    coalesce(p.payment_subject_by_language ->> 'SPANISH', bo.external_id) as titulo,
    p.payment_subject_by_language as titulo_by_language,
    coalesce(p.one_off_status, p.dd_status) as estado,
    coalesce(p.one_off_status_at, p.next_charge_at::timestamptz, p.dd_start_date::timestamptz) as fecha,
    coalesce(p.one_off_amount, p.next_charge_amount_eur) as importe_eur,
    coalesce(p.one_off_currency, 'EUR') as moneda,
    p.payment_variant as variante,
    p.dd_frequency as frecuencia,
    e.interested_party_id as persona_id,
    e.interested_party_name as persona_nombre,
    bo.updated_at as sincronizado_en,
    jsonb_build_object(
        'tabla', 'dena_pago',
        'pago_pk', p.business_object_pk,
        'expediente_pk', p.expediente_object_pk,
        'medio', coalesce(p.one_off_medium, p.dd_medium),
        'procesador', p.payment_processor_id,
        'transaccion', p.payment_processor_tx_id
    ) as detalle
from dena.dena_pago p
join dena.dena_business_object bo on bo.business_object_pk = p.business_object_pk
join dena.dena_expediente e on e.business_object_pk = p.expediente_object_pk
join dena.dena_business_object exp_bo on exp_bo.business_object_pk = e.business_object_pk;

drop view if exists public.dena_external_folders;
drop view if exists public.dena_external_citas;

create or replace view public.dena_external_citas as
select
    bo.external_id as id,
    dp.external_id as persona_id,
    c.priority_code as prioridad,
    coalesce(c.subject_by_language ->> 'SPANISH', bo.external_id) as titulo,
    c.subject_by_language as titulo_by_language,
    c.priority_code as estado,
    make_timestamptz(c.year_num, c.month_of_year, c.day_of_month, c.hour_of_day, c.minute_of_hour, 0) as fecha,
    c.duration_minutes as duracion_minutos,
    concat_ws(', ', c.location_address, c.location_area_level3_name, c.location_zip_code) as ubicacion,
    bo.updated_at as sincronizado_en,
    jsonb_build_object(
        'tabla', 'dena_cita',
        'cita_pk', c.business_object_pk,
        'detalle', c.details_by_language,
        'indicaciones', c.location_directions_by_language
    ) as detalle
from dena.dena_cita c
join dena.dena_business_object bo on bo.business_object_pk = c.business_object_pk
left join dena.dena_person dp on dp.person_pk = bo.about_person_pk;

create or replace view public.dena_external_personas as
select
    bo.external_id as id,
    pd.party_id as persona_id,
    concat_ws(' ', pd.party_name, pd.party_surname) as titulo,
    jsonb_build_object(
        'SPANISH', concat_ws(' ', pd.party_name, pd.party_surname),
        'BASQUE', concat_ws(' ', pd.party_name, pd.party_surname),
        'ENGLISH', concat_ws(' ', pd.party_name, pd.party_surname)
    ) as titulo_by_language,
    pd.contact_mode as estado,
    pd.birth_date_ts as fecha,
    pd.email,
    pd.phone_1 as telefono,
    pd.contact_language as idioma,
    ou.display_name_by_language ->> 'SPANISH' as unidad,
    ou.display_name_by_language as unidad_by_language,
    bo.updated_at as sincronizado_en,
    jsonb_build_object(
        'tabla', 'dena_person_data',
        'persona_pk', pd.person_pk,
        'business_object_pk', pd.business_object_pk,
        'raw_payload', bo.raw_payload
    ) as detalle
from dena.dena_person_data pd
join dena.dena_business_object bo on bo.business_object_pk = pd.business_object_pk
left join dena.dena_org_unit ou on ou.org_unit_pk = pd.org_unit_pk;

create or replace view public.dena_external_semantica as
select
    sd.source_path as id,
    sd.document_group as grupo,
    sd.document_title as titulo,
    coalesce(sd.suggested_table, '-') as tabla_sugerida,
    sd.source_version as version,
    sd.source_date as fecha,
    count(sf.semantic_field_pk)::integer as campos,
    count(sev.semantic_enum_value_pk)::integer as enumerados,
    jsonb_build_object(
        'tabla', 'dena_source_document',
        'source_document_pk', sd.source_document_pk,
        'ruta_markdown', sd.source_path,
        'campos', jsonb_agg(distinct jsonb_build_object(
            'campo', sf.field_path,
            'tipo', sf.field_type,
            'requerido', sf.required_level,
            'descripcion', sf.description
        )) filter (where sf.semantic_field_pk is not null)
    ) as detalle
from dena.dena_source_document sd
left join dena.dena_semantic_field sf on sf.source_document_pk = sd.source_document_pk
left join dena.dena_semantic_enum_value sev on sev.source_document_pk = sd.source_document_pk
group by sd.source_document_pk;

create or replace view public.dena_external_folders as
select 'expedientes'::text as folder_id, 'Expedientes'::text as title, 'dena_external_expedientes'::text as endpoint, count(*)::integer as total from public.dena_external_expedientes
union all
select 'notificaciones', 'Notificaciones', 'dena_external_notificaciones', count(*)::integer from public.dena_external_notificaciones
union all
select 'pagos', 'Pagos', 'dena_external_pagos', count(*)::integer from public.dena_external_pagos
union all
select 'citas', 'Citas', 'dena_external_citas', count(*)::integer from public.dena_external_citas
union all
select 'personas', 'Personas', 'dena_external_personas', count(*)::integer from public.dena_external_personas
union all
select 'semantica', 'Semantica markdown', 'dena_external_semantica', count(*)::integer from public.dena_external_semantica;

grant usage on schema public to dena_external_anon;
grant select on
    public.dena_external_expedientes,
    public.dena_external_notificaciones,
    public.dena_external_pagos,
    public.dena_external_citas,
    public.dena_external_personas,
    public.dena_external_semantica,
    public.dena_external_folders
to dena_external_anon;

notify pgrst, 'reload schema';
