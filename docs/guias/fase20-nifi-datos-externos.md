# Fase 20 - NiFi hacia datos externos DENA

## Objetivo

Sincronizar los cambios hechos en Mathesar sobre `verticales.expedientes.admin_file` hacia la PostgreSQL aislada `datos_externos`, para que la demo DENA enriquecida se actualice igual que el datalake.

Flujo:

```text
Mathesar
  -> verticales.expedientes.admin_file
  -> verticales.expedientes.admin_file_nifi
  -> NiFi
  -> datos_externos.dena.dena_admin_file_staging
  -> trigger SQL
  -> datos_externos.dena.dena_expediente / dena_business_object
```

## Piezas añadidas

- `sql/datos-externos/004_nifi_staging.sql`
- `scripts/dena/provision-fase20-datos-externos-nifi.sh`
- `scripts/verify-fase20-datos-externos-nifi.sh`

## SQL

`004_nifi_staging.sql` crea:

- Tabla `dena.dena_admin_file_staging`.
- Función `dena.dena_status_from_verticales(text)`.
- Función batch `dena.dena_admin_file_staging_to_dena()`.
- Función trigger `dena.dena_apply_admin_file_row_to_dena()`.
- Trigger `trg_dena_admin_file_staging_to_dena`.

El trigger actualiza el modelo DENA cuando NiFi inserta una fila en staging. Esto evita depender de que el procesador posterior de NiFi ejecute la promoción en todos los casos.

## Grupo NiFi

El aprovisionamiento crea el grupo:

```text
Fase 20 - DENA datos externos incremental
```

Procesadores:

- `Query Verticales Incremental`
- `Persist Staging Batch`
- `Promote Staging To Main`

Controller services:

- `Verticales DBCP`
- `Datalake DBCP` apuntando en esta fase a `datos-externos-postgresql.datos-externos.svc.cluster.local`
- `JSON Record Writer`
- `JSON Record Reader`

## Aprovisionamiento

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/provision-fase20-datos-externos-nifi.sh
```

El script:

1. Comprueba el driver JDBC de PostgreSQL en NiFi.
2. Aplica `004_nifi_staging.sql`.
3. Reutiliza el aprovisionador NiFi de Fase 15 con otro grupo y otro destino.
4. Arranca la sincronización incremental cada `30 sec`.

## Verificación

```bash
bash scripts/verify-fase20-datos-externos-nifi.sh
```

La verificación comprueba:

- Grupo NiFi presente.
- Procesadores `VALID/RUNNING`.
- Controller services `VALID/ENABLED`.
- Que la fila `EXP-0001` coincide entre `verticales` y `datos_externos`.

## Prueba manual

Actualizar una fila origen:

```bash
PG_PASS="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$PG_PASS" \
  psql -U postgres -d expedientes -c "
    update expedientes.admin_file
    set title = 'Expediente demo 1 reflejado automaticamente',
        status = 'archivado',
        amount_eur = 9876.54,
        updated_at = now()
    where id = 1;
  "
```

Esperar el siguiente ciclo de NiFi y comprobar:

```bash
DATOS_PASS="$(kubectl get secret -n datos-externos datos-externos-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -i -n datos-externos datos-externos-postgresql-0 -- \
  env PGPASSWORD="$DATOS_PASS" \
  psql -U postgres -d datos_externos -c "
    select bo.external_id,
           e.state_code,
           e.description_by_language->>'SPANISH' as title,
           bo.raw_payload->>'amount_eur' as amount_eur
    from dena.dena_expediente e
    join dena.dena_business_object bo on bo.business_object_pk = e.business_object_pk
    where bo.external_id = 'EXP-0001';
  "
```

Resultado esperado:

```text
EXP-0001 | CLOSED | Expediente demo 1 reflejado automaticamente | 9876.54
```
