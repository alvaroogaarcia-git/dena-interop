# Fase 11b: Verticales y Mathesar

## Objetivo

Crear el origen vertical `expedientes`, instalar Mathesar y dejar el driver JDBC de PostgreSQL disponible para NiFi.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/install-nifi-postgresql-driver.sh
helm upgrade --install postgresql-verticales bitnami/postgresql -n verticales --version 18.7.5 --values helm-values/postgresql-verticales-values.yaml --timeout 10m
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n verticales --timeout=300s
pgv="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -i -n verticales postgresql-verticales-0 -- env PGPASSWORD="$pgv" psql -v ON_ERROR_STOP=1 -U postgres -d postgres -c "SELECT 'CREATE DATABASE mathesar_django' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mathesar_django')\\gexec"
kubectl exec -i -n verticales postgresql-verticales-0 -- env PGPASSWORD="$pgv" psql -v ON_ERROR_STOP=1 -U postgres -d expedientes < sql/verticales/01-expedientes-source.sql
kubectl exec -i -n verticales postgresql-verticales-0 -- env PGPASSWORD="$pgv" psql -v ON_ERROR_STOP=1 -U postgres -d expedientes < sql/verticales/02-state-check.sql
bash scripts/dena/load-expedientes.sh
kubectl create secret generic mathesar-secret -n verticales --from-literal=db-password="$pgv" --from-literal=secret-key="$(openssl rand -base64 50)" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s-manifests/mathesar-deployment.yaml
kubectl rollout status deployment/mathesar -n verticales --timeout=300s
bash scripts/verify-fase11b.sh
```

## Que hace cada parte

- `install-nifi-postgresql-driver.sh`: instala el driver JDBC persistente en NiFi.
- `postgresql-verticales`: crea la base origen de expedientes.
- `pgv=...`: lee la password generada por el chart.
- `CREATE DATABASE mathesar_django`: crea la base interna de Mathesar si falta.
- `01-expedientes-source.sql`: crea la tabla origen.
- `02-state-check.sql`: crea objetos de control incremental.
- `load-expedientes.sh`: carga datos demo.
- `mathesar-secret` y `mathesar-deployment.yaml`: despliegan Mathesar.

## Verificacion

```bash
kubectl get pods,svc,pvc -n verticales -o wide
bash scripts/verify-fase11b.sh
```

## Referencias

- [Historico 0-11b](estado-fases-0-11b.md)
- [Mathesar](../herramientas/mathesar.md)
