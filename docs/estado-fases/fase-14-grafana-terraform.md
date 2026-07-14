# Fase 14: Grafana por Terraform

## Objetivo

Gestionar datasources, carpeta `DENA` y dashboards de Grafana mediante Terraform.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
kubectl apply -f k8s-manifests/keycloak-servicemonitor.yaml
kubectl apply -f k8s-manifests/postgresql-exporters.yaml
bash scripts/dena/apply-fase14-grafana.sh
bash scripts/verify-fase14.sh
```

## Que hace cada parte

- `keycloak-servicemonitor.yaml`: permite a Prometheus descubrir métricas de Keycloak.
- `postgresql-exporters.yaml`: expone métricas de PostgreSQL.
- `apply-fase14-grafana.sh`: aplica Terraform para datasources y dashboards.
- `verify-fase14.sh`: consulta la API de Grafana para validar carpeta, datasources y dashboards.

## Verificación

```bash
bash scripts/verify-fase14.sh
```

## Referencias

- [Histórico 0-14](historico/estado-fases-0-14.md)
- [Grafana observabilidad](../arquitectura/grafana-observabilidad.md)
