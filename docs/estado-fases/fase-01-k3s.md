# Fase 1: k3s

## Objetivo

Instalar k3s como cluster Kubernetes de un solo nodo, sin Traefik ni servicelb, para que APISIX sea el gateway HTTP principal.

## Comandos

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.35.5+k3s1' INSTALL_K3S_EXEC='server --disable traefik --disable servicelb --write-kubeconfig-mode 0644 --node-ip 192.168.56.15 --tls-san 192.168.56.15' sh -
sudo systemctl enable --now k3s
sudo k3s kubectl wait --for=condition=Ready node --all --timeout=180s
sudo k3s kubectl get nodes -o wide
```

## Que hace cada parte

- `curl -sfL https://get.k3s.io`: descarga el instalador oficial de k3s.
- `INSTALL_K3S_VERSION`: fija la version validada.
- `--disable traefik`: evita instalar Traefik porque se usa APISIX.
- `--disable servicelb`: evita el balanceador local incluido por defecto.
- `--write-kubeconfig-mode 0644`: permite leer el kubeconfig generado.
- `--node-ip`: fija la IP del nodo Kubernetes.
- `--tls-san`: anade la IP al certificado de la API de Kubernetes.
- `systemctl enable --now k3s`: activa k3s y lo deja arrancando automaticamente.
- `kubectl wait`: espera a que el nodo este `Ready`.

## Verificacion

```bash
sudo systemctl status k3s
sudo k3s kubectl get nodes -o wide
```

El nodo debe aparecer `Ready`.

## Referencias

- [Historico 0-3](historico/estado-fases-0-3.md)
