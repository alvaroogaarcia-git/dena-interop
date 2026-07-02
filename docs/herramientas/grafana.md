# Grafana

## Qué Es

Grafana es una herramienta de visualización. Muestra dashboards con métricas, logs y trazas desde distintos datasources.

## Objetivo En Este Piloto

Grafana es la consola principal de observabilidad. Permite ver el estado del stack, consumo, disponibilidad y señales técnicas.

## Dónde Está

- Namespace: `monitoring`
- Deployment: `monitoring-grafana`
- Service NodePort: `31803`
- URL: `http://192.168.56.15:31803`

## Cómo Se Usa

Abrir:

```text
http://192.168.56.15:31803
```

Login demo:

- Usuario: `admin`
- Password: secret `monitoring/grafana-admin`

Recuperar password:

```bash
kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

## Qué Contiene En Este Caso

Datasources:

- Prometheus.
- Loki.
- Tempo.

Carpeta:

- `DENA`

Dashboards:

- `DENA Stack Overview`
- `DENA PostgreSQL Overview`
- `Observability Prometheus`
- `Observability Loki`
- `Observability Tempo`

## Cómo Verificarlo

```bash
bash scripts/verify-fase14.sh
curl -i http://192.168.56.15:31803/login
```

## Por Qué Se Usa

Porque centraliza la observabilidad. Sin Grafana, las métricas/logs/trazas existen, pero son más difíciles de consultar.
