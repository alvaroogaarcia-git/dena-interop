# OTel Collector

## Qué Es

OpenTelemetry Collector es un recolector y encaminador de telemetría. Recibe logs, métricas y trazas, las procesa y las envía a backends como Loki, Prometheus y Tempo.

## Objetivo En Este Piloto

Actúa como punto único de entrada para observabilidad técnica.

## Dónde Está

- Namespace: `monitoring`
- Release Helm: `otel-collector`
- DaemonSet: `otel-collector-opentelemetry-collector-agent`
- Service: `otel-collector-opentelemetry-collector`

## Cómo Se Usa

Se configura por Helm:

```bash
helm get values otel-collector -n monitoring
```

Ver pods:

```bash
kubectl get daemonset -n monitoring otel-collector-opentelemetry-collector-agent
kubectl logs -n monitoring daemonset/otel-collector-opentelemetry-collector-agent --tail=80
```

## Qué Contiene En Este Caso

Pipelines:

- Logs hacia Loki.
- Trazas hacia Tempo.
- Métricas hacia Prometheus.

## Cómo Verificarlo

```bash
kubectl rollout status daemonset/otel-collector-opentelemetry-collector-agent -n monitoring
```

## Por Qué Se Usa

Porque desacopla la emisión de telemetría de los backends concretos. Si cambia Loki, Tempo o Prometheus, se ajusta el Collector.
