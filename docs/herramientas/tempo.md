# Tempo

## Que Es

Tempo es un backend de trazas distribuidas. Guarda trazas para analizar el recorrido de una peticion entre servicios.

## Objetivo En Este Piloto

Tempo completa la observabilidad junto a Prometheus y Loki. Permite preparar el stack para trazabilidad cuando los servicios emitan trazas.

## Donde Esta

- Namespace: `monitoring`
- StatefulSet: `tempo`
- Service interno: `tempo.monitoring.svc.cluster.local:3200`
- OTLP gRPC: `4317`
- OTLP HTTP: `4318`

## Como Se Usa

Normalmente se consulta desde Grafana con el datasource `Tempo`.

Comprobacion interna:

```bash
kubectl run tempo-check --rm -i --restart=Never --image=nginx:alpine -n monitoring -- \
  wget -qO- http://tempo.monitoring.svc.cluster.local:3200/ready
```

## Que Contiene En Este Caso

Tempo recibe trazas desde el OTel Collector. En el piloto puede tener pocas trazas si los servicios no estan instrumentados.

## Como Verificarlo

```bash
kubectl rollout status statefulset/tempo -n monitoring
bash scripts/verify-fase14.sh
```

## Por Que Se Usa

Porque la trazabilidad ayuda a entender una peticion completa cuando intervienen gateway, identidad, API y servicios internos.
