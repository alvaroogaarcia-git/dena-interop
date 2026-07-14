# Fase 9: PostgreSQL datalake

## Objetivo

Desplegar PostgreSQL en `datalake`, que será la base consolidada expuesta por PostgREST y alimentada por NiFi.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
GODEBUG=http2client=0 helm repo add bitnami https://repo.broadcom.com/bitnami-files --force-update
GODEBUG=http2client=0 helm repo update
helm upgrade --install postgresql-datalake bitnami/postgresql -n datalake --version 18.7.5 --values helm-values/postgresql-datalake-values.yaml --timeout 10m
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n datalake --timeout=300s
```

## Que hace cada parte

- `helm repo add bitnami`: registra el repo del chart PostgreSQL.
- `helm upgrade --install`: crea el release `postgresql-datalake`.
- `--version 18.7.5`: fija la versión validada del chart.
- `--values`: aplica usuarios, base y persistencia versionados.
- `kubectl wait`: espera a que PostgreSQL acepte conexiones.

## Verificación

```bash
kubectl get pods,svc,pvc -n datalake -l app.kubernetes.io/name=postgresql -o wide
```

## Referencias

- [Histórico 0-10](historico/estado-fases-0-10.md)
- [Valores datalake](../../helm-values/postgresql-datalake-values.yaml)
