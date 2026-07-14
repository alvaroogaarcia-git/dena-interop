# Fase 0: DietPi base

## Objetivo

Dejar la VM DietPi lista para instalar k3s: sistema actualizado, red correcta, swap desactivado y parámetros de kernel compatibles con Kubernetes.

## Comandos

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl wget git open-iscsi nfs-common iptables iproute2 kmod tar gzip unzip openssl sudo
sudo hostnamectl set-hostname dena
sudo modprobe overlay
sudo modprobe br_netfilter
printf 'overlay\nbr_netfilter\n' | sudo tee /etc/modules-load.d/k3s.conf
printf 'net.bridge.bridge-nf-call-iptables=1\nnet.ipv4.ip_forward=1\n' | sudo tee /etc/sysctl.d/99-k3s.conf
sudo sysctl --system
sudo swapoff -a
sudo sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab
ip -brief addr
curl -I https://github.com
```

## Que hace cada parte

- `apt-get update`: actualiza el índice local de paquetes.
- `apt-get install`: instala herramientas basicas para descargar, descomprimir, usar Git y preparar almacenamiento/red.
- `hostnamectl`: fija el nombre del nodo como `dena`.
- `modprobe overlay` y `modprobe br_netfilter`: cargan módulos de kernel necesarios para contenedores y red de Kubernetes.
- `tee /etc/modules-load.d/k3s.conf`: hace persistente la carga de módulos tras reiniciar.
- `tee /etc/sysctl.d/99-k3s.conf`: activa forwarding IP y filtrado de bridge.
- `sysctl --system`: aplica los parámetros de kernel.
- `swapoff -a`: desactiva swap en la sesión actual.
- `sed -i ... /etc/fstab`: evita que swap vuelva a activarse al reiniciar.
- `ip -brief addr`: comprueba que existe la IP esperada, normalmente `192.168.56.15`.
- `curl -I https://github.com`: confirma salida a internet.

## Verificación

```bash
sudo whoami
ip -brief addr
free -h
df -h /
```

Debe responder `root`, mostrar la IP host-only, tener memoria suficiente y disco disponible.

## Referencias

- [Guía de replicación de VM](../operacion/configuracion-vm-previa.md)
- [Histórico 0-3](historico/estado-fases-0-3.md)
