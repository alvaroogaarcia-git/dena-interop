-- Extra citizen-facing demo data.
-- Keeps CIT-10001 rich enough for the client demo timeline and attention panel.

set search_path = dena, public;

with ctx as (
    select
        p.person_pk,
        a.admin_pk,
        m.message_pk,
        proc.procedure_pk,
        proc.service_pk
    from dena_person p
    join dena_admin a on a.external_id = 'EJGV'
    join dena_interop_message m on m.message_correlation_id = 'corr-demo-0001'
    join dena_procedure proc on proc.origin_ref_id = 'PROC-001'
    where p.external_id = 'CIT-10001'
    limit 1
),
extra_expedientes(expediente_id, external_oid, title_es, state_code, days_ago, amount_hint) as (
    values
        ('EXP-0101', 'bo-exp-oid-cit10001-0101', 'Solicitud de ayuda al alquiler', 'WAITING_FOR_INTERESTED_PARTY_RESPONSE', 9, 1250.00),
        ('EXP-0102', 'bo-exp-oid-cit10001-0102', 'Renovacion de datos padronales', 'IN_PROGRESS', 5, 0.00),
        ('EXP-0103', 'bo-exp-oid-cit10001-0103', 'Bonificacion de transporte publico', 'OPENED', 2, 85.50),
        ('EXP-0104', 'bo-exp-oid-cit10001-0104', 'Revision de compatibilidad de ayudas', 'WAITING_FOR_OTHER_ORG_WORK', 12, 640.00),
        ('EXP-0105', 'bo-exp-oid-cit10001-0105', 'Alta de solicitud de tarjeta ciudadana', 'REGISTERED_PENDING_TO_BE_OPENED', 1, 0.00)
),
exp_objects as (
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
        ctx.message_pk,
        'EXPEDIENTE',
        'administrativeServiceProcedureRecord',
        ee.external_oid,
        ee.expediente_id,
        ctx.admin_pk,
        ctx.person_pk,
        jsonb_build_object('demo', true, 'citizenFocus', true, 'id', ee.expediente_id, 'state', ee.state_code, 'amountHint', ee.amount_hint),
        now() - make_interval(days => ee.days_ago),
        now() - make_interval(hours => ee.days_ago * 6)
    from extra_expedientes ee
    cross join ctx
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
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
    eo.business_object_pk,
    ctx.service_pk,
    ctx.procedure_pk,
    now() - make_interval(days => ee.days_ago),
    now() - make_interval(hours => ee.days_ago * 6),
    now() - make_interval(days => ee.days_ago, hours => 2),
    'REG-CIT10001-' || right(ee.expediente_id, 4),
    ee.state_code,
    jsonb_build_object('SPANISH', ee.state_code, 'BASQUE', ee.state_code),
    'CIT-10001',
    'Persona Demo 1',
    jsonb_build_object('SPANISH', ee.title_es, 'BASQUE', ee.title_es)
from extra_expedientes ee
join exp_objects eo on eo.external_oid = ee.external_oid
cross join ctx
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

with base as (
    select
        e.business_object_pk as expediente_object_pk,
        bo.origin_admin_pk,
        bo.about_person_pk,
        bo.source_message_pk
    from dena_business_object bo
    join dena_expediente e on e.business_object_pk = bo.business_object_pk
    where bo.external_id = 'EXP-0101'
),
notice_data(external_id, external_oid, state_code, subject_es, days_ago) as (
    values
        ('NOT-0101', 'bo-not-oid-cit10001-0101', 'ACKNOWLEDGED_BY_DESTINATION', 'Confirmacion de documentacion recibida', 4)
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
        base.source_message_pk,
        'NOTIFICACION',
        'notice',
        nd.external_oid,
        nd.external_id,
        base.origin_admin_pk,
        base.about_person_pk,
        jsonb_build_object('demo', true, 'citizenFocus', true, 'id', nd.external_id, 'state', nd.state_code)
    from notice_data nd
    cross join base
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
    base.expediente_object_pk,
    'COMMUNICATION',
    now() - make_interval(days => nd.days_ago),
    now() - make_interval(days => nd.days_ago - 1),
    nd.state_code,
    jsonb_build_object('SPANISH', nd.subject_es, 'BASQUE', nd.subject_es)
from notice_data nd
join notice_objects no on no.external_oid = nd.external_oid
cross join base
on conflict (business_object_pk) do update
set
    expediente_object_pk = excluded.expediente_object_pk,
    notice_kind = excluded.notice_kind,
    issued_at_ts = excluded.issued_at_ts,
    read_at_ts = excluded.read_at_ts,
    state_code = excluded.state_code,
    act_subject_by_language = excluded.act_subject_by_language;

with payment_data(external_id, external_oid, expediente_id, title_es, status_code, amount_eur, due_days) as (
    values
        ('PAY-0101', 'bo-pay-oid-cit10001-0101', 'EXP-0101', 'Tasa de tramitacion de ayuda', 'PENDING', 42.50, 12),
        ('PAY-0102', 'bo-pay-oid-cit10001-0102', 'EXP-0103', 'Abono transporte bonificado', 'COMPLETED', 18.75, -3)
),
payment_base as (
    select
        pd.*,
        e.business_object_pk as expediente_object_pk,
        bo.origin_admin_pk,
        bo.about_person_pk,
        bo.source_message_pk
    from payment_data pd
    join dena_business_object bo on bo.external_id = pd.expediente_id
    join dena_expediente e on e.business_object_pk = bo.business_object_pk
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
        'PAGO_UNICO',
        'oneOffPayment',
        external_oid,
        external_id,
        origin_admin_pk,
        about_person_pk,
        jsonb_build_object('demo', true, 'citizenFocus', true, 'id', external_id, 'state', status_code)
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
    payment_processor_tx_id
)
select
    po.business_object_pk,
    pb.expediente_object_pk,
    'ONE_OFF',
    'ONE_OFF_PAYMENT',
    jsonb_build_object('SPANISH', pb.title_es, 'BASQUE', pb.title_es),
    'Q60',
    current_date + pb.due_days,
    case when pb.status_code = 'COMPLETED' then current_date + pb.due_days end,
    pb.amount_eur,
    'EUR',
    pb.status_code,
    now() - make_interval(hours => abs(pb.due_days)),
    'PAYMENT_CARD',
    'WEB_BROWSER',
    'DEMO-PROCESSOR',
    'TX-CIT10001-' || right(pb.external_id, 4)
from payment_base pb
join payment_objects po on po.external_oid = pb.external_oid
on conflict (business_object_pk) do update
set
    expediente_object_pk = excluded.expediente_object_pk,
    payment_subject_by_language = excluded.payment_subject_by_language,
    one_off_due_date = excluded.one_off_due_date,
    one_off_paid_at = excluded.one_off_paid_at,
    one_off_amount = excluded.one_off_amount,
    one_off_status = excluded.one_off_status,
    one_off_status_at = excluded.one_off_status_at,
    payment_processor_tx_id = excluded.payment_processor_tx_id;

with ctx as (
    select
        p.person_pk,
        a.admin_pk,
        m.message_pk
    from dena_person p
    join dena_admin a on a.external_id = 'BILBAO'
    join dena_interop_message m on m.message_correlation_id = 'corr-demo-0001'
    where p.external_id = 'CIT-10001'
    limit 1
),
cita_object as (
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
        ctx.message_pk,
        'CITA',
        'appointment',
        'bo-cita-oid-cit10001-0101',
        'CITA-0101',
        ctx.admin_pk,
        ctx.person_pk,
        jsonb_build_object('demo', true, 'citizenFocus', true, 'id', 'CITA-0101', 'priority', 'HIGH')
    from ctx
    on conflict (object_kind, external_oid) do update
    set
        source_message_pk = excluded.source_message_pk,
        external_id = excluded.external_id,
        origin_admin_pk = excluded.origin_admin_pk,
        about_person_pk = excluded.about_person_pk,
        raw_payload = excluded.raw_payload,
        updated_at = now()
    returning business_object_pk
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
    business_object_pk,
    extract(year from current_date + 10)::integer,
    extract(month from current_date + 10)::integer,
    extract(day from current_date + 10)::integer,
    12,
    30,
    30,
    'HIGH',
    jsonb_build_object('SPANISH', 'Cita prioritaria de revision documental', 'BASQUE', 'Dokumentazioa berrikusteko lehentasunezko hitzordua'),
    jsonb_build_object('SPANISH', 'Atencion presencial para revisar la solicitud de ayuda'),
    'ES',
    'Espana',
    'PV',
    'Euskadi',
    '48020',
    'Bilbao',
    '48001',
    'Plaza Demo 2',
    jsonb_build_object('SPANISH', 'Mostrador de atencion ciudadana')
from cita_object
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
    location_address = excluded.location_address,
    location_directions_by_language = excluded.location_directions_by_language;

notify pgrst, 'reload schema';
