# Fase 17: Portainer

## Objetivo

Desplegar Portainer CE para inspeccion operativa del cluster.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
. .local/demo.env
kubectl apply -f k8s-manifests/portainer-deployment.yaml
kubectl rollout status deployment/portainer -n portainer --timeout=240s
PORTAINER_ADMIN_PASSWORD="$PORTAINER_ADMIN_PASSWORD" bash scripts/dena/init-portainer.sh
```

## Que hace cada parte

- `. .local/demo.env`: carga la password admin de Portainer.
- `portainer-deployment.yaml`: crea Deployment, Service y almacenamiento.
- `rollout status`: espera a que Portainer este listo.
- `init-portainer.sh`: inicializa usuario admin y endpoint Kubernetes.

## Verificacion

```bash
kubectl get pods,svc,pvc -n portainer -o wide
curl -kI https://192.168.56.15:30779
```

## Referencias

- [Historico 0-17](estado-fases-0-17.md)
- [Portainer](../herramientas/portainer.md)
