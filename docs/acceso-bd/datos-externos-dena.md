# datos-externos / datos_externos

Base PostgreSQL independiente para revisar el modelo DENA derivado de los Markdown de `/home/dietpi/codex_unzip/codex/semantica-dena`.

## Identificacion

- Namespace: `datos-externos`
- Pod: `datos-externos-postgresql-0`
- Service interno: `datos-externos-postgresql.datos-externos.svc.cluster.local`
- Base de datos: `datos_externos`
- Esquema: `dena`
- Usuario administrador: `postgres`
- Usuario aplicativo: `datos_externos`

## Password

El password se guarda en el Secret del release:

```bash
kubectl get secret -n datos-externos datos-externos-postgresql \
  -o jsonpath='{.data.postgres-password}' | base64 -d
echo
```

El script de despliegue tambien lo conserva localmente en:

```text
.local/fase19-datos-externos.env
```

## Entrar En psql

Desde la VM:

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config

pg_password="$(kubectl get secret -n datos-externos datos-externos-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -it -n datos-externos datos-externos-postgresql-0 -- \
  env PGPASSWORD="$pg_password" \
  psql -U postgres -d datos_externos
```

## Consultas De Comprobacion

```sql
\dt dena.*

select count(*) from dena.dena_expediente;
select count(*) from dena.dena_notificacion;
select count(*) from dena.dena_pago;
select count(*) from dena.dena_cita;
select count(*) from dena.dena_person_data;

select bo.external_id, e.state_code, e.interested_party_id, e.interested_party_name
from dena.dena_expediente e
join dena.dena_business_object bo on bo.business_object_pk = e.business_object_pk
order by bo.external_id
limit 10;

select document_group, count(*)
from dena.dena_source_document
group by document_group
order by document_group;
```

Valores esperados del seed demo:

- `50` expedientes.
- `30` notificaciones.
- `25` pagos.
- `10` citas.
- `20` fichas de persona.
- `21` documentos Markdown catalogados.

## Acceso Desde Mathesar

Mathesar puede crear una conexion adicional a esta base sin desplegar otra instancia.

Usar estos datos en la UI de Mathesar:

```text
Host: datos-externos-postgresql.datos-externos.svc.cluster.local
Puerto: 5432
Base: datos_externos
Usuario: postgres
Password: valor del Secret datos-externos-postgresql
```

Tablas utiles para empezar:

- `dena.dena_expediente`
- `dena.dena_business_object`
- `dena.dena_notificacion`
- `dena.dena_pago`
- `dena.dena_cita`
- `dena.dena_person_data`
- `dena.dena_source_document`
- `dena.dena_semantic_field`
- `dena.dena_semantic_enum_value`

## Verificacion Automatizada

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/verify-fase19-datos-externos.sh
```
