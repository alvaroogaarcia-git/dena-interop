# Guia UI - Flujo NiFi de Fase 15

Esta guia describe la configuracion manual del flujo incremental de Fase 15 en NiFi 2.9.

## Componentes

Crear un grupo de proceso llamado `Fase 15 - DENA staging incremental`.

Dentro del grupo, crear:

- Controller service `Verticales DBCP`
- Controller service `Datalake DBCP`
- Controller service `JSON Record Writer`
- Controller service `JSON Record Reader`
- Processor `Query Verticales Incremental`
- Processor `Persist Staging Batch`
- Processor `Promote Staging To Main`

## Configuracion

`Verticales DBCP`

- `Database Connection URL`: `jdbc:postgresql://postgresql-verticales.verticales.svc.cluster.local:5432/expedientes`
- `Database Driver Class Name`: `org.postgresql.Driver`
- `Database Driver Locations`: `/opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar`
- `Database User`: `postgres`
- `Password`: secret de `postgresql-verticales`

`Datalake DBCP`

- `Database Connection URL`: `jdbc:postgresql://postgresql-datalake.datalake.svc.cluster.local:5432/datalake`
- `Database Driver Class Name`: `org.postgresql.Driver`
- `Database Driver Locations`: `/opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar`
- `Database User`: `postgres`
- `Password`: secret de `postgresql-datalake`

`JSON Record Writer`

- sin propiedades adicionales

`JSON Record Reader`

- sin propiedades adicionales

`Query Verticales Incremental`

- tipo: `QueryDatabaseTableRecord`
- tabla: `expedientes.admin_file`
- columnas maximas: `updated_at,id`
- writer: `JSON Record Writer`

`Persist Staging Batch`

- tipo: `PutDatabaseRecord`
- DBCP: `Datalake DBCP`
- record reader: `JSON Record Reader`
- tabla: `dena.admin_file_staging`
- behavior: `INSERT`
- `Unmatched Column Behavior`: `Ignore`

`Promote Staging To Main`

- tipo: `ExecuteSQL`
- DBCP: `Datalake DBCP`
- SQL: `SELECT dena.dena_staging_to_main();`

## Conexiones

- `Query Verticales Incremental` -> `Persist Staging Batch` por `success`
- `Persist Staging Batch` -> `Promote Staging To Main` por `success`

## Orden de arranque

1. Arrancar primero los controller services.
2. Verificar que quedan en `ENABLED`.
3. Arrancar los procesadores en ese orden.

## Notas operativas

- El flujo es incremental por `updated_at,id`.
- La tabla de staging se vacia dentro de `dena.dena_staging_to_main()`.
- Tras cambios de esquema, ejecutar `NOTIFY pgrst, 'reload schema';` en el datalake.
