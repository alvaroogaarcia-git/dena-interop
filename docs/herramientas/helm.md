# Helm

## Qué Es

Helm es un gestor de paquetes para Kubernetes. Instala aplicaciones completas a partir de charts, que son plantillas parametrizables de manifiestos Kubernetes.

## Objetivo En Este Piloto

Helm instala los productos que tienen chart estable:

- PostgreSQL.
- APISIX.
- Prometheus/Grafana.
- Loki.
- Tempo.
- OTel Collector.

Keycloak, PostgREST, NiFi, Mathesar, Portainer y la SPA se despliegan con manifiestos propios porque se necesita más control o el despliegue es sencillo.

## Dónde Está

Se ejecuta en la máquina de operador, usando el mismo kubeconfig que `kubectl`.

Releases actuales:

```bash
helm list -A
```

## Cómo Se Usa

Instalar o actualizar:

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --values helm-values/monitoring-values.yaml
```

Ver histórico:

```bash
helm history monitoring -n monitoring
```

Ver valores aplicados:

```bash
helm get values monitoring -n monitoring
```

## Qué Contiene En Este Caso

Los valores versionados están en `helm-values/`:

- `apisix-values.yaml`
- `monitoring-values.yaml`
- `loki-values.yaml`
- `tempo-values.yaml`
- `otel-collector-values.yaml`
- `postgresql-values.yaml`
- `postgresql-datalake-values.yaml`
- `postgresql-verticales-values.yaml`

## Cómo Verificarlo

```bash
helm list -A
```

Resultado esperado: releases `apisix`, `postgresql`, `postgresql-datalake`, `postgresql-verticales`, `monitoring`, `loki`, `tempo` y `otel-collector`.

## Por Qué Se Usa

Porque reduce errores al instalar productos complejos y deja la configuración principal en ficheros `values.yaml` versionados.
