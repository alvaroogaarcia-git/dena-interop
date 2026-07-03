# Extensión 11c - NiFi JDBC incremental

Nota de numeración: este flujo se implementó originalmente con el nombre interno `Fase 12`. En el plan consolidado queda como extensión 11c; la Fase 12 corresponde a Terraform y Keycloak. Se conservan nombres de scripts y del grupo NiFi por compatibilidad.

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

En la raíz de NiFi se ve un solo bloque de grupo; al abrirlo aparecen los tres procesadores y los dos controller services de la fase.

## Requisitos previos

- `k3s` activo
- NiFi en `Running/Ready`
- driver `postgresql-42.7.4.jar` copiado a `extensions/` con `bash scripts/dena/install-nifi-postgresql-driver.sh`
- secret `nifi-secret` operativo
- PostgreSQL de `verticales` en `Running`

## Aprovisionamiento

Ejecutar:

```bash
bash scripts/dena/provision-fase12-nifi.sh
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
bash scripts/verify-fase12.sh
```

La verificación comprueba:

- presencia del grupo de proceso
- los tres procesadores en `VALID/RUNNING`
- DBCP y Record Writer en `VALID/ENABLED`
- disponibilidad del directorio de salida
- presencia del driver JDBC en NiFi

La validación realizada generó un fichero `fase12-*.json` en el PVC.

## Persistencia

El deployment configura `nifi.flow.configuration.file` sobre `/persistent/conf/flow.json.gz`, dentro de `nifi-extensions`. La clave `nifi.sensitive.props.key` se obtiene de `nifi-secret`, por lo que las propiedades JDBC cifradas se pueden leer después de recrear el pod.

Prueba validada:

```bash
kubectl rollout restart deployment/nifi -n datalake
kubectl rollout status deployment/nifi -n datalake --timeout=15m
bash scripts/verify-fase12.sh
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

Después, reejecutar el flujo o esperar al siguiente ciclo de NiFi y revisar que aparece un nuevo JSON en el directorio de salida.

## Acceso a NiFi

Si el NodePort directo no responde, usar el acceso validado:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
```

URL:

```text
https://localhost:8443/nifi
```
