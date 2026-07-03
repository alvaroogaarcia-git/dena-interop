# Estado Fases 0-7

Fecha: 2026-06-16

## Resumen

El clúster queda validado hasta Fase 7:

- Fases 0-6: ver `estado-fases-0-6.md`.
- Fase 7: observabilidad local en `monitoring`.

## Releases Helm

```text
monitoring  monitoring  kube-prometheus-stack-86.2.3  v0.91.0
loki        monitoring  loki-7.0.0                    3.6.7
tempo       monitoring  tempo-1.24.4                  2.9.0
```

## Grafana

- Release: `monitoring`
- Service: `monitoring-grafana`
- Tipo: `NodePort`
- Puerto: `31803`
- URL: `http://192.168.56.15:31803/login`
- Secret admin: `grafana-admin`
- Password local: `.local/fase7.env` (ignorado por Git)

Validación:

```text
HTTP/1.1 200 OK
<title>Grafana</title>
```

Datasources provisionados:

- `Prometheus`: `http://monitoring-kube-prometheus-prometheus.monitoring:9090/`
- `Loki`: `http://loki.monitoring.svc.cluster.local:3100`
- `Tempo`: `http://tempo.monitoring.svc.cluster.local:3200`

## Prometheus

- Chart: `kube-prometheus-stack-86.2.3`
- Prometheus Operator activo.
- Prometheus activo en `monitoring-kube-prometheus-prometheus`.
- Alertmanager desactivado para entorno local.
- Retencion: `7d`.
- Storage: `emptyDir`.
- Nota de disco: sin `retentionSize`; para producción definir `retentionSize` y PVC acotado.

Validación:

```text
Prometheus Server is Ready.
```

## Loki

- Chart: `loki-7.0.0`
- App: `3.6.7`
- Modo: `SingleBinary`
- StatefulSet: `loki`
- PVC: `storage-loki-0`, `4Gi`, `local-path`
- Caches: desactivadas.
- `read`, `write` y `backend`: réplicas `0`.

Validación:

```text
ready
```

Endpoint interno:

```text
http://loki.monitoring.svc.cluster.local:3100
```

## Tempo

- Chart: `tempo-1.24.4`
- App: `2.9.0`
- Pod: `tempo-0`
- Service: `tempo`
- Persistencia: desactivada.
- OTLP gRPC: `4317`
- OTLP HTTP: `4318`
- Readiness: `3200`

Validación:

```text
ready
```

Endpoint interno:

```text
http://tempo.monitoring.svc.cluster.local:3200
```

## Estado final esperado

```bash
kubectl get pods,svc,pvc -n monitoring -o wide
helm list -n monitoring
curl -i http://192.168.56.15:31803/login
```

Todos los pods de `monitoring` deben estar `Running`:

- `monitoring-grafana`
- `monitoring-kube-prometheus-operator`
- `monitoring-kube-state-metrics`
- `monitoring-prometheus-node-exporter`
- `prometheus-monitoring-kube-prometheus-prometheus-0`
- `loki-0`
- `tempo-0`
