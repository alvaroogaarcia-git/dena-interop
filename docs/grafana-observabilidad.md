# Grafana y observabilidad del stack

Fecha de referencia: 2026-06-22

## Objetivo

Dejar Grafana como punto central del entorno para:

- metricas de cluster y nodo
- logs en Loki
- trazas en Tempo
- metricas de Keycloak
- metricas de las tres bases PostgreSQL
- dashboards operativos propios del stack

La autenticacion de Grafana sigue saliendo del secret `grafana-admin`. No se ha guardado ninguna credencial nueva en Git.

## Cambios versionados

### Grafana

Archivo: `helm-values/monitoring-values.yaml`

Se han dejado versionados:

- `uid: loki`
- `uid: tempo`
- `Tempo.serviceMap -> prometheus`
- `Tempo.tracesToLogsV2 -> loki`
- `Tempo.nodeGraph.enabled: true`
- `Loki.jsonData.maxLines: 1000`
- recursos de Grafana ajustados a nodo unico:
  - `requests.cpu: 25m`
  - `requests.memory: 64Mi`
  - `limits.memory: 192Mi`

Resultado validado por API de Grafana:

- `Prometheus`
- `Loki` con `uid=loki`
- `Tempo` con `uid=tempo`

### Keycloak

Archivo modificado: `k8s-manifests/keycloak-deployment.yaml`

Se ha activado:

- `KC_HEALTH_ENABLED=true`
- `KC_METRICS_ENABLED=true`
- puerto `management` en `9000`

Archivo nuevo: `k8s-manifests/keycloak-servicemonitor.yaml`

Resultado validado en Prometheus:

- `up{service="keycloak"} = 1`

### PostgreSQL

Archivo nuevo: `k8s-manifests/postgresql-exporters.yaml`

En vez de forzar `helm upgrade` sobre releases que ya contienen secretos sensibles en values locales, se ha desplegado observabilidad manual con:

- un `postgres-exporter` por namespace:
  - `auth`
  - `datalake`
  - `verticales`
- `Service` interno por exporter
- `ServiceMonitor` en `monitoring`
- `SecretRef` a secrets ya existentes del cluster

Recursos ajustados para el nodo:

- `requests.cpu: 10m`
- `requests.memory: 16Mi`
- `limits.memory: 64Mi`

Resultado validado en Prometheus:

- `pg_up` devuelve `1` para `auth`
- `pg_up` devuelve `1` para `datalake`
- `pg_up` devuelve `1` para `verticales`

Archivo adicional: `helm-values/postgresql-metrics-values.yaml`

Ese fichero queda preparado como alternativa futura si mas adelante quieres volver al camino de exporter embebido por Helm.

### Dashboards propios

Archivo nuevo: `k8s-manifests/grafana-dashboards.yaml`

Dashboards cargados y validados por API:

- `DENA Stack Overview`
- `DENA PostgreSQL Overview`

Desde Fase 14, Terraform es la fuente de verdad de estos dashboards y de los datasources principales. Los JSON versionados estan en `terraform/dashboards/` y se aplican con `scripts/dena/apply-fase14-grafana.sh`.

## Pasos aplicados de verdad en el cluster

Desde:

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config
```

### 1. Activar metricas de Keycloak

```bash
kubectl apply -f k8s-manifests/keycloak-deployment.yaml
kubectl apply -f k8s-manifests/keycloak-servicemonitor.yaml
```

### 2. Desplegar exporters PostgreSQL

```bash
kubectl apply -f k8s-manifests/postgresql-exporters.yaml
```

### 3. Cargar dashboards propios en Grafana

```bash
kubectl apply -f k8s-manifests/grafana-dashboards.yaml
```

### 4. Completar el rollout de Grafana en un nodo justo de memoria

Durante la aplicacion de cambios de Grafana, el nodo unico no tenia margen para un `RollingUpdate` con `maxSurge`. Para cerrarlo de forma controlada se hizo:

```bash
kubectl scale deployment monitoring-grafana -n monitoring --replicas=0
kubectl scale deployment monitoring-grafana -n monitoring --replicas=1
kubectl set resources deployment monitoring-grafana -n monitoring -c grafana \
  --requests=cpu=25m,memory=64Mi \
  --limits=memory=192Mi
kubectl scale rs monitoring-grafana-69f98764c5 -n monitoring --replicas=0
```

### 5. Reemplazar Keycloak para que arrancase con la nueva plantilla

```bash
kubectl delete pod -n auth -l app=keycloak
```

## Validacion ejecutada

### Grafana

API consultada con el usuario y password del secret `grafana-admin`.

Validado:

- `GET /api/datasources`
- `GET /api/search?query=DENA`

Resultado esperado y observado:

- datasources presentes:
  - `Prometheus`
  - `Loki`
  - `Tempo`
- dashboards presentes:
  - `DENA Stack Overview`
  - `DENA PostgreSQL Overview`

Acceso:

- `http://192.168.56.15:31803/login`

### Prometheus

Validacion hecha mediante `kubectl port-forward` temporal al servicio de Prometheus y consultas HTTP:

```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 19090:9090
curl -s 'http://127.0.0.1:19090/api/v1/query?query=pg_up'
curl -s 'http://127.0.0.1:19090/api/v1/query?query=up%7Bservice%3D%22keycloak%22%7D'
```

Resultados validados:

- `pg_up=1` en `auth`
- `pg_up=1` en `datalake`
- `pg_up=1` en `verticales`
- `up{service="keycloak"}=1`

## Estado final util

Desde Grafana ya quedan centralizados:

- metricas de Kubernetes
- metricas de nodo
- logs de pods via OTel Collector + Loki
- trazas en Tempo
- metricas de Keycloak
- metricas de PostgreSQL
- dashboards propios del stack

## Limites actuales

No he instrumentado todavia con metricas o trazas propias:

- `APISIX`
- `NiFi`
- `PostgREST`
- `Mathesar`

Esos cuatro siguen visibles por:

- estado de pod y namespace
- logs de contenedor en Loki
- consumo de recursos del pod en Prometheus

Para tenerlos con dashboards y trazas de aplicacion hace falta una fase posterior especifica por producto.
