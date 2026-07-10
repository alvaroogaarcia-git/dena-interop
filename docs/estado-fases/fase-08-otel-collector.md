# Fase 8: OpenTelemetry Collector

## Objetivo

Instalar OpenTelemetry Collector como DaemonSet para recoger senales del nodo y enviarlas a la pila de observabilidad.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/preflight-fase8.sh
GODEBUG=http2client=0 helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
GODEBUG=http2client=0 helm repo update
GODEBUG=http2client=0 helm upgrade --install otel-collector open-telemetry/opentelemetry-collector -n monitoring --version 0.158.2 --values helm-values/otel-collector-values.yaml --timeout 10m
kubectl rollout status daemonset/otel-collector-opentelemetry-collector-agent -n monitoring --timeout=300s
```

## Que hace cada parte

- `preflight-fase8.sh`: comprueba que la Fase 7 esta sana antes de instalar.
- `helm repo add open-telemetry`: registra el repo del chart.
- `helm upgrade --install`: instala o actualiza el collector.
- `--values helm-values/otel-collector-values.yaml`: aplica pipelines versionadas.
- `rollout status daemonset`: espera a que el agente este listo en el nodo.

## Verificacion

```bash
kubectl get daemonset,pods -n monitoring -l app.kubernetes.io/instance=otel-collector -o wide
```

## Referencias

- [Historico 0-10](historico/estado-fases-0-10.md)
- [OTel Collector](../herramientas/otel-collector.md)
