# Fase 5: Keycloak

## Objetivo

Desplegar Keycloak en `auth`, conectado al PostgreSQL de la Fase 4.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
. .local/fase4-6.env
kubectl create secret generic keycloak-secret -n auth --from-literal=db-password="$TF_VAR_postgres_password" --from-literal=admin-password="$TF_VAR_keycloak_admin_password" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s-manifests/keycloak-deployment.yaml
kubectl rollout status deployment/keycloak -n auth --timeout=420s
```

## Que hace cada parte

- `. .local/fase4-6.env`: carga password de PostgreSQL y password admin de Keycloak.
- `kubectl create secret generic keycloak-secret`: crea el Secret consumido por el Deployment.
- `kubectl apply -f k8s-manifests/keycloak-deployment.yaml`: aplica el Deployment y Service de Keycloak.
- `kubectl rollout status`: espera a que el Deployment termine correctamente.

## Verificación

```bash
kubectl get pods,svc -n auth -l app=keycloak -o wide
kubectl logs -n auth deploy/keycloak --tail=80
```

## Referencias

- [Histórico 0-6](historico/estado-fases-0-6.md)
- [Manifiesto Keycloak](../../k8s-manifests/keycloak-deployment.yaml)
