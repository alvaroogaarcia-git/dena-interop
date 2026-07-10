# Fase 11: Apache NiFi

## Objetivo

Desplegar Apache NiFi 2.9 en `datalake` con HTTPS y autenticacion single-user.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
. .local/demo.env
kubectl create secret generic nifi-secret -n datalake --from-literal=single-user-username=admin --from-literal=single-user-password="$NIFI_SINGLE_USER_PASSWORD" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s-manifests/nifi-deployment.yaml
kubectl rollout status deployment/nifi -n datalake --timeout=600s
bash scripts/verify-fase11.sh
```

## Que hace cada parte

- `. .local/demo.env`: carga la password de NiFi.
- `nifi-secret`: crea credenciales single-user.
- `kubectl apply`: aplica Deployment, Service y volumen de NiFi.
- `rollout status`: espera a que NiFi arranque.
- `verify-fase11.sh`: valida el despliegue y acceso operativo.

## Verificacion

```bash
kubectl get pods,svc,pvc -n datalake -l app=nifi -o wide
bash scripts/verify-fase11.sh
```

## Referencias

- [Historico 0-11](estado-fases-0-11.md)
- [Manifiesto NiFi](../../k8s-manifests/nifi-deployment.yaml)
