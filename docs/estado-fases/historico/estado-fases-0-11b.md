# Estado Fases 0-12

Fecha: 2026-06-22

## Resumen

El clúster queda validado hasta Fase 12:

- Fases 0-11: ver `estado-fases-0-11.md`.
- Fase 11b: origen PostgreSQL en `verticales`, Mathesar local y driver JDBC de PostgreSQL persistido en NiFi.
- Fase 12: flujo JDBC incremental NiFi operativo, idempotente y persistente tras reinicio.

Pendiente a partir de aqui:

- rutas APISIX
- esquema DENA de Fase 15
- Terraform de fases posteriores

## Fase 11b - Verticales: PostgreSQL origen + Mathesar Local

ADR-008: la BD del namespace `verticales` simula un sistema origen de la empresa. La tabla `expedientes.admin_file` es la fuente editable; Mathesar la expone por web y NiFi queda preparado para leer cambios incrementales por `updated_at`.

Recursos versionados:

- Helm values: `helm-values/postgresql-verticales-values.yaml`
- Deployment/Service: `k8s-manifests/mathesar-deployment.yaml`
- SQL base: `sql/verticales/01-expedientes-source.sql`
- CHECK de estado: `sql/verticales/02-state-check.sql`
- Carga inicial: `scripts/dena/load-expedientes.sh`
- Driver JDBC NiFi: `scripts/dena/install-nifi-postgresql-driver.sh`

Estado validado:

- Release Helm: `postgresql-verticales`
- Namespace: `verticales`
- StatefulSet: `postgresql-verticales`
- Base creada por chart: `expedientes`
- Base interna de Mathesar: `mathesar_django`
- Tabla origen: `expedientes.admin_file`
- Filas de ejemplo: `50`
- Deployment: `mathesar`
- Service type: `NodePort`
- NodePort Mathesar: `30900`
- Driver JDBC NiFi: `postgresql-42.7.4.jar` en `nifi-extensions`

Configuración validada:

- Mathesar usa `POSTGRES_HOST=postgresql-verticales.verticales.svc.cluster.local`
- Mathesar usa `POSTGRES_DB=mathesar_django`
- Mathesar usa `WEB_CONCURRENCY=1` para ajustarse al nodo actual
- probes TCP sobre `:8000`
- NiFi mantiene acceso de operador por `kubectl port-forward`
- el origen CSV/GetFile queda reemplazado por PostgreSQL como fuente de cambios

Validación esperada:

```text
postgresql-verticales-0   1/1   Running
mathesar-...             1/1   Running
service/mathesar         NodePort   ...   8000:30900/TCP
```

Accesos de operador:

```text
Mathesar: http://192.168.56.15:30900
NiFi: https://localhost:8443/nifi
```

Notas operativas:

- En este corte historico el primer arranque de Mathesar requeria crear el usuario admin desde la UI; en el estado actual lo inicializa `scripts/bootstrap-demo.sh`.
- Dentro de Mathesar hay que añadir la conexión a `expedientes` usando `postgres`.
- El NodePort directo de NiFi `30821` sigue devolviendo `400`; el acceso validado continua siendo por port-forward.
- La Fase 12 versiona el flujo NiFi JDBC incremental; Fase 11b deja preparado el origen, el driver y la conectividad.
- En este nodo de `4 GiB`, Mathesar queda reducido a `128Mi` de request y `256Mi` de limit para poder programarse.

## Comandos de cierre

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config

bash scripts/verify-fase11.sh
bash scripts/dena/install-nifi-postgresql-driver.sh
bash scripts/verify-fase11b.sh
```

Estado esperado:

- `statefulset/postgresql-verticales` en `Ready`
- `deployment/mathesar` en `Available`
- `expedientes.admin_file` con `50` filas
- `postgresql-42.7.4.jar` presente en `extensions/` de NiFi

## Fase 12 validada

- Grupo `Fase 12 - JDBC incremental` presente.
- Tres procesadores en `VALID/RUNNING`.
- `Verticales DBCP` y `JSON Record Writer` en `VALID/ENABLED`.
- JSON de salida generado en el PVC.
- Flujo conservado tras `kubectl rollout restart deployment/nifi -n datalake`.

Procedimiento: [fase12-nifi-jdbc.md](../../guias/fase12-nifi-jdbc.md).
Optimización del nodo: [optimizacion-k3s-4gb.md](../../operacion/optimizacion-k3s-4gb.md).
