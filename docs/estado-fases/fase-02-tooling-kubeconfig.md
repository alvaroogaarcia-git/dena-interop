# Fase 2: tooling local y kubeconfig

## Objetivo

Dejar disponibles `kubectl`, Helm y Terraform, y preparar un kubeconfig usable por el usuario `dietpi`.

## Comandos

```bash
sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl
mkdir -p /home/dietpi/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/dietpi/.kube/dena-config
sudo chown dietpi:dietpi /home/dietpi/.kube/dena-config
chmod 600 /home/dietpi/.kube/dena-config
export KUBECONFIG=/home/dietpi/.kube/dena-config
kubectl get nodes -o wide
helm version --short
terraform version
```

Si Helm o Terraform no existen, el bootstrap los instala automáticamente.

## Que hace cada parte

- `ln -sf`: crea el comando `kubectl` apuntando al binario de k3s.
- `mkdir -p`: crea la carpeta de configuración de Kubernetes del usuario.
- `cp k3s.yaml`: copia las credenciales del cluster.
- `chown` y `chmod`: dejan el kubeconfig accesible solo para `dietpi`.
- `export KUBECONFIG`: indica a `kubectl`, Helm y Terraform que usen ese cluster.
- `helm version` y `terraform version`: comprueban que las herramientas están instaladas.

## Verificación

```bash
kubectl get nodes -o wide
kubectl version --client=true
helm version --short
terraform version
```

## Referencias

- [Histórico 0-3](historico/estado-fases-0-3.md)
