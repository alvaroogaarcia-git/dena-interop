# kubectl

## Qué Es

`kubectl` es la herramienta de línea de comandos para hablar con Kubernetes. Permite ver recursos, aplicar manifiestos, consultar logs, hacer port-forward y diagnosticar problemas.

## Objetivo En Este Piloto

Se usa para operar todo el clúster k3s desde la máquina de operador sin entrar por SSH al servidor.

## Dónde Está

- Se ejecuta en la máquina de operador.
- Usa `KUBECONFIG=/home/dietpi/.kube/dena-config`.
- Habla con el API server de k3s en `192.168.56.15:6443`.

## Cómo Se Usa

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

## Qué Contiene En Este Caso

`kubectl` no contiene datos por sí mismo. Es la herramienta que permite consultar y modificar los objetos Kubernetes del clúster:

- Deployments.
- StatefulSets.
- Services.
- Secrets.
- ConfigMaps.
- PVCs.
- Pods.

## Cómo Verificarlo

```bash
kubectl get nodes
```

Si devuelve el nodo `dietpi`, la conexión al clúster está bien.

## Por Qué Se Usa

Porque es la herramienta estándar para operar Kubernetes. Permite que todos los cambios sean reproducibles mediante manifiestos versionados.
