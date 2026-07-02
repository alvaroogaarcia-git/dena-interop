# kubectl

## Que Es

`kubectl` es la herramienta de linea de comandos para hablar con Kubernetes. Permite ver recursos, aplicar manifiestos, consultar logs, hacer port-forward y diagnosticar problemas.

## Objetivo En Este Piloto

Se usa para operar todo el cluster k3s desde la maquina de operador sin entrar por SSH al servidor.

## Donde Esta

- Se ejecuta en la maquina de operador.
- Usa `KUBECONFIG=/home/dietpi/.kube/dena-config`.
- Habla con el API server de k3s en `192.168.56.15:6443`.

## Como Se Usa

Comandos frecuentes:

```bash
kubectl get ns
kubectl get pods -A
kubectl get svc -A
kubectl logs -n auth deploy/keycloak --tail=80
kubectl describe pod -n gateway -l app.kubernetes.io/name=apisix
kubectl rollout status deployment/apisix -n gateway --timeout=180s
```

Para aplicar manifiestos:

```bash
kubectl apply -f k8s-manifests/dena-interop-spa.yaml
kubectl apply -f k8s-manifests/portainer-deployment.yaml
```

Para abrir accesos temporales:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
kubectl port-forward -n gateway svc/apisix-admin 9180:9180
```

## Que Contiene En Este Caso

`kubectl` no contiene datos por si mismo. Es la herramienta que permite consultar y modificar los objetos Kubernetes del cluster:

- Deployments.
- StatefulSets.
- Services.
- Secrets.
- ConfigMaps.
- PVCs.
- Pods.

## Como Verificarlo

```bash
kubectl get nodes
```

Si devuelve el nodo `dietpi`, la conexion al cluster esta bien.

## Por Que Se Usa

Porque es la herramienta estandar para operar Kubernetes. Permite que todos los cambios sean reproducibles mediante manifiestos versionados.
