# Loki

## Qué Es

Loki es un sistema de almacenamiento y consulta de logs. Está pensado para integrarse con Grafana.

## Objetivo En Este Piloto

Loki centraliza logs de los servicios para poder consultarlos desde Grafana.

## Dónde Está

- Namespace: `monitoring`
- StatefulSet: `loki`
- Service interno: `loki.monitoring.svc.cluster.local:3100`

## Cómo Se Usa

Normalmente se usa desde Grafana con el datasource `Loki`.

Comprobación interna:

```bash
kubectl run loki-check --rm -i --restart=Never --image=nginx:alpine -n monitoring -- \
  wget -qO- http://loki.monitoring.svc.cluster.local:3100/ready
```

## Qué Contiene En Este Caso

Loki está desplegado en modo `SingleBinary`, adecuado para un piloto single-node.

Recibe logs a través del OTel Collector.

## Cómo Verificarlo

```bash
kubectl rollout status statefulset/loki -n monitoring
bash scripts/verify-fase14.sh
```

## Por Qué Se Usa

Porque permite consultar logs sin entrar pod por pod con `kubectl logs`.
