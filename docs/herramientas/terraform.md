# Terraform

## Qué Es

Terraform es una herramienta de infraestructura como código. Declara recursos en ficheros `.tf` y los aplica contra APIs externas.

## Objetivo En Este Piloto

Terraform configura servicios ya desplegados:

- Keycloak:
  - realm `piloto`
  - clientes `react-frontend` y `apisix-gateway`
  - roles `dena-reader`, `dena-writer`, `dena-admin`
  - usuario `testuser`
- Grafana:
  - datasources `Prometheus`, `Loki` y `Tempo`
  - carpeta `DENA`
  - dashboards versionados

## Dónde Está

Directorio:

```text
terraform/
```

Ficheros principales:

- `main.tf`: Keycloak.
- `grafana.tf`: Grafana.
- `providers.tf`: providers.
- `variables.tf`: variables.
- `outputs.tf`: salidas.
- `dashboards/`: JSON de dashboards.

## Cómo Se Usa

Los scripts recomendados son:

```bash
bash scripts/dena/apply-fase12-keycloak.sh
bash scripts/dena/apply-fase14-grafana.sh
```

Validación manual:

```bash
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```

## Qué Contiene En Este Caso

Terraform contiene la configuración funcional, no los contenedores. Los contenedores los despliega Kubernetes/Helm; Terraform configura Keycloak y Grafana por API.

## Cómo Verificarlo

```bash
terraform -chdir=terraform validate
bash scripts/verify-fase12-keycloak.sh
bash scripts/verify-fase14.sh
```

## Por Qué Se Usa

Porque Keycloak y Grafana tienen mucha configuración interna. Terraform evita hacerla a mano en la UI y permite revisarla en Git.

## Nota De Seguridad

El estado Terraform puede contener secretos. Por eso `terraform/*.tfstate` está ignorado por Git.
