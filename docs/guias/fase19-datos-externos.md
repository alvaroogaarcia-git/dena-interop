# Fase 19 - PostgreSQL datos externos desde Markdown DENA

## Objetivo

Crear una base PostgreSQL independiente para conservar el modelo semantico DENA deducido de los Markdown ubicados en `/home/dietpi/codex_unzip/codex/semantica-dena`.

Esta fase no modifica los namespaces ni las bases ya existentes:

- `auth`
- `gateway`
- `monitoring`
- `datalake`
- `verticales`
- `portainer`

## Arquitectura

Recursos nuevos:

- Namespace: `datos-externos`
- Release Helm: `datos-externos-postgresql`
- Chart: `bitnami/postgresql` version `18.7.5`
- Base: `datos_externos`
- Usuario aplicativo configurado en values: `datos_externos`
- Pod/StatefulSet: `datos-externos-postgresql-0`
- Service interno: `datos-externos-postgresql`
- PVC: `data-datos-externos-postgresql-0`
- Secret: `datos-externos-postgresql`

No se publica ningun `NodePort`, Ingress ni ruta APISIX. La base queda accesible solo dentro del cluster.

## Archivos añadidos

```text
helm-values/datos-externos-postgresql-values.yaml
k8s-manifests/datos-externos/namespace.yaml
scripts/dena/apply-fase19-datos-externos.sh
scripts/verify-fase19-datos-externos.sh
sql/datos-externos/001_schema.sql
sql/datos-externos/002_markdown_catalog.sql
sql/datos-externos/003_demo_data.sql
sql/datos-externos/004_nifi_staging.sql
sql/datos-externos/README.md
docs/guias/fase19-datos-externos.md
docs/estado-fases/estado-fases-0-19.md
docs/acceso-bd/datos-externos-dena.md
```

## Modelo SQL

El esquema principal es `dena`.

Bloques principales:

- Maestros compartidos: `dena_admin`, `dena_person`, `dena_data_type`.
- Envoltorio REST y trazabilidad: `dena_interop_message`, `dena_interop_message_route`.
- Base comun DATA-RETRIEVE: `dena_business_object`, `dena_business_object_url`.
- Catalogo administrativo: `dena_org_unit`, `dena_service`, `dena_procedure`.
- Entidades DATA-RETRIEVE: `dena_expediente`, `dena_notificacion`, `dena_registro_oficial`, `dena_pago`, `dena_cita`, `dena_person_data`.
- Flujos METADATA-SYNC: `dena_sync_metadata_item`.
- Flujos PERSON-SYNC: `dena_person_push_event`, `dena_person_export_request`.
- Trazabilidad Markdown: `dena_source_document`, `dena_semantic_field`, `dena_semantic_enum_value`.

El diseño combina tablas normalizadas con `jsonb` para `LanguageTexts`, payloads originales y zonas ambiguas de la documentacion.

## Que contiene cada tabla

Las tablas `dena_source_document`, `dena_semantic_field` y `dena_semantic_enum_value` conservan la trazabilidad directa con los Markdown de `/home/dietpi/codex_unzip/codex/semantica-dena`:

- `dena_source_document`: inventario de documentos Markdown usados como fuente.
- `dena_semantic_field`: campos detectados en esos Markdown, con tabla sugerida, ruta de campo, tipo y obligatoriedad.
- `dena_semantic_enum_value`: valores enumerados publicados en los Markdown.

El resto del esquema es el modelo fisico PostgreSQL derivado de esa documentacion:

| Tabla | Contenido |
| --- | --- |
| `dena_admin` | Administraciones u organismos participantes. |
| `dena_person` | Personas referenciadas por objetos DENA. |
| `dena_data_type` | Tipos DENA base: `RECORDS`, `NOTICES`, `REGISTRY`, `PAYMENTS`, `SCHEDULE`. |
| `dena_interop_message` | Cabecera y payload de mensajes REST DENA. |
| `dena_interop_message_route` | Ruta recorrida por cada mensaje entre componentes. |
| `dena_business_object` | Base comun de expediente, notificacion, registro, pago, cita y persona. |
| `dena_business_object_url` | URLs asociadas a objetos de negocio. |
| `dena_org_unit` | Unidades organicas. |
| `dena_org_unit_url` | URLs asociadas a unidades organicas. |
| `dena_service` | Servicios administrativos. |
| `dena_service_ref_url` | URLs de referencia de servicios. |
| `dena_service_org_unit` | Relacion entre servicios y unidades organicas por rol. |
| `dena_procedure` | Procedimientos administrativos asociados a servicios. |
| `dena_procedure_ref_url` | URLs de referencia de procedimientos. |
| `dena_procedure_org_unit` | Relacion entre procedimientos y unidades organicas por rol. |
| `dena_expediente` | Expedientes administrativos: servicio, procedimiento, estado, interesado y fechas. |
| `dena_notificacion` | Notificaciones o comunicaciones asociadas a expedientes. |
| `dena_registro_oficial` | Registros oficiales asociados a expedientes. |
| `dena_pago` | Pagos unicos y domiciliaciones asociados a expedientes. |
| `dena_pago_historial` | Historico de cargos de pagos domiciliados. |
| `dena_pago_org_unit` | Relacion entre pagos y unidades organicas por rol. |
| `dena_cita` | Citas presenciales: fecha, hora, prioridad, asunto y ubicacion. |
| `dena_person_data` | Datos de persona: identificador, nombre, contacto e idioma. |
| `dena_person_address` | Direcciones asociadas a una ficha de persona. |
| `dena_person_bank_account` | Cuentas bancarias asociadas a una ficha de persona. |
| `dena_sync_metadata_item` | Elementos de sincronizacion `metadata-sync`. |
| `dena_person_push_event` | Eventos `person-sync` de alta, baja, actualizacion o cambio de identificador. |
| `dena_person_export_request` | Solicitudes de exportacion de datos de persona. |

Las filas de negocio cargadas por `003_demo_data.sql` son ficticias. Sirven para navegar el modelo en Mathesar y comprobar relaciones reales entre expedientes, pagos, notificaciones, citas, personas y trazas.

## Datos demo

El fichero `sql/datos-externos/003_demo_data.sql` genera datos ficticios idempotentes para inspeccionar el modelo completo:

- `50` expedientes con codigos `EXP-0001` a `EXP-0050`.
- `50` personas base con codigos `CIT-10001` a `CIT-10050`.
- `5` administraciones, `5` unidades organicas, `8` servicios y `12` procedimientos.
- `30` notificaciones asociadas a expedientes.
- `25` pagos, con pagos unicos y domiciliaciones.
- `10` citas presenciales.
- `20` fichas `PersonData` con direccion y cuenta bancaria demo.
- `50` mensajes REST con rutas de interoperabilidad simuladas.

Los codigos de expediente siguen el mismo patron que la tabla demo de Mathesar (`EXP-0001`, `EXP-0002`, ...), pero esta base conserva una vista DENA normalizada y mas rica.

La Fase 20 anade sincronizacion incremental desde `verticales` mediante NiFi. Ver [Fase 20 - NiFi hacia datos externos DENA](fase20-nifi-datos-externos.md).

## Despliegue

Desde la maquina DietPi:

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/apply-fase19-datos-externos.sh
```

El script:

1. Crea o reutiliza `.local/fase19-datos-externos.env`.
2. Genera una password local si no existe.
3. Aplica el namespace `datos-externos`.
4. Ejecuta `helm upgrade --install` del PostgreSQL independiente.
5. Espera al StatefulSet.
6. Aplica todos los SQL de `sql/datos-externos/*.sql` ordenados por nombre.

La convencion es usar prefijos numericos:

```text
001_schema.sql
002_markdown_catalog.sql
003_demo_data.sql
004_otra_migracion.sql
```

## Verificacion

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/verify-fase19-datos-externos.sh
```

La verificacion comprueba:

- Namespace, StatefulSet, Service, PVC y Secret nuevos.
- Tablas principales del esquema `dena`.
- 21 documentos Markdown catalogados.
- Diccionario semantico de campos.
- Catalogo de enumeraciones.
- Tipos DENA base: `RECORDS`, `NOTICES`, `REGISTRY`, `PAYMENTS`, `SCHEDULE`.
- Datos demo principales: expedientes, notificaciones, pagos, citas, personas y mensajes REST.

## Consultas utiles

```bash
pg_password="$(kubectl get secret -n datos-externos datos-externos-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -it -n datos-externos datos-externos-postgresql-0 -- \
  env PGPASSWORD="$pg_password" \
  psql -U postgres -d datos_externos
```

Dentro de `psql`:

```sql
\dt dena.*
select document_group, count(*) from dena.dena_source_document group by 1 order by 1;
select enum_name, count(*) from dena.dena_semantic_enum_value group by 1 order by 1;
select count(*) from dena.dena_expediente;
select count(*) from dena.dena_notificacion;
select count(*) from dena.dena_pago;
select count(*) from dena.dena_cita;
select count(*) from dena.dena_person_data;
select bo.external_id, e.state_code, e.interested_party_id
from dena.dena_expediente e
join dena.dena_business_object bo on bo.business_object_pk = e.business_object_pk
order by bo.external_id
limit 10;
```

## Acceso desde Mathesar

No hace falta desplegar otro Mathesar. Desde la UI de Mathesar existente (`http://192.168.56.15:30900`) se puede crear una conexion adicional:

```text
Host: datos-externos-postgresql.datos-externos.svc.cluster.local
Puerto: 5432
Base: datos_externos
Usuario: postgres
Password: secret datos-externos-postgresql
```

Para leer el password:

```bash
kubectl get secret -n datos-externos datos-externos-postgresql \
  -o jsonpath='{.data.postgres-password}' | base64 -d
echo
```

Guia de acceso detallada: [datos-externos / datos_externos](../acceso-bd/datos-externos-dena.md).

## Aislamiento

La fase usa namespace, release Helm, PVC y Secret propios. No reutiliza servicios, credenciales ni almacenamiento de `auth`, `datalake` o `verticales`.
