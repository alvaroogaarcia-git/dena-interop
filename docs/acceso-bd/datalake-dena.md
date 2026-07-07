# datalake / dena

## Qué Es

Base consolidada del piloto. Aquí vive el esquema `dena` que expone la API y la auditoría de recuperaciones.

## Dónde Está

- Namespace: `datalake`
- Pod: `postgresql-datalake-0`
- Base de datos: `datalake`
- Usuario SQL habitual: `postgres`

## Contraseña

Esta contraseña no está fijada como valor visible en Git. Se lee desde el secret:

```bash
kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d
```

Si quieres guardar el valor en una variable local:

```bash
PG="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
```

## Acceso Exacto

### Consola Interactiva

```bash
PG="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$PG" \
  psql -U postgres -d datalake
```

### Consulta Rápida

```bash
PG="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$PG" \
  psql -U postgres -d datalake -c "select count(*) from dena.admin_file;"
```

### Qué Ver

```sql
\dt dena.*
select id, realm, username, event_type, operator_username, created_at
from dena.recovery_event
order by created_at desc
limit 20;

select id, realm, username, status, issued_at, used_at, used_by
from dena.recovery_backup_code
order by id desc;
```

## Cuándo Usarlo

- Para revisar la API DENA y la tabla consolidada.
- Para comprobar la auditoría de recuperaciones.
- Para validar los backup codes y su consumo.

