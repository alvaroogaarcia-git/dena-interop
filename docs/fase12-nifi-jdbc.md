# Fase 12 - NiFi JDBC incremental

Esta fase deja preparado un flujo NiFi reproducible para leer incrementalmente `expedientes.admin_file` y persistir la salida en disco dentro del PVC de NiFi.

## Objetivo

Tomar como fuente el PostgreSQL de `verticales`, consultar la tabla `expedientes.admin_file` y guardar cada extracción incremental como JSON en:

```text
/opt/nifi/nifi-current/extensions/fase12-output
```

La lectura incremental se apoya en:

- `updated_at`
- `id`

## Piezas que crea la fase

- Grupo de proceso `Fase 12 - JDBC incremental`
- Controller service `Verticales DBCP`
- Controller service `JSON Record Writer`
- Processor `Query Verticales Incremental`
- Processor `Stamp Output Filename`
- Processor `Persist Fase 12 Output`

## Requisitos previos

- `k3s` activo
- NiFi accesible por `kubectl port-forward -n datalake svc/nifi 8443:8443`
- driver `postgresql-42.7.4.jar` ya copiado a `extensions/`
- secret `nifi-secret` operativo
- PostgreSQL de `verticales` en `Running`

## Aprovisionamiento

Ejecutar:

```bash
bash scripts/dena/provision-fase12-nifi.sh
```

El script:

1. Obtiene token de NiFi con el usuario single-user.
2. Crea el grupo de proceso si no existe.
3. Crea el `DBCPConnectionPool` contra `postgresql-verticales.verticales.svc.cluster.local`.
4. Crea `JsonRecordSetWriter`.
5. Crea `QueryDatabaseTableRecord` con `Maximum-value Columns = updated_at,id`.
6. Crea `UpdateAttribute` para dar nombre estable al fichero de salida.
7. Crea `PutFile` apuntando al directorio persistente del PVC.
8. Conecta y arranca los procesadores.

## Verificacion

```bash
bash scripts/verify-fase12.sh
```

La verificacion comprueba:

- presencia del grupo de proceso
- presencia de los tres procesadores
- disponibilidad del directorio de salida
- presencia del driver JDBC en NiFi

## Prueba de incremental

Con la fase aprovisionada, modificar una fila de `expedientes.admin_file`:

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
PG_PASS="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$PG_PASS" \
  psql -U postgres -d expedientes -c "update expedientes.admin_file set status = 'archivado', updated_at = now() where id = 1;"
```

Despues, reejecutar el flujo o esperar al siguiente ciclo de NiFi y revisar que aparece un nuevo JSON en el directorio de salida.

## Acceso a NiFi

Si el NodePort directo no responde, usar el acceso validado:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
```

URL:

```text
https://localhost:8443/nifi
```
