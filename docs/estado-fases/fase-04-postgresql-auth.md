# Fase 4: PostgreSQL auth

## Objetivo

Desplegar PostgreSQL en el namespace `auth` para que Keycloak tenga base de datos persistente.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
. .local/fase4-6.env
kubectl create secret generic postgresql-auth -n auth --from-literal=postgres-password="$TF_VAR_postgres_password" --from-literal=password="$TF_VAR_postgres_password" --from-literal=replication-password="$TF_VAR_postgres_replication_password" --dry-run=client -o yaml | kubectl apply -f -
curl -kL --http1.1 --fail --output /tmp/postgresql-16.2.1.tgz https://charts.bitnami.com/bitnami/postgresql-16.2.1.tgz
helm upgrade --install postgresql /tmp/postgresql-16.2.1.tgz -n auth --values helm-values/postgresql-values.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n auth --timeout=240s
```

## Que hace cada parte

- `. .local/fase4-6.env`: carga passwords locales no versionadas.
- `kubectl create secret generic`: crea o actualiza el Secret usado por PostgreSQL.
- `--dry-run=client -o yaml | kubectl apply -f -`: hace el Secret idempotente.
- `curl ... postgresql-16.2.1.tgz`: descarga el chart validado.
- `helm upgrade --install`: instala o actualiza el release `postgresql`.
- `--values helm-values/postgresql-values.yaml`: aplica la configuracion versionada.
- `kubectl wait`: espera a que el pod este listo.

## Verificacion

```bash
kubectl get pods,svc,pvc -n auth -l app.kubernetes.io/name=postgresql -o wide
```

## Referencias

- [Historico 0-6](estado-fases-0-6.md)
- [Valores Helm](../../helm-values/postgresql-values.yaml)
