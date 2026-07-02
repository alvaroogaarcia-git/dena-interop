# Preparación de Fase 8

Fecha: 2026-06-17

## Objetivo

Dejar el entorno listo para arrancar manualmente la Fase 8 de la guía:

- chart values versionado para `otel-collector`
- preflight de salud del stack previo
- receta corta de recuperación cuando el nodo vuelve de un reinicio con pods en `CreateContainerError`

## Archivos nuevos

- `helm-values/otel-collector-values.yaml`
- `scripts/preflight-fase8.sh`
- `scripts/recover-fase7.sh`

## Secuencia recomendada

Desde `/home/dietpi/dena-interop`:

```bash
export KUBECONFIG=~/.kube/dena-config
bash scripts/preflight-fase8.sh
```

Si el preflight falla por workloads no listos:

```bash
bash scripts/recover-fase7.sh
bash scripts/preflight-fase8.sh
```

Cuando el preflight pase:

```bash
helm install otel-collector open-telemetry/opentelemetry-collector \
  -n monitoring \
  --values helm-values/otel-collector-values.yaml
```

Validación mínima de Fase 8:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=otel-collector -n monitoring --timeout=240s
kubectl get pods,svc -n monitoring
kubectl get servicemonitor -n monitoring | grep otel
```

## Configuración aplicada al collector

- `mode: daemonset`
- logs a Loki por `otlphttp`
- trazas a Tempo por OTLP HTTP
- métricas expuestas en formato Prometheus para que las raspe `kube-prometheus-stack`
- presets activados:
  - `logsCollection`
  - `hostMetrics`
  - `kubernetesAttributes`
  - `kubeletMetrics`
  - `clusterMetrics`

## Nota operativa

El clúster actual no está en un estado válido para seguir instalando fases nuevas hasta recuperar:

- `keycloak`
- `apisix`
- varios componentes de `monitoring`
- `coredns` y `metrics-server`

La preparación de Fase 8 deja el material listo en el repo, pero presupone que primero vuelvas a tener Fase 7 sana.
