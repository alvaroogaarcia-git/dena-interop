# Grafana

## Que Es

Grafana es una herramienta de visualizacion. Muestra dashboards con metricas, logs y trazas desde distintos datasources.

## Objetivo En Este Piloto

Grafana es la consola principal de observabilidad. Permite ver el estado del stack, consumo, disponibilidad y señales tecnicas.

## Donde Esta

- Namespace: `monitoring`
- Deployment: `monitoring-grafana`
- Service NodePort: `31803`
- URL: `http://192.168.56.15:31803`

## Como Se Usa

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

## Que Contiene En Este Caso

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

## Como Verificarlo

```bash
bash scripts/verify-fase14.sh
curl -i http://192.168.56.15:31803/login
```

## Por Que Se Usa

Porque centraliza la observabilidad. Sin Grafana, las metricas/logs/trazas existen, pero son mas dificiles de consultar.
