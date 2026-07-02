# Prometheus

## Que Es

Prometheus es una base de datos de metricas y un motor de consulta temporal. Recoge metricas de Kubernetes y de servicios instrumentados.

## Objetivo En Este Piloto

Prometheus permite saber si los pods estan vivos, cuanta CPU/memoria consumen y que componentes fallan.

## Donde Esta

- Namespace: `monitoring`
- StatefulSet: `prometheus-monitoring-kube-prometheus-prometheus`
- Service interno: `prometheus-operated:9090`
- Acceso recomendado: Grafana o port-forward.

## Como Se Usa

Port-forward:

```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

Abrir:

```text
http://localhost:9090
```

## Que Contiene En Este Caso

Metricas de:

- Kubernetes.
- Node exporter.
- kube-state-metrics.
- PostgreSQL exporters.
- Keycloak ServiceMonitor.
- APISIX prometheus plugin, cuando aplica.
- OTel Collector metrics pipeline.

## Como Verificarlo

```bash
kubectl rollout status statefulset/prometheus-monitoring-kube-prometheus-prometheus -n monitoring
```

Desde Grafana:

- Datasource `Prometheus`.
- Dashboards de la carpeta `DENA`.

## Por Que Se Usa

Porque las metricas permiten detectar problemas antes de mirar logs: pods sin replicas, reinicios, consumo alto o servicios caidos.
