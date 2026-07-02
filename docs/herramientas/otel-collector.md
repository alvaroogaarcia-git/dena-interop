# OTel Collector

## Que Es

OpenTelemetry Collector es un recolector y encaminador de telemetria. Recibe logs, metricas y trazas, las procesa y las envia a backends como Loki, Prometheus y Tempo.

## Objetivo En Este Piloto

Actua como punto unico de entrada para observabilidad tecnica.

## Donde Esta

- Namespace: `monitoring`
- Release Helm: `otel-collector`
- DaemonSet: `otel-collector-opentelemetry-collector-agent`
- Service: `otel-collector-opentelemetry-collector`

## Como Se Usa

Se configura por Helm:

```bash
helm get values otel-collector -n monitoring
```

Ver pods:

```bash
kubectl get daemonset -n monitoring otel-collector-opentelemetry-collector-agent
kubectl logs -n monitoring daemonset/otel-collector-opentelemetry-collector-agent --tail=80
```

## Que Contiene En Este Caso

Pipelines:

- Logs hacia Loki.
- Trazas hacia Tempo.
- Metricas hacia Prometheus.

## Como Verificarlo

```bash
kubectl rollout status daemonset/otel-collector-opentelemetry-collector-agent -n monitoring
```

## Por Que Se Usa

Porque desacopla la emision de telemetria de los backends concretos. Si cambia Loki, Tempo o Prometheus, se ajusta el Collector.
