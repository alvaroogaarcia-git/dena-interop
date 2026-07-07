# Demo rápida en una VM nueva

Esta guía deja una VM DietPi como réplica demo de `dena-interop` con un solo comando. La VM se crea a mano; el bootstrap instala k3s, herramientas, el repositorio y todas las fases validadas.

Si necesitas preparar la VM desde cero antes de ejecutar el comando, usa primero [configuracion-vm-previa.md](../operacion/configuracion-vm-previa.md).

## Requisitos de la VM

- DietPi x86_64 limpio.
- Usuario `dietpi` con sudo.
- 2 vCPU.
- 4 GiB RAM como mínimo.
- 30-40 GiB de disco recomendados.
- Adaptador NAT para acceso a internet.
- Adaptador host-only con IP `192.168.56.15`.

Desde la VM, comprueba la IP:

```bash
ip -brief addr
```

Debe aparecer `192.168.56.15`. Si usas otra IP, ejecuta el bootstrap con `DENA_NODE_IP=<ip>`.

## Instalación

Entra por consola o SSH a la VM y ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/alvaroogaarcia-git/dena-interop/main/scripts/bootstrap-demo.sh | sudo bash
```

El proceso descarga imágenes, charts y binarios. En una VM nueva puede tardar 20-45 minutos según red y equipo.

## URLs finales

Cuando termine, desde el ordenador host abre:

```text
SPA/OIDC:   http://localhost:30080/        # con tunel SSH activo
Grafana:    http://192.168.56.15:31803/login
Mathesar:   http://192.168.56.15:30900
Portainer:  https://192.168.56.15:30779
```

Antes de usar la SPA con login OIDC o la consola admin con passkey, abre el tunel:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

Credenciales demo:

```text
SPA/OIDC:   testuser / Test1234!
Admin DENA: adminuser / Admin1234! + passkey en http://localhost:30080/dena/admin-console
Grafana:    admin / hLgdC1Azsa0V7XUUhF9P8NyQEVSQyDpJ
Portainer:  admin / T]8zJMh3U:ADu@L
```

## SSH desde el host

Siempre puedes entrar con:

```bash
ssh dietpi@192.168.56.15
```

Si quieres usar `dena` como alias desde el host, añade en el archivo `hosts` del ordenador host:

```text
192.168.56.15 dena
```

Después podrás usar:

```bash
ssh dietpi@dena
```

## Reejecución y verificación

El bootstrap es reejecutable en una VM parcialmente instalada, siempre que el repo local no tenga cambios sin guardar.

Para verificar el stack después:

```bash
cd /home/dietpi/dena-interop
bash scripts/demo-status.sh
bash scripts/verify-stack.sh
```

Si necesitas usar otra IP:

```bash
curl -fsSL https://raw.githubusercontent.com/alvaroogaarcia-git/dena-interop/main/scripts/bootstrap-demo.sh \
  | sudo env DENA_NODE_IP=192.168.56.20 bash
```
