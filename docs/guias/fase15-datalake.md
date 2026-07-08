# Fase 15 - SQL del datalake y carga de datos local

Esta fase separa el esquema DENA del datalake en tres piezas y añade una carga local reproducible hacia la staging.

## Objetivo

Aplicar en `datalake`:

- tabla principal `dena.admin_file`
- vista camelCase `dena."adminFile"`
- RPC `public.dena_data_retrieve`
- staging `dena.admin_file_staging`
- función de promoción `dena.dena_staging_to_main()`

## Aplicación de SQL

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
PG="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"

for f in sql/01-dena-admin-file.sql sql/02-dena-rpc.sql sql/03-dena-staging.sql; do
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$PG" \
    psql -U postgres -d datalake < "$f"
done
```

Tras cambios de esquema, `NOTIFY pgrst, 'reload schema';` fuerza la recarga de PostgREST.

## Carga manual

La carga manual va a `dena.admin_file_staging`.

El CSV debe contener estas 9 columnas, en este orden:

`source_id`, `expediente_code`, `title`, `citizen_id`, `source_system`, `status`, `amount_eur`, `opened_at`, `updated_at`

```bash
bash scripts/dena/load-csv.sh --file expedientes.csv
```

Si quieres materializar el lote en la tabla principal:

```bash
bash scripts/dena/load-csv.sh --file expedientes.csv --promote
```

La segunda variante ejecuta `dena.dena_staging_to_main()` dentro del datalake.

## Flujo NiFi

El flujo incremental usa:

- `QueryDatabaseTableRecord` sobre `verticales.expedientes.admin_file`
- `PutDatabaseRecord` hacia `dena.admin_file_staging`
- `ExecuteSQL` con `SELECT dena.dena_staging_to_main();`

El `QueryDatabaseTableRecord` se ejecuta cada `30 sec` y compara `updated_at` para traer altas y ediciones.

Generar el resumen del flujo:

```bash
python3 scripts/dena/nifi-build-flow.py
```

## Verificación

```bash
bash scripts/dena/apply-fase15-datalake.sh
bash scripts/verify-fase15.sh
```

La verificación comprueba que el esquema DENA y la staging existen en el datalake.
