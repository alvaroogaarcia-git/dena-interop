# Estado Fases 0-3

Fecha: 2026-06-16

## Fase 0 - DietPi

Validado:

- Paquetes instalados: `curl`, `wget`, `git`, `open-iscsi`, `nfs-common`, `iptables`.
- Swap sin entradas activas en `/etc/fstab`.
- Módulos cargados: `overlay`, `br_netfilter`.
- Persistencia de módulos: `/etc/modules-load.d/k3s.conf`.
- Sysctl aplicado y persistido en `/etc/sysctl.d/99-k3s.conf`:
  - `net.bridge.bridge-nf-call-iptables = 1`
  - `net.bridge.bridge-nf-call-ip6tables = 1`
  - `net.ipv4.ip_forward = 1`

## Fase 1 - K3s

Validado:

- Servicio `k3s` activo.
- Nodo `dietpi` en estado `Ready`.
- Configuración persistente creada en:
  - `/boot/dietpi-k3s.yaml`
  - `/etc/rancher/k3s/config.yaml`

Contenido aplicado:

```yaml
write-kubeconfig-mode: "0644"
disable:
  - traefik
  - servicelb
tls-san:
  - "192.168.56.15"
```

Traefik y servicelb:

- Eliminados los `HelmChart` de K3s para `traefik` y `traefik-crd`.
- Verificado que no quedan pods ni servicios Traefik en `kube-system`.
- Verificado que no quedan `helmcharts.helm.cattle.io`.

## Fase 2 - Tooling local + kubeconfig

Validado:

- `kubectl`: `v1.35.5+k3s1`
- `helm`: `v3.14.2`
- `terraform`: `v1.8.0`
- Kubeconfig creado en `/home/dietpi/.kube/dena-config`.
- Kubeconfig apunta a `https://192.168.56.15:6443`.
- Permisos de kubeconfig: `0600`.
- `.bashrc` exporta `KUBECONFIG=/home/dietpi/.kube/dena-config`.

Repos Helm disponibles:

- `bitnami`
- `apiseven`
- `prometheus-community`
- `grafana`
- `open-telemetry`

Configuración aplicada para red corporativa:

- Usar `GODEBUG=http2client=0` en operaciones Helm contra repos externos.
- `bitnami` está registrado contra `https://repo.broadcom.com/bitnami-files`.
  - Motivo: `https://charts.bitnami.com/bitnami` redirige a Broadcom y falla con `EOF` al combinar Helm y `--insecure-skip-tls-verify`.
- `apiseven` está registrado contra `https://apache.github.io/apisix-helm-chart`.
  - Motivo: `https://charts.apiseven.com` corta la conexión; el índice Apache contiene el chart `apiseven/apisix`.
- `helm repo update` no soporta `--insecure-skip-tls-verify` para repositorios; solo expone el flag equivalente para el API server de Kubernetes.

Validación de charts:

- `helm repo update` funciona con los cinco repos configurados.
- `apiseven/apisix` versión `2.14.1` resuelve y el paquete incluye sus dependencias `etcd`, `common` y `apisix-ingress-controller`.
- `bitnami/postgresql` versión actual `18.7.5` resuelve en el índice, pero descarga desde OCI/Docker Hub y falla en esta red con `403 Forbidden` al pedir token anónimo.
- `bitnami/postgresql` versión `16.2.1` descarga como `.tgz` tradicional y contiene `charts/common` empaquetado.

## Fase 3 - Namespaces

Namespaces de la guía aplicados de forma declarativa:

- `auth`
- `gateway`
- `app`
- `monitoring`
- `datalake`
- `verticales`

Estado final:

- No existe namespace `apps`.
- No hay releases Helm instalados.
- No hay workloads de fases posteriores en namespaces de aplicación.
- Solo quedan workloads base de `kube-system`: CoreDNS, local-path-provisioner y metrics-server.
