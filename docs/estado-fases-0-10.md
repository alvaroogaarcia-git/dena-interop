# Estado Fases 0-10

Fecha: 2026-06-19

## Resumen

El clúster queda validado hasta Fase 10:

- Fases 0-7: ver `docs/estado-fases-0-7.md`.
- Fase 8: `otel-collector` desplegado y sano en `monitoring`.
- Fase 9: PostgreSQL del datalake desplegado y sano en `datalake`.
- Fase 10: PostgREST desplegado, conectado al datalake y validado funcionalmente.

No se ha empezado la Fase 11:

- No hay recursos en `verticales`.
- No hay NiFi.
- No hay Mathesar.
- APISIX sigue sin rutas.
- El esquema DENA de Fase 15 todavía no está aplicado.

## Releases Helm

```text
apisix              gateway     apisix-2.14.1                    3.16.0
loki                monitoring  loki-7.0.0                       3.6.7
monitoring          monitoring  kube-prometheus-stack-86.2.3     v0.91.0
otel-collector      monitoring  opentelemetry-collector-0.158.2  0.153.0
postgresql          auth        postgresql-16.2.1                17.1.0
postgresql-datalake datalake    postgresql-18.7.5                18.4.0
tempo               monitoring  tempo-1.24.4                     2.9.0
```

## Fase 8 - OTel Collector

- Release: `otel-collector`
- Namespace: `monitoring`
- Chart: `opentelemetry-collector-0.158.2`
- Modo: `DaemonSet`
- Service: `otel-collector-opentelemetry-collector`

Validación:

```text
otel-collector-opentelemetry-collector-agent-...   1/1   Running
```

Pipelines validadas:

- logs hacia Loki por `otlphttp`
- trazas hacia Tempo por OTLP HTTP
- métricas expuestas para scrape de Prometheus

## Fase 9 - PostgreSQL datalake

- Release: `postgresql-datalake`
- Namespace: `datalake`
- Chart: `postgresql-18.7.5`
- App: `18.4.0`
- StatefulSet: `postgresql-datalake`
- Service: `postgresql-datalake`
- PVC: `data-postgresql-datalake-0`, `4Gi`, `local-path`
- Base de datos objetivo: `datalake`

Validación:

```text
postgresql-datalake-0   1/1   Running
```

## Fase 10 - PostgREST

- Deployment: `postgrest`
- Service: `postgrest`
- Namespace: `datalake`
- Imagen: `postgrest/postgrest:v13.0.4`
- Puerto: `3000`
- `PGRST_DB_SCHEMAS=public`
- `PGRST_DB_ANON_ROLE=anon`
- `PGRST_OPENAPI_SERVER_PROXY_URI=http://192.168.56.15:30080/api`

Secret validado:

- `postgrest-secret`
- DSN esperado:

```text
postgres://postgrest:<password>@postgresql-datalake.datalake.svc.cluster.local:5432/datalake
```

Roles de base de datos validados:

```text
anon|f
postgrest|t
postgrest->anon
```

Validación HTTP:

```text
HTTP/1.1 200 OK
Server: postgrest/13.0.4
Content-Type: application/openapi+json; charset=utf-8
```

La raíz `/` del servicio devuelve el documento OpenAPI del esquema `public`, lo que confirma:

- conectividad entre `postgrest` y `postgresql-datalake`
- password correcta en `postgrest-secret`
- roles `anon` y `postgrest` operativos
- servicio interno accesible en el clúster

## Comandos de cierre

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config

bash scripts/verify-fase10.sh
kubectl get pods,svc,pvc -n datalake -o wide
kubectl logs -n datalake deploy/postgrest --tail=80
```

Estado esperado:

- `postgresql-datalake-0` en `Running`
- `postgrest` en `Running`
- `service/postgrest` en `ClusterIP`
- `scripts/verify-fase10.sh` termina sin error

## Siguiente fase

La siguiente fase de la guía es la Fase 11, pero no forma parte de este cierre.
