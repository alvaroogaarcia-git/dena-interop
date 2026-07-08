# Extensión 11c - NiFi JDBC incremental

Nota de numeración: este flujo se implementó originalmente con el nombre interno `Fase 12`. En el plan consolidado queda como extensión 11c; la Fase 12 corresponde a Terraform y Keycloak. El stack actual usa el flujo consolidado de staging (`provision-fase15-nifi.sh` y `verify-fase15-nifi.sh`); los nombres `fase12` quedan como referencia histórica.

Esta fase deja preparado un flujo NiFi reproducible para leer incrementalmente `expedientes.admin_file_nifi`, escribir lotes en `dena.admin_file_staging` y promocionarlos a `dena.admin_file`.

## Objetivo

Tomar como fuente el PostgreSQL de `verticales`, consultar la vista `expedientes.admin_file_nifi`, persistir cada lote en staging del datalake y ejecutar la función de promoción. Mathesar sigue editando la tabla real `expedientes.admin_file`; la vista solo aliasa `id` como `source_id` para el datalake.

La lectura incremental se apoya en:

- `updated_at`
- `id`

## Piezas que crea la fase

- Grupo de proceso `Fase 15 - DENA staging incremental`
- Controller service `Verticales DBCP`
- Controller service `Datalake DBCP`
- Controller service `JSON Record Writer`
- Controller service `JSON Record Reader`
- Processor `Query Verticales Incremental`
- Processor `Persist Staging Batch`
- Processor `Promote Staging To Main`

En la raíz de NiFi se ve un solo bloque de grupo; al abrirlo aparecen los tres procesadores y los cuatro controller services de la fase.

## Requisitos previos

- `k3s` activo
- NiFi en `Running/Ready`
- driver `postgresql-42.7.4.jar` copiado a `extensions/` con `bash scripts/dena/install-nifi-postgresql-driver.sh`
- secret `nifi-secret` operativo
- PostgreSQL de `verticales` en `Running`
- PostgreSQL de `datalake` en `Running`
- SQL de la Fase 15 aplicado (`dena.admin_file_staging` y `dena.dena_staging_to_main()`)

## Aprovisionamiento

Ejecutar:

```bash
bash scripts/dena/provision-fase15-nifi.sh
```

El script:

1. Abre y cierra automáticamente un `port-forward` local a NiFi.
2. Lee usuario y password desde `nifi-secret` y obtiene un token.
3. Crea o reutiliza el grupo y sus componentes.
4. Reconfigura DBCP con las claves de propiedades de NiFi 2.9.
5. Reconcilia propiedades y conexiones sin duplicar componentes.
6. Habilita servicios y arranca los procesadores.

El aprovisionamiento es idempotente: puede repetirse para reparar o reconciliar el flujo.

## Verificación

```bash
bash scripts/verify-fase15-nifi.sh
```

La verificación comprueba:

- presencia del grupo de proceso
- los tres procesadores en `VALID/RUNNING`
- DBCP, Record Writer y Record Reader en `VALID/ENABLED`
- igualdad de datos sincronizados entre `verticales` y `datalake`
- presencia del driver JDBC en NiFi

## Persistencia

El deployment configura `nifi.flow.configuration.file` sobre `/persistent/conf/flow.json.gz`, dentro de `nifi-extensions`. La clave `nifi.sensitive.props.key` se obtiene de `nifi-secret`, por lo que las propiedades JDBC cifradas se pueden leer después de recrear el pod.

Prueba validada:

```bash
kubectl rollout restart deployment/nifi -n datalake
kubectl rollout status deployment/nifi -n datalake --timeout=15m
bash scripts/verify-fase15-nifi.sh
```

El grupo mantuvo el mismo identificador y todos los componentes continuaron operativos sin reprovisionar.

## Prueba de incremental

Con la fase aprovisionada, modificar una fila de `expedientes.admin_file`:

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
PG_PASS="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$PG_PASS" \
  psql -U postgres -d expedientes -c "update expedientes.admin_file set status = 'archivado', updated_at = now() where id = 1;"
```

Después, esperar al siguiente ciclo de NiFi y comprobar que el cambio aparece en `datalake.dena.admin_file`:

```bash
DL_PASS="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$DL_PASS" \
  psql -U postgres -d datalake -c "select source_id, status, updated_at from dena.admin_file where source_id = 1;"
```

## Acceso a NiFi

Si el NodePort directo no responde, usar el acceso validado:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
```

URL:

```text
https://localhost:8443/nifi
```
