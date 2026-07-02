# Configuracion previa de la VM demo

Esta guia deja una VM DietPi preparada para replicar `dena-interop`, incluyendo red, IP fija y comprobaciones previas. Termina justo antes de pulsar `Enter` en el comando que ejecuta el bootstrap.

## Objetivo

La demo esta pensada para una VM de un solo nodo con dos interfaces:

- NAT: salida a internet para descargar paquetes, charts e imagenes.
- Host-only: acceso desde el ordenador host a la demo.

La IP esperada por defecto es:

```text
192.168.56.15
```

Si usas otra IP, el bootstrap tambien funciona, pero debes pasarla con `DENA_NODE_IP=<ip>`.

## Recursos recomendados

- Sistema: DietPi x86_64 limpio.
- CPU: 2 vCPU minimo.
- RAM: 4 GiB minimo; 8 GiB recomendado.
- Disco: 40 GiB recomendado.
- Usuario: `dietpi` con sudo.
- Red 1: NAT.
- Red 2: host-only.

## Configuracion de red en VirtualBox

En VirtualBox, crea o revisa la red host-only:

1. Abre `Tools` -> `Network` -> `Host-only Networks`.
2. Crea una red tipo `vboxnet0` si no existe.
3. Usa una red compatible con:

```text
IPv4 Address: 192.168.56.1
IPv4 Mask:    255.255.255.0
DHCP:         opcional, preferible desactivado para esta demo
```

En la VM:

1. `Adapter 1`: `NAT`.
2. `Adapter 2`: `Host-only Adapter`.
3. Selecciona la red host-only, normalmente `vboxnet0`.
4. Arranca la VM.

## Configuracion de IP en DietPi

Entra en la VM por consola y abre el configurador:

```bash
sudo dietpi-config
```

Ruta recomendada:

```text
Network Options: Adapters
```

Configura las interfaces asi:

- Interfaz NAT, normalmente `eth0`: DHCP activado.
- Interfaz host-only, normalmente `eth1`: IP estatica.

Valores para `eth1`:

```text
IP address: 192.168.56.15
Netmask:    255.255.255.0
Gateway:    dejar vacio, o no usar gateway en esta interfaz
DNS:        no necesario en eth1; la salida a internet debe ir por eth0/NAT
```

Aplica cambios y reinicia red o reinicia la VM:

```bash
sudo reboot
```

## Comprobaciones de red

Despues del reinicio, entra de nuevo en la VM y comprueba interfaces:

```bash
ip -brief addr
```

Resultado esperado aproximado:

```text
eth0  UP  10.0.2.x/24
eth1  UP  192.168.56.15/24
```

Comprueba salida a internet desde la VM:

```bash
curl -I https://github.com
```

Comprueba acceso desde el ordenador host:

```bash
ssh dietpi@192.168.56.15
```

Si quieres usar el alias `dena` desde el host, anade esta linea al archivo `hosts` del ordenador host:

```text
192.168.56.15 dena
```

Luego prueba:

```bash
ssh dietpi@dena
```

## Preparacion minima del sistema

Antes del bootstrap conviene actualizar certificados y paquetes base:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl sudo
```

Comprueba que el usuario actual puede usar sudo:

```bash
sudo whoami
```

Debe responder:

```text
root
```

## Checklist antes de ejecutar

Antes del comando final, valida:

```bash
ip -brief addr
curl -I https://github.com
sudo whoami
df -h /
free -h
```

Condiciones esperadas:

- Existe `192.168.56.15/24` en la interfaz host-only.
- La VM tiene internet por NAT.
- `sudo whoami` responde `root`.
- Hay al menos 30 GiB de disco total, idealmente 40 GiB.
- Hay 4 GiB de RAM minimo.

## Comando final preparado

Cuando todo lo anterior este correcto, copia este comando en la VM:

```bash
curl -fsSL https://raw.githubusercontent.com/alvaroogaarcia-git/dena-interop/main/scripts/bootstrap-demo.sh | sudo bash
```

En este punto, deten la preparacion. El siguiente paso ya es pulsar `Enter` para ejecutar el bootstrap que instalara k3s, herramientas, repositorio, manifests, Helm charts, Terraform, APISIX, Keycloak, PostgREST, NiFi, Grafana, Mathesar, Portainer y la SPA.

## Si usas otra IP

Si la IP host-only no es `192.168.56.15`, prepara el comando asi, sustituyendo la IP:

```bash
curl -fsSL https://raw.githubusercontent.com/alvaroogaarcia-git/dena-interop/main/scripts/bootstrap-demo.sh | sudo env DENA_NODE_IP=192.168.56.20 bash
```

Tambien debes usar esa misma IP para abrir las URLs finales y para SSH.

## Errores comunes antes del bootstrap

`La VM no tiene la IP 192.168.56.15`

La interfaz host-only no esta configurada, esta en otra red, o la IP estatica no se aplico. Revisa `dietpi-config` y `ip -brief addr`.

`curl: Could not resolve host`

La VM no tiene DNS o no tiene salida por NAT. Revisa que `eth0` use DHCP y que el adaptador 1 sea NAT.

`ssh: connect to host 192.168.56.15 port 22: No route to host`

El host no esta en la misma red host-only o la VM no tiene la IP esperada.

`Permission denied` al usar sudo

Estas usando un usuario sin permisos. En esta demo se espera el usuario `dietpi` o un usuario con sudo equivalente.
