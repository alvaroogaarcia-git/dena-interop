# Loki

## Que Es

Loki es un sistema de almacenamiento y consulta de logs. Esta pensado para integrarse con Grafana.

## Objetivo En Este Piloto

Loki centraliza logs de los servicios para poder consultarlos desde Grafana.

## Donde Esta

- Namespace: `monitoring`
- StatefulSet: `loki`
- Service interno: `loki.monitoring.svc.cluster.local:3100`

## Como Se Usa

Normalmente se usa desde Grafana con el datasource `Loki`.

Comprobacion interna:

```bash
kubectl run loki-check --rm -i --restart=Never --image=nginx:alpine -n monitoring -- \
  wget -qO- http://loki.monitoring.svc.cluster.local:3100/ready
```

## Que Contiene En Este Caso

Loki esta desplegado en modo `SingleBinary`, adecuado para un piloto single-node.

Recibe logs a traves del OTel Collector.

## Como Verificarlo

```bash
kubectl rollout status statefulset/loki -n monitoring
bash scripts/verify-fase14.sh
```

## Por Que Se Usa

Porque permite consultar logs sin entrar pod por pod con `kubectl logs`.
