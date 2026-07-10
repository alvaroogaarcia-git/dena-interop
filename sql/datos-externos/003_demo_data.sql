-- Datos demo para la PostgreSQL aislada de datos externos DENA.
-- El seed es idempotente y genera un conjunto navegable desde psql o Mathesar.

set search_path = dena, public;

with admins(external_oid, external_id, dir3_code, display_name, metadata) as (
    values
        ('adm-oid-gv', 'EJGV', 'A16003011', 'Gobierno Vasco', '{"demo": true, "scope": "autonomico"}'::jsonb),
        ('adm-oid-bizkaia', 'DFB', 'L02000048', 'Diputacion Foral de Bizkaia', '{"demo": true, "scope": "foral"}'::jsonb),
        ('adm-oid-gipuzkoa', 'DFG', 'L02000020', 'Diputacion Foral de Gipuzkoa', '{"demo": true, "scope": "foral"}'::jsonb),
        ('adm-oid-araba', 'DFA', 'L02000001', 'Diputacion Foral de Araba', '{"demo": true, "scope": "foral"}'::jsonb),
        ('adm-oid-bilbao', 'BILBAO', 'L01480209', 'Ayuntamiento de Bilbao', '{"demo": true, "scope": "municipal"}'::jsonb)
)
insert into dena_admin (external_oid, external_id, dir3_code, display_name, metadata)
select external_oid, external_id, dir3_code, display_name, metadata
from admins
on conflict (external_oid) where external_oid is not null do update
set
    external_id = excluded.external_id,
    dir3_code = excluded.dir3_code,
    display_name = excluded.display_name,
    metadata = excluded.metadata,
    updated_at = now();

with people as (
    select
        gs,
        'person-oid-' || lpad(gs::text, 4, '0') as external_oid,
        'CIT-' || lpad((10000 + gs)::text, 5, '0') as external_id,
        jsonb_build_object(
            'demo', true,
            'name', format('Persona Demo %s', gs),
            'preferredLanguage', case when gs % 3 = 0 then 'BASQUE' else 'SPANISH' end
        ) as metadata
    from generate_series(1, 50) as gs
)
insert into dena_person (external_oid, external_id, metadata)
select external_oid, external_id, metadata
from people
on conflict (external_oid) where external_oid is not null do update
set
    external_id = excluded.external_id,
    metadata = excluded.metadata,
    updated_at = now();

with units(external_oid, external_id, dir3_id, name_es, name_eu) as (
    values
        ('ou-oid-001', 'OU-ATENCION-CIUDADANA', 'A16003011-U001', 'Atencion ciudadana', 'Herritarren arreta'),
        ('ou-oid-002', 'OU-REGISTRO', 'A16003011-U002', 'Registro general', 'Erregistro orokorra'),
        ('ou-oid-003', 'OU-TRIBUTOS', 'L02000048-U003', 'Gestion tributaria', 'Zergen kudeaketa'),
        ('ou-oid-004', 'OU-AYUDAS', 'L02000020-U004', 'Ayudas y subvenciones', 'Laguntzak eta dirulaguntzak'),
        ('ou-oid-005', 'OU-CITAS', 'L01480209-U005', 'Citas presenciales', 'Aurrez aurreko hitzorduak')
)
insert into dena_org_unit (external_oid, external_id, dir3_id, display_name_by_language, metadata)
select
    external_oid,
    external_id,
    dir3_id,
    jsonb_build_object('SPANISH', name_es, 'BASQUE', name_eu),
    '{"demo": true}'::jsonb
from units
on conflict (external_id) do update
set
    external_oid = excluded.external_oid,
    dir3_id = excluded.dir3_id,
    display_name_by_language = excluded.display_name_by_language,
    metadata = excluded.metadata,
    updated_at = now();

with services(origin_ref_oid, origin_ref_id, name_es, name_eu, sia_ref_id) as (
    values
        ('svc-oid-001', 'SVC-LICENCIAS', 'Licencias y autorizaciones', 'Lizentziak eta baimenak', 'SIA-0001'),
        ('svc-oid-002', 'SVC-AYUDAS', 'Ayudas ciudadanas', 'Herritarrentzako laguntzak', 'SIA-0002'),
        ('svc-oid-003', 'SVC-TRIBUTOS', 'Tributos y pagos', 'Zergak eta ordainketak', 'SIA-0003'),
        ('svc-oid-004', 'SVC-REGISTRO', 'Registro y documentacion', 'Erregistroa eta dokumentazioa', 'SIA-0004'),
        ('svc-oid-005', 'SVC-CITAS', 'Citas y atencion presencial', 'Hitzorduak eta arreta presentziala', 'SIA-0005'),
        ('svc-oid-006', 'SVC-PADRON', 'Padron y datos personales', 'Errolda eta datu pertsonalak', 'SIA-0006'),
        ('svc-oid-007', 'SVC-MOVILIDAD', 'Movilidad y transporte', 'Mugikortasuna eta garraioa', 'SIA-0007'),
        ('svc-oid-008', 'SVC-VIVIENDA', 'Vivienda', 'Etxebizitza', 'SIA-0008')
)
insert into dena_service (
    origin_ref_oid,
    origin_ref_id,
    dena_ref_id,
    sia_ref_id,
    service_name_by_language,
    metadata
)
select
    origin_ref_oid,
    origin_ref_id,
    'DENA-' || origin_ref_id,
    sia_ref_id,
    jsonb_build_object('SPANISH', name_es, 'BASQUE', name_eu),
    '{"demo": true}'::jsonb
from services
on conflict (origin_ref_id) do update
set
    origin_ref_oid = excluded.origin_ref_oid,
    dena_ref_id = excluded.dena_ref_id,
    sia_ref_id = excluded.sia_ref_id,
    service_name_by_language = excluded.service_name_by_language,
    metadata = excluded.metadata,
    updated_at = now();

insert into dena_service_org_unit (service_pk, org_unit_pk, role_code)
select s.service_pk, u.org_unit_pk, role_code
from dena_service s
join lateral (
    select org_unit_pk
    from dena_org_unit
    order by org_unit_pk
    offset ((abs(hashtext(s.origin_ref_id)) % 5))
    limit 1
) u on true
cross join lateral (values ('RESPONSIBLE'), ('MANAGING')) as roles(role_code)
where s.metadata ->> 'demo' = 'true'
on conflict (service_pk, org_unit_pk, role_code) do nothing;

with procedures as (
    select
        gs,
        s.service_pk,
        'proc-oid-' || lpad(gs::text, 3, '0') as origin_ref_oid,
        'PROC-' || lpad(gs::text, 3, '0') as origin_ref_id,
        jsonb_build_object(
            'SPANISH', format('Procedimiento demo %s de %s', gs, s.origin_ref_id),
            'BASQUE', format('%s prozedura demoa %s', s.origin_ref_id, gs)
        ) as procedure_name_by_language
    from generate_series(1, 12) as gs
    join dena_service s on s.origin_ref_id = (
        array[
            'SVC-LICENCIAS',
            'SVC-AYUDAS',
            'SVC-TRIBUTOS',
            'SVC-REGISTRO',
            'SVC-CITAS',
            'SVC-PADRON',
            'SVC-MOVILIDAD',
            'SVC-VIVIENDA'
        ])[((gs - 1) % 8) + 1]
)
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
    procedure_name_by_language,
    origin_ref_oid,
    origin_ref_id,
    'DENA-' || origin_ref_id,
    'SIA-PROC-' || lpad(gs::text, 3, '0'),
    '{"demo": true}'::jsonb
from procedures
on conflict (origin_ref_id) do update
set
    service_pk = excluded.service_pk,
    procedure_name_by_language = excluded.procedure_name_by_language,
    origin_ref_oid = excluded.origin_ref_oid,
    dena_ref_id = excluded.dena_ref_id,
    sia_ref_id = excluded.sia_ref_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into dena_procedure_org_unit (procedure_pk, org_unit_pk, role_code)
select p.procedure_pk, u.org_unit_pk, 'RESPONSIBLE'
from dena_procedure p
join dena_service_org_unit sou on sou.service_pk = p.service_pk and sou.role_code = 'RESPONSIBLE'
join dena_org_unit u on u.org_unit_pk = sou.org_unit_pk
where p.metadata ->> 'demo' = 'true'
on conflict (procedure_pk, org_unit_pk, role_code) do nothing;

with base_messages as (
    select
        gs,
        p.person_pk,
        a.admin_pk,
        dt.data_type_pk,
        format('corr-demo-%s', lpad(gs::text, 4, '0')) as corr_id,
        case
            when gs % 5 = 0 then 'SCHEDULE'
            when gs % 4 = 0 then 'PAYMENTS'
            when gs % 3 = 0 then 'NOTICES'
            else 'RECORDS'
        end as data_type_id
    from generate_series(1, 50) as gs
    join dena_person p on p.external_id = 'CIT-' || lpad((10000 + gs)::text, 5, '0')
    join dena_admin a on a.external_id = (
        array['EJGV', 'DFB', 'DFG', 'DFA', 'BILBAO']
    )[((gs - 1) % 5) + 1]
    join dena_data_type dt on dt.external_id = case
        when gs % 5 = 0 then 'SCHEDULE'
        when gs % 4 = 0 then 'PAYMENTS'
        when gs % 3 = 0 then 'NOTICES'
        else 'RECORDS'
    end
)
insert into dena_interop_message (
    message_correlation_id,
    message_type,
    flow_direction,
    user_agent,
    origin_party_id,
    destination_party_id,
    subject_person_pk,
    administration_pk,
    data_type_pk,
    status_code,
    raw_context,
    raw_data,
    received_at
)
select
    corr_id,
    'DATA_RETRIEVE_RESPONSE',
    'RESPONSE',
    'dena-interop-demo/1.0',
    'vertical-demo',
    'dena-core-demo',
    person_pk,
    admin_pk,
    data_type_pk,
    '200',
    jsonb_build_object('demo', true, 'messageCorrelationId', corr_id),
    jsonb_build_object('demo', true, 'dataType', data_type_id),
    now() - make_interval(hours => gs)
from base_messages
where not exists (
    select 1
    from dena_interop_message m
    where m.message_correlation_id = base_messages.corr_id
);

insert into dena_interop_message_route (
    message_pk,
    route_order,
    dena_component_id,
    route_timestamp_ts,
    route_timestamp_epoch_ms,
    route_timestamp_raw
)
select
    m.message_pk,
    route_order,
    component_id,
    m.received_at + make_interval(secs => route_order),
    floor(extract(epoch from m.received_at + make_interval(secs => route_order)) * 1000)::bigint,
    to_char(m.received_at + make_interval(secs => route_order), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
from dena_interop_message m
cross join (values (1, 'vertical-demo'), (2, 'nifi-demo'), (3, 'datos-externos-demo')) as r(route_order, component_id)
where m.message_correlation_id like 'corr-demo-%'
on conflict (message_pk, route_order) do update
set
    dena_component_id = excluded.dena_component_id,
    route_timestamp_ts = excluded.route_timestamp_ts,
    route_timestamp_epoch_ms = excluded.route_timestamp_epoch_ms,
    route_timestamp_raw = excluded.route_timestamp_raw;

with expediente_base as (
    select
        gs,
        'EXP-' || lpad(gs::text, 4, '0') as expediente_id,
        'bo-exp-oid-' || lpad(gs::text, 4, '0') as external_oid,
        p.person_pk,
        a.admin_pk,
        m.message_pk,
        proc.procedure_pk,
        proc.service_pk,
        case
            when gs % 6 = 0 then 'CLOSED'
            when gs % 5 = 0 then 'WAITING_FOR_OTHER_ORG_WORK'
            when gs % 4 = 0 then 'WAITING_FOR_INTERESTED_PARTY_RESPONSE'
            when gs % 3 = 0 then 'IN_PROGRESS'
            when gs % 2 = 0 then 'OPENED'
            else 'REGISTERED_PENDING_TO_BE_OPENED'
        end as state_code
    from generate_series(1, 50) as gs
    join dena_person p on p.external_id = 'CIT-' || lpad((10000 + gs)::text, 5, '0')
    join dena_admin a on a.external_id = (
        array['EJGV', 'DFB', 'DFG', 'DFA', 'BILBAO']
    )[((gs - 1) % 5) + 1]
    join dena_interop_message m on m.message_correlation_id = format('corr-demo-%s', lpad(gs::text, 4, '0'))
    join dena_procedure proc on proc.origin_ref_id = 'PROC-' || lpad((((gs - 1) % 12) + 1)::text, 3, '0')
),
upsert_objects as (
    insert into dena_business_object (
        source_message_pk,
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
        message_pk,
        'EXPEDIENTE',
        'administrativeServiceProcedureRecord',
        external_oid,
        expediente_id,
        admin_pk,
        person_pk,
        jsonb_build_object('demo', true, 'id', expediente_id, 'state', state_code),
        now() - make_interval(days => gs),
        now() - make_interval(hours => gs)
    from expediente_base
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
        raw_type = excluded.raw_type,
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
    eb.service_pk,
    eb.procedure_pk,
    now() - make_interval(days => eb.gs),
    now() - make_interval(hours => eb.gs),
    now() - make_interval(days => eb.gs, hours => 2),
    'REG-' || lpad(eb.gs::text, 6, '0'),
    eb.state_code,
    jsonb_build_object('SPANISH', eb.state_code, 'BASQUE', eb.state_code),
    'CIT-' || lpad((10000 + eb.gs)::text, 5, '0'),
    format('Persona Demo %s', eb.gs),
    jsonb_build_object(
        'SPANISH', format('Expediente demo %s generado para datos externos DENA', eb.gs),
        'BASQUE', format('DENA kanpo datuetarako %s demo espedientea', eb.gs)
    )
from expediente_base eb
join upsert_objects bo on bo.external_oid = eb.external_oid
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

insert into dena_business_object_url (business_object_pk, url, language_code, tags)
select
    e.business_object_pk,
    'https://demo.dena.local/expedientes/' || bo.external_id,
    'es',
    array['demo', 'expediente']
from dena_expediente e
join dena_business_object bo on bo.business_object_pk = e.business_object_pk
where bo.external_id like 'EXP-%'
  and not exists (
      select 1
      from dena_business_object_url bou
      where bou.business_object_pk = e.business_object_pk
        and bou.url = 'https://demo.dena.local/expedientes/' || bo.external_id
  );

with notice_base as (
    select
        gs,
        e.business_object_pk as expediente_object_pk,
        exp_bo.origin_admin_pk,
        exp_bo.about_person_pk,
        exp_bo.source_message_pk,
        'bo-not-oid-' || lpad(gs::text, 4, '0') as external_oid,
        'NOT-' || lpad(gs::text, 4, '0') as external_id,
        case
            when gs % 5 = 0 then 'EXPIRED'
            when gs % 4 = 0 then 'REJECTED_BY_DESTINATION'
            when gs % 3 = 0 then 'ACKNOWLEDGED_BY_DESTINATION'
            else 'PENDING_TO_BE_READED_BY_DESTINATION'
        end as state_code
    from generate_series(1, 30) as gs
    join dena_business_object exp_bo on exp_bo.external_id = 'EXP-' || lpad((((gs - 1) % 50) + 1)::text, 4, '0')
    join dena_expediente e on e.business_object_pk = exp_bo.business_object_pk
),
notice_objects as (
    insert into dena_business_object (
        source_message_pk,
        object_kind,
        raw_type,
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        raw_payload
    )
    select
        source_message_pk,
        'NOTIFICACION',
        'notice',
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        jsonb_build_object('demo', true, 'id', external_id, 'state', state_code)
    from notice_base
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
        external_id = excluded.external_id,
        origin_admin_pk = excluded.origin_admin_pk,
        about_person_pk = excluded.about_person_pk,
        raw_payload = excluded.raw_payload,
        updated_at = now()
    returning business_object_pk, external_oid
)
insert into dena_notificacion (
    business_object_pk,
    expediente_object_pk,
    notice_kind,
    issued_at_ts,
    read_at_ts,
    state_code,
    act_subject_by_language
)
select
    no.business_object_pk,
    nb.expediente_object_pk,
    case when nb.gs % 2 = 0 then 'COMMUNICATION' else 'OFFICIAL_NOTICE' end,
    now() - make_interval(days => nb.gs),
    case when nb.state_code = 'ACKNOWLEDGED_BY_DESTINATION' then now() - make_interval(days => nb.gs - 1) end,
    nb.state_code,
    jsonb_build_object('SPANISH', format('Notificacion demo %s', nb.gs), 'BASQUE', format('%s demo jakinarazpena', nb.gs))
from notice_base nb
join notice_objects no on no.external_oid = nb.external_oid
on conflict (business_object_pk) do update
set
    expediente_object_pk = excluded.expediente_object_pk,
    notice_kind = excluded.notice_kind,
    issued_at_ts = excluded.issued_at_ts,
    read_at_ts = excluded.read_at_ts,
    state_code = excluded.state_code,
    act_subject_by_language = excluded.act_subject_by_language;

with registry_base as (
    select
        gs,
        e.business_object_pk as expediente_object_pk,
        exp_bo.origin_admin_pk,
        exp_bo.about_person_pk,
        exp_bo.source_message_pk,
        'bo-reg-oid-' || lpad(gs::text, 4, '0') as external_oid,
        'REGOF-' || lpad(gs::text, 4, '0') as external_id,
        case
            when gs % 3 = 0 then 'TRANSFERRED_FROM_OTHER_ORG_UNIT'
            when gs % 2 = 0 then 'RECEIVED_FROM_OTHER_ORG_UNIT'
            else 'PRESENTED'
        end as state_code
    from generate_series(1, 15) as gs
    join dena_business_object exp_bo on exp_bo.external_id = 'EXP-' || lpad((((gs - 1) % 50) + 1)::text, 4, '0')
    join dena_expediente e on e.business_object_pk = exp_bo.business_object_pk
),
registry_objects as (
    insert into dena_business_object (
        source_message_pk,
        object_kind,
        raw_type,
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        raw_payload
    )
    select
        source_message_pk,
        'REGISTRO_OFICIAL',
        'officialRegistryEntry',
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        jsonb_build_object('demo', true, 'id', external_id, 'state', state_code)
    from registry_base
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
        external_id = excluded.external_id,
        origin_admin_pk = excluded.origin_admin_pk,
        about_person_pk = excluded.about_person_pk,
        raw_payload = excluded.raw_payload,
        updated_at = now()
    returning business_object_pk, external_oid
)
insert into dena_registro_oficial (
    business_object_pk,
    expediente_object_pk,
    registered_at_ts,
    subject_by_language,
    state_code,
    state_description_by_language
)
select
    ro.business_object_pk,
    rb.expediente_object_pk,
    now() - make_interval(days => rb.gs),
    jsonb_build_object('SPANISH', format('Registro oficial demo %s', rb.gs)),
    rb.state_code,
    jsonb_build_object('SPANISH', rb.state_code)
from registry_base rb
join registry_objects ro on ro.external_oid = rb.external_oid
on conflict (business_object_pk) do update
set
    expediente_object_pk = excluded.expediente_object_pk,
    registered_at_ts = excluded.registered_at_ts,
    subject_by_language = excluded.subject_by_language,
    state_code = excluded.state_code,
    state_description_by_language = excluded.state_description_by_language;

with payment_base as (
    select
        gs,
        e.business_object_pk as expediente_object_pk,
        exp_bo.origin_admin_pk,
        exp_bo.about_person_pk,
        exp_bo.source_message_pk,
        'bo-pay-oid-' || lpad(gs::text, 4, '0') as external_oid,
        'PAY-' || lpad(gs::text, 4, '0') as external_id,
        case when gs % 5 = 0 then 'DIRECT_DEBIT' else 'ONE_OFF' end as variant
    from generate_series(1, 25) as gs
    join dena_business_object exp_bo on exp_bo.external_id = 'EXP-' || lpad((((gs - 1) % 50) + 1)::text, 4, '0')
    join dena_expediente e on e.business_object_pk = exp_bo.business_object_pk
),
payment_objects as (
    insert into dena_business_object (
        source_message_pk,
        object_kind,
        raw_type,
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        raw_payload
    )
    select
        source_message_pk,
        case when variant = 'DIRECT_DEBIT' then 'DOMICILIACION' else 'PAGO_UNICO' end,
        case when variant = 'DIRECT_DEBIT' then 'directDebit' else 'oneOffPayment' end,
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        jsonb_build_object('demo', true, 'id', external_id, 'variant', variant)
    from payment_base
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
        external_id = excluded.external_id,
        origin_admin_pk = excluded.origin_admin_pk,
        about_person_pk = excluded.about_person_pk,
        raw_payload = excluded.raw_payload,
        updated_at = now()
    returning business_object_pk, external_oid
)
insert into dena_pago (
    business_object_pk,
    expediente_object_pk,
    payment_variant,
    payment_type,
    payment_subject_by_language,
    one_off_format_code,
    one_off_due_date,
    one_off_paid_at,
    one_off_amount,
    one_off_currency,
    one_off_status,
    one_off_status_at,
    one_off_medium,
    one_off_device,
    payment_processor_id,
    payment_processor_tx_id,
    dd_start_date,
    dd_expires_at,
    dd_frequency,
    dd_medium,
    dd_medium_hint,
    next_charge_at,
    next_charge_amount_eur,
    dd_status
)
select
    po.business_object_pk,
    pb.expediente_object_pk,
    pb.variant,
    case when pb.variant = 'DIRECT_DEBIT' then 'DIRECT_DEBIT' else 'ONE_OFF_PAYMENT' end,
    jsonb_build_object('SPANISH', format('Pago demo %s', pb.gs)),
    case when pb.variant = 'ONE_OFF' then 'Q60' end,
    case when pb.variant = 'ONE_OFF' then current_date + pb.gs end,
    case when pb.variant = 'ONE_OFF' and pb.gs % 3 = 0 then current_date - pb.gs end,
    case when pb.variant = 'ONE_OFF' then round((50 + pb.gs * 17.35)::numeric, 2) end,
    case when pb.variant = 'ONE_OFF' then 'EUR' end,
    case
        when pb.variant = 'ONE_OFF' and pb.gs % 4 = 0 then 'PENDING'
        when pb.variant = 'ONE_OFF' then 'COMPLETED'
    end,
    case when pb.variant = 'ONE_OFF' then now() - make_interval(hours => pb.gs) end,
    case when pb.variant = 'ONE_OFF' then 'PAYMENT_CARD' end,
    case when pb.variant = 'ONE_OFF' then 'WEB_BROWSER' end,
    case when pb.variant = 'ONE_OFF' then 'DEMO-PROCESSOR' end,
    case when pb.variant = 'ONE_OFF' then 'TX-' || lpad(pb.gs::text, 6, '0') end,
    case when pb.variant = 'DIRECT_DEBIT' then current_date - pb.gs end,
    case when pb.variant = 'DIRECT_DEBIT' then current_date + 365 end,
    case when pb.variant = 'DIRECT_DEBIT' then 'MONTHLY' end,
    case when pb.variant = 'DIRECT_DEBIT' then 'DIRECT_DEBIT' end,
    case when pb.variant = 'DIRECT_DEBIT' then 'IBAN terminado en ' || lpad((pb.gs * 13 % 10000)::text, 4, '0') end,
    case when pb.variant = 'DIRECT_DEBIT' then current_date + 30 end,
    case when pb.variant = 'DIRECT_DEBIT' then round((25 + pb.gs * 4.15)::numeric, 2) end,
    case when pb.variant = 'DIRECT_DEBIT' then 'ACTIVE' end
from payment_base pb
join payment_objects po on po.external_oid = pb.external_oid
on conflict (business_object_pk) do update
set
    expediente_object_pk = excluded.expediente_object_pk,
    payment_variant = excluded.payment_variant,
    payment_type = excluded.payment_type,
    payment_subject_by_language = excluded.payment_subject_by_language,
    one_off_format_code = excluded.one_off_format_code,
    one_off_due_date = excluded.one_off_due_date,
    one_off_paid_at = excluded.one_off_paid_at,
    one_off_amount = excluded.one_off_amount,
    one_off_currency = excluded.one_off_currency,
    one_off_status = excluded.one_off_status,
    one_off_status_at = excluded.one_off_status_at,
    one_off_medium = excluded.one_off_medium,
    one_off_device = excluded.one_off_device,
    payment_processor_id = excluded.payment_processor_id,
    payment_processor_tx_id = excluded.payment_processor_tx_id,
    dd_start_date = excluded.dd_start_date,
    dd_expires_at = excluded.dd_expires_at,
    dd_frequency = excluded.dd_frequency,
    dd_medium = excluded.dd_medium,
    dd_medium_hint = excluded.dd_medium_hint,
    next_charge_at = excluded.next_charge_at,
    next_charge_amount_eur = excluded.next_charge_amount_eur,
    dd_status = excluded.dd_status;

insert into dena_pago_historial (business_object_pk, charged_at, amount_eur)
select p.business_object_pk, current_date - (gs * 30), round((20 + gs * 3.5)::numeric, 2)
from dena_pago p
join dena_business_object bo on bo.business_object_pk = p.business_object_pk
cross join generate_series(1, 3) as gs
where bo.external_id like 'PAY-%'
  and p.payment_variant = 'DIRECT_DEBIT'
  and not exists (
      select 1
      from dena_pago_historial ph
      where ph.business_object_pk = p.business_object_pk
        and ph.charged_at = current_date - (gs * 30)
  )
on conflict do nothing;

with cita_base as (
    select
        gs,
        exp_bo.origin_admin_pk,
        exp_bo.about_person_pk,
        exp_bo.source_message_pk,
        'bo-cita-oid-' || lpad(gs::text, 4, '0') as external_oid,
        'CITA-' || lpad(gs::text, 4, '0') as external_id
    from generate_series(1, 10) as gs
    join dena_business_object exp_bo on exp_bo.external_id = 'EXP-' || lpad((((gs - 1) % 50) + 1)::text, 4, '0')
),
cita_objects as (
    insert into dena_business_object (
        source_message_pk,
        object_kind,
        raw_type,
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        raw_payload
    )
    select
        source_message_pk,
        'CITA',
        'appointment',
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        jsonb_build_object('demo', true, 'id', external_id)
    from cita_base
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
        external_id = excluded.external_id,
        origin_admin_pk = excluded.origin_admin_pk,
        about_person_pk = excluded.about_person_pk,
        raw_payload = excluded.raw_payload,
        updated_at = now()
    returning business_object_pk, external_oid
)
insert into dena_cita (
    business_object_pk,
    year_num,
    month_of_year,
    day_of_month,
    hour_of_day,
    minute_of_hour,
    duration_minutes,
    priority_code,
    subject_by_language,
    details_by_language,
    location_country_id,
    location_country_name,
    location_area_level1_id,
    location_area_level1_name,
    location_area_level3_id,
    location_area_level3_name,
    location_zip_code,
    location_address,
    location_directions_by_language
)
select
    co.business_object_pk,
    extract(year from current_date)::integer,
    ((extract(month from current_date)::integer + cb.gs - 1) % 12) + 1,
    ((cb.gs - 1) % 28) + 1,
    9 + (cb.gs % 7),
    case when cb.gs % 2 = 0 then 30 else 0 end,
    30,
    case when cb.gs % 4 = 0 then 'HIGH' when cb.gs % 3 = 0 then 'MEDIUM' else 'NORMAL' end,
    jsonb_build_object('SPANISH', format('Cita demo %s', cb.gs), 'BASQUE', format('%s demo hitzordua', cb.gs)),
    jsonb_build_object('SPANISH', 'Atencion presencial de prueba'),
    'ES',
    'Espana',
    'PV',
    'Euskadi',
    '48020',
    'Bilbao',
    '48001',
    'Gran Via 1',
    jsonb_build_object('SPANISH', 'Entrada principal')
from cita_base cb
join cita_objects co on co.external_oid = cb.external_oid
on conflict (business_object_pk) do update
set
    year_num = excluded.year_num,
    month_of_year = excluded.month_of_year,
    day_of_month = excluded.day_of_month,
    hour_of_day = excluded.hour_of_day,
    minute_of_hour = excluded.minute_of_hour,
    duration_minutes = excluded.duration_minutes,
    priority_code = excluded.priority_code,
    subject_by_language = excluded.subject_by_language,
    details_by_language = excluded.details_by_language,
    location_country_id = excluded.location_country_id,
    location_country_name = excluded.location_country_name,
    location_area_level1_id = excluded.location_area_level1_id,
    location_area_level1_name = excluded.location_area_level1_name,
    location_area_level3_id = excluded.location_area_level3_id,
    location_area_level3_name = excluded.location_area_level3_name,
    location_zip_code = excluded.location_zip_code,
    location_address = excluded.location_address,
    location_directions_by_language = excluded.location_directions_by_language;

with person_data_base as (
    select
        gs,
        p.person_pk,
        u.org_unit_pk,
        m.message_pk,
        'bo-person-oid-' || lpad(gs::text, 4, '0') as external_oid,
        'PERSONDATA-' || lpad(gs::text, 4, '0') as external_id,
        p.external_id as party_id
    from generate_series(1, 20) as gs
    join dena_person p on p.external_id = 'CIT-' || lpad((10000 + gs)::text, 5, '0')
    join dena_org_unit u on u.external_id = (
        array['OU-ATENCION-CIUDADANA', 'OU-REGISTRO', 'OU-TRIBUTOS', 'OU-AYUDAS', 'OU-CITAS']
    )[((gs - 1) % 5) + 1]
    join dena_interop_message m on m.message_correlation_id = format('corr-demo-%s', lpad(gs::text, 4, '0'))
),
person_data_objects as (
    insert into dena_business_object (
        source_message_pk,
        object_kind,
        raw_type,
        external_oid,
        external_id,
        about_person_pk,
        raw_payload
    )
    select
        message_pk,
        'PERSONA',
        'personData',
        external_oid,
        external_id,
        person_pk,
        jsonb_build_object('demo', true, 'partyId', party_id)
    from person_data_base
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
        external_id = excluded.external_id,
        about_person_pk = excluded.about_person_pk,
        raw_payload = excluded.raw_payload,
        updated_at = now()
    returning business_object_pk, external_oid
)
insert into dena_person_data (
    business_object_pk,
    person_pk,
    org_unit_pk,
    party_id,
    party_name,
    party_surname,
    birth_date_ts,
    phone_1,
    email,
    contact_language,
    contact_mode
)
select
    pdo.business_object_pk,
    pdb.person_pk,
    pdb.org_unit_pk,
    pdb.party_id,
    format('Nombre%s', pdb.gs),
    format('Apellido%s', pdb.gs),
    make_timestamptz(1980 + (pdb.gs % 20), ((pdb.gs - 1) % 12) + 1, ((pdb.gs - 1) % 28) + 1, 0, 0, 0),
    '+34944' || lpad(pdb.gs::text, 6, '0'),
    format('persona.demo.%s@example.invalid', pdb.gs),
    case when pdb.gs % 3 = 0 then 'BASQUE' else 'SPANISH' end,
    case when pdb.gs % 2 = 0 then 'ELECTRONIC' else 'POSTAL' end
from person_data_base pdb
join person_data_objects pdo on pdo.external_oid = pdb.external_oid
on conflict (business_object_pk) do update
set
    person_pk = excluded.person_pk,
    org_unit_pk = excluded.org_unit_pk,
    party_id = excluded.party_id,
    party_name = excluded.party_name,
    party_surname = excluded.party_surname,
    birth_date_ts = excluded.birth_date_ts,
    phone_1 = excluded.phone_1,
    email = excluded.email,
    contact_language = excluded.contact_language,
    contact_mode = excluded.contact_mode;

insert into dena_person_address (
    business_object_pk,
    address_role,
    address_order,
    address_description_by_language,
    country_nora_code,
    country_desc_by_language,
    province_nora_code,
    province_desc_by_language,
    municipality_nora_code,
    municipality_desc_by_language,
    address_line,
    postal_code
)
select
    pd.business_object_pk,
    'MAIN',
    1,
    jsonb_build_object('SPANISH', 'Direccion principal demo'),
    'ES',
    jsonb_build_object('SPANISH', 'Espana'),
    '48',
    jsonb_build_object('SPANISH', 'Bizkaia'),
    '020',
    jsonb_build_object('SPANISH', 'Bilbao'),
    'Calle Demo ' || row_number() over (order by pd.business_object_pk),
    '48001'
from dena_person_data pd
join dena_business_object bo on bo.business_object_pk = pd.business_object_pk
where bo.external_id like 'PERSONDATA-%'
on conflict (business_object_pk, address_role, address_order) do update
set
    address_description_by_language = excluded.address_description_by_language,
    country_nora_code = excluded.country_nora_code,
    country_desc_by_language = excluded.country_desc_by_language,
    province_nora_code = excluded.province_nora_code,
    province_desc_by_language = excluded.province_desc_by_language,
    municipality_nora_code = excluded.municipality_nora_code,
    municipality_desc_by_language = excluded.municipality_desc_by_language,
    address_line = excluded.address_line,
    postal_code = excluded.postal_code;

insert into dena_person_bank_account (business_object_pk, account_id, account_id_type, entity_name)
select
    pd.business_object_pk,
    'ES00' || lpad((10000000000000000000::numeric + row_number() over (order by pd.business_object_pk))::text, 20, '0'),
    'IBAN',
    'Banco Demo'
from dena_person_data pd
join dena_business_object bo on bo.business_object_pk = pd.business_object_pk
where bo.external_id like 'PERSONDATA-%'
  and not exists (
      select 1
      from dena_person_bank_account pba
      where pba.business_object_pk = pd.business_object_pk
        and pba.account_id_type = 'IBAN'
  );

insert into dena_sync_metadata_item (
    source_message_pk,
    admin_pk,
    person_pk,
    data_type_pk,
    data_type_external_id,
    some_data_was_updated_at,
    pop_message_how,
    pop_message_by_language,
    raw_payload
)
select
    m.message_pk,
    m.administration_pk,
    m.subject_person_pk,
    m.data_type_pk,
    dt.external_id,
    m.received_at,
    case when row_number() over (order by m.message_pk) % 2 = 0 then 'PUSH_TO_CLIENT_AT_CORE' else 'AT_CLIENT_AFTER_SYNC' end,
    jsonb_build_object('SPANISH', 'Hay datos demo actualizados'),
    jsonb_build_object('demo', true)
from dena_interop_message m
join dena_data_type dt on dt.data_type_pk = m.data_type_pk
where m.message_correlation_id like 'corr-demo-%'
  and not exists (
      select 1
      from dena_sync_metadata_item smi
      where smi.source_message_pk = m.message_pk
  );

insert into dena_person_push_event (
    source_message_pk,
    person_pk,
    target_admin_pk,
    sync_event,
    create_date_ts,
    last_update_date_ts,
    name_hash,
    surname1_hash,
    surname2_hash,
    all_names_hash,
    raw_payload
)
select
    m.message_pk,
    m.subject_person_pk,
    m.administration_pk,
    case
        when gs % 4 = 0 then 'ID_CHANGED'
        when gs % 3 = 0 then 'UPDATED'
        when gs % 2 = 0 then 'CREATED'
        else 'DELETED'
    end,
    now() - make_interval(days => gs),
    now() - make_interval(hours => gs),
    md5('name-' || gs),
    md5('surname1-' || gs),
    md5('surname2-' || gs),
    md5('all-' || gs),
    jsonb_build_object('demo', true)
from generate_series(1, 20) as gs
join dena_interop_message m on m.message_correlation_id = format('corr-demo-%s', lpad(gs::text, 4, '0'))
where not exists (
    select 1
    from dena_person_push_event ppe
    where ppe.source_message_pk = m.message_pk
);

insert into dena_person_export_request (
    source_message_pk,
    admin_pk,
    person_export_spec,
    export_file_format,
    last_update_range_text,
    sync_event,
    raw_payload
)
select
    m.message_pk,
    m.administration_pk,
    case when gs % 2 = 0 then 'data' else 'sync' end,
    case
        when gs % 4 = 0 then 'PARQUET'
        when gs % 3 = 0 then 'ZIP_OF_JSON'
        when gs % 2 = 0 then 'CSV'
        else 'SQLITE'
    end,
    'P30D',
    case when gs % 2 = 0 then 'UPDATED' else null end,
    jsonb_build_object('demo', true, 'request', gs)
from generate_series(1, 8) as gs
join dena_interop_message m on m.message_correlation_id = format('corr-demo-%s', lpad(gs::text, 4, '0'))
where not exists (
    select 1
    from dena_person_export_request per
    where per.source_message_pk = m.message_pk
);

select
    'datos_demo' as dataset,
    (select count(*) from dena_expediente) as expedientes,
    (select count(*) from dena_notificacion) as notificaciones,
    (select count(*) from dena_pago) as pagos,
    (select count(*) from dena_cita) as citas,
    (select count(*) from dena_person_data) as personas_detalle;
