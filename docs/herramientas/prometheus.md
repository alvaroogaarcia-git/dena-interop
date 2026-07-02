# Prometheus

## Qué Es

Prometheus es una base de datos de métricas y un motor de consulta temporal. Recoge métricas de Kubernetes y de servicios instrumentados.

## Objetivo En Este Piloto

Prometheus permite saber si los pods están vivos, cuánta CPU/memoria consumen y qué componentes fallan.

## Dónde Está

- Namespace: `monitoring`
- StatefulSet: `prometheus-monitoring-kube-prometheus-prometheus`
- Service interno: `prometheus-operated:9090`
- Acceso recomendado: Grafana o port-forward.

## Cómo Se Usa

Port-forward:

```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

Abrir:

```text
http://localhost:9090
```

## Qué Contiene En Este Caso

Métricas de:

- Kubernetes.
- Node exporter.
- kube-state-metrics.
- PostgreSQL exporters.
- Keycloak ServiceMonitor.
- APISIX prometheus plugin, cuando aplica.
- OTel Collector metrics pipeline.

## Cómo Verificarlo

```bash
kubectl rollout status statefulset/prometheus-monitoring-kube-prometheus-prometheus -n monitoring
```

Desde Grafana:

- Datasource `Prometheus`.
- Dashboards de la carpeta `DENA`.

## Por Qué Se Usa

Porque las métricas permiten detectar problemas antes de mirar logs: pods sin réplicas, reinicios, consumo alto o servicios caídos.
