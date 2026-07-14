# Fase 7: observabilidad local

## Objetivo

Instalar Prometheus/Grafana, Loki y Tempo en `monitoring`.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
. .local/fase7.env
kubectl create secret generic grafana-admin -n monitoring --from-literal=admin-user=admin --from-literal=admin-password="$TF_VAR_grafana_admin_password" --dry-run=client -o yaml | kubectl apply -f -
GODEBUG=http2client=0 helm repo add grafana https://grafana.github.io/helm-charts --force-update
GODEBUG=http2client=0 helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
GODEBUG=http2client=0 helm repo update
GODEBUG=http2client=0 helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --version 86.2.3 --values helm-values/monitoring-values.yaml --timeout 15m
GODEBUG=http2client=0 helm upgrade --install loki grafana/loki -n monitoring --version 7.0.0 --values helm-values/loki-values.yaml --timeout 10m
GODEBUG=http2client=0 helm upgrade --install tempo grafana/tempo -n monitoring --version 1.24.4 --values helm-values/tempo-values.yaml --timeout 10m
kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=300s
kubectl rollout status statefulset/loki -n monitoring --timeout=300s
kubectl rollout status statefulset/tempo -n monitoring --timeout=300s
```

## Que hace cada parte

- `. .local/fase7.env`: carga la password admin de Grafana.
- `grafana-admin`: crea el Secret de login de Grafana.
- `helm repo add`: registra repos de Grafana y Prometheus.
- `kube-prometheus-stack`: instala Prometheus, Grafana y operadores.
- `loki`: instala almacenamiento de logs.
- `tempo`: instala almacenamiento de trazas.
- `rollout status`: espera a que los componentes principales esten listos.

## Verificación

```bash
helm list -n monitoring
kubectl get pods,svc,pvc -n monitoring -o wide
curl -i http://192.168.56.15:31803/login
```

## Referencias

- [Histórico 0-7](historico/estado-fases-0-7.md)
- [Grafana observabilidad](../arquitectura/grafana-observabilidad.md)
