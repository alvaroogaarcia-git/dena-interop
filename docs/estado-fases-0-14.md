# Estado Fases 0-14

Fecha: 2026-06-25

## Resumen

El alcance consolidado queda validado hasta Fase 14:

- Fases 0-13: plataforma, autenticacion, gateway, observabilidad, datalake, NiFi, verticales y API DENA protegida por OIDC.
- Fase 14: Grafana queda gestionado por Terraform para datasources, carpeta y dashboards operativos DENA.

## Fase 14 - Terraform y Grafana

Estado versionado:

- provider `grafana/grafana` 3.25.9 bloqueado en `.terraform.lock.hcl`
- provider `grafana` configurado contra port-forward local
- datasources gestionados por Terraform:
  - `Prometheus` con `uid=prometheus`
  - `Loki` con `uid=loki`
  - `Tempo` con `uid=tempo`
- carpeta Grafana `DENA` con `uid=dena`
- dashboards gestionados por Terraform:
  - `DENA Stack Overview` con `uid=dena-stack-overview`
  - `DENA PostgreSQL Overview` con `uid=dena-postgresql-overview`

Los dashboards viven como JSON en `terraform/dashboards/` para que Terraform sea la fuente de verdad de Grafana.

## Aplicacion reproducible

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config

bash scripts/dena/apply-fase14-grafana.sh
bash scripts/verify-fase14.sh
```

El script de aplicacion:

- obtiene credenciales desde el Secret `monitoring/grafana-admin`
- ejecuta `helm upgrade monitoring` con `helm-values/monitoring-values.yaml` para desactivar el provisioning read-only de datasources
- abre port-forward local contra `svc/monitoring-grafana`
- ejecuta `terraform init`
- aplica solo los recursos Grafana con `terraform apply -target=...`

## Verificacion

`scripts/verify-fase14.sh` comprueba por API de Grafana:

- salud de Grafana con base de datos `ok`
- datasources `prometheus`, `loki` y `tempo`
- carpeta `dena`
- dashboards `dena-stack-overview` y `dena-postgresql-overview`

## Siguiente fase

La siguiente fase abierta es la Fase 15: completar SQL DENA y carga al datalake segun la issue correspondiente.
