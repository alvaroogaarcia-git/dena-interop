# verticales / expedientes

## Qué Es

Base de negocio editable que simula el sistema origen de expedientes.

## Dónde Está

- Namespace: `verticales`
- Pod: `postgresql-verticales-0`
- Base de datos: `expedientes`
- Usuario SQL: `postgres`

## Contraseña

Valor demo fijo:

```text
pyZN2eJRnVfArOgFltoTlotN
```

También se puede leer desde el secret:

```bash
kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d
```

## Acceso Exacto

### Consola Interactiva

```bash
kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD='pyZN2eJRnVfArOgFltoTlotN' \
  psql -U postgres -d expedientes
```

### Consulta Rápida

```bash
kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD='pyZN2eJRnVfArOgFltoTlotN' \
  psql -U postgres -d expedientes -c "select count(*) from expedientes.admin_file;"
```

### Qué Ver

Tablas útiles:

```sql
\dt expedientes.*
select id, expediente_code, status, updated_at
from expedientes.admin_file
order by id
limit 5;
```

## Cuándo Usarlo

- Para editar expedientes del sistema origen.
- Para comprobar que Mathesar está apuntando a la base correcta.
- Para validar el cambio que luego recogerá NiFi.

