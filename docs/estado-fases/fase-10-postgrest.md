# Fase 10: PostgREST

## Objetivo

Instalar PostgREST conectado al PostgreSQL del datalake para exponer la API interna SQL.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
. .local/fase4-6.env
pg_password="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -i -n datalake postgresql-datalake-0 -- env PGPASSWORD="$pg_password" psql -v ON_ERROR_STOP=1 -U postgres -d datalake -v postgrest_db_password="$TF_VAR_postgrest_db_password" < sql/00-postgrest-roles.sql
kubectl create secret generic postgrest-secret -n datalake --from-literal=db-uri="postgres://postgrest:${TF_VAR_postgrest_db_password}@postgresql-datalake.datalake.svc.cluster.local:5432/datalake" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s-manifests/postgrest-deployment.yaml
kubectl rollout status deployment/postgrest -n datalake --timeout=240s
bash scripts/verify-fase10.sh
```

## Que hace cada parte

- `pg_password=...`: lee la password real del Secret de PostgreSQL.
- `kubectl exec ... psql`: ejecuta SQL dentro del pod de PostgreSQL.
- `sql/00-postgrest-roles.sql`: crea roles y permisos de PostgREST.
- `postgrest-secret`: guarda la cadena de conexion.
- `kubectl apply`: despliega PostgREST.
- `verify-fase10.sh`: prueba conectividad y respuesta funcional.

## Verificacion

```bash
kubectl get pods,svc -n datalake -l app=postgrest -o wide
bash scripts/verify-fase10.sh
```

## Referencias

- [Historico 0-10](historico/estado-fases-0-10.md)
- [Manifiesto PostgREST](../../k8s-manifests/postgrest-deployment.yaml)
