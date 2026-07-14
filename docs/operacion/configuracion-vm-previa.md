# Guía paso a paso para replicar la demo en una VM

Esta guía explica cómo preparar una máquina virtual desde cero y ejecutar un único comando para instalar la demo `dena-interop`.

Está escrita para personas sin conocimientos de administración de sistemas. Sigue los pasos en orden y copia los comandos exactamente como aparecen.

## Antes de empezar

Necesitas:

- Un ordenador con VirtualBox instalado.
- Una imagen ISO de DietPi para PC/VirtualBox x86_64.
- Conexión a internet.
- Al menos 40 GiB libres en disco.
- Repositorio GitHub `alvaroogaarcia-git/dena-interop` público.

El último punto es importante. El comando final descarga el instalador desde GitHub sin usuario ni password. Si el repositorio es privado, fallará con un error parecido a:

```text
curl: (22) The requested URL returned error: 404
```

## Que se va a crear

La demo usa una VM con dos tarjetas de red:

- `NAT`: permite que la VM salga a internet para descargar paquetes, imágenes y charts.
- `Host-only`: permite que tu ordenador pueda abrir la demo dentro de la VM.

La IP fija recomendada para la VM es:

```text
192.168.56.15
```

Si usas esa IP, podrás copiar los comandos tal cual. Si usas otra IP, al final tendrás que cambiarla en el comando de instalación.

## Recursos de la VM

Crea la VM con estos valores:

| Opcion | Valor recomendado |
| --- | --- |
| Sistema | Linux 64-bit |
| Distribución | DietPi x86_64 |
| CPU | 2 vCPU mínimo |
| RAM | 8192 MB recomendado, 4096 MB mínimo |
| Disco | 40 GiB recomendado |
| Usuario | `dietpi` |
| Red 1 | NAT |
| Red 2 | Host-only Adapter |

Con 4 GiB de RAM puede funcionar, pero irá más justo. Si tu ordenador lo permite, usa 8 GiB.

## Paso 1: crear la red host-only en VirtualBox

Abre VirtualBox y revisa que exista una red host-only.

1. Abre `Tools`.
2. Entra en `Network`.
3. Abre la pestaña `Host-only Networks`.
4. Crea una red si no existe.
5. Configúrala así:

```text
IPv4 Address: 192.168.56.1
IPv4 Mask:    255.255.255.0
DHCP Server:  desactivado
```

El nombre habitual de esta red es `vboxnet0`.

## Paso 2: crear la máquina virtual

En VirtualBox:

1. Pulsa `New`.
2. Pon un nombre, por ejemplo `dena-demo`.
3. Selecciona tipo `Linux`.
4. Selecciona versión `Debian 64-bit` o `Other Linux 64-bit`.
5. Asigna memoria:

```text
8192 MB
```

6. Asigna CPU:

```text
2 CPU
```

7. Crea un disco virtual nuevo:

```text
40 GiB
```

8. Monta la ISO de DietPi en la unidad óptica de la VM.

## Paso 3: configurar las dos tarjetas de red

Con la VM apagada, abre `Settings` -> `Network`.

Configura `Adapter 1`:

```text
Enable Network Adapter: activado
Attached to: NAT
```

Configura `Adapter 2`:

```text
Enable Network Adapter: activado
Attached to: Host-only Adapter
Name: vboxnet0
```

Guarda los cambios.

## Paso 4: instalar DietPi

Arranca la VM e instala DietPi siguiendo el asistente.

Cuando te pida usuario, usa el usuario normal de DietPi:

```text
dietpi
```

El usuario `dietpi` debe poder usar `sudo`. Esto es lo normal en DietPi.

Cuando termine la instalación, reinicia la VM si el asistente lo pide.

## Paso 5: configurar la IP fija de la VM

Entra en la VM con el usuario `dietpi` y abre el configurador:

```bash
sudo dietpi-config
```

En el menú, entra en:

```text
Network Options: Adapters
```

Configura las interfaces así:

| Interfaz | Uso | Configuración |
| --- | --- | --- |
| `eth0` | Internet por NAT | DHCP activado |
| `eth1` | Acceso desde tu ordenador | IP estática |

En `eth1`, usa estos valores:

```text
IP address: 192.168.56.15
Netmask:    255.255.255.0
Gateway:    vacio
DNS:        vacio
```

Guarda los cambios y reinicia la VM:

```bash
sudo reboot
```

## Paso 6: comprobar que la red está bien

Después del reinicio, entra otra vez en la VM y ejecuta:

```bash
ip -brief addr
```

Debes ver algo parecido a esto:

```text
eth0  UP  10.0.2.x/24
eth1  UP  192.168.56.15/24
```

No pasa nada si los nombres no son exactamente `eth0` y `eth1`, pero debe aparecer la IP:

```text
192.168.56.15
```

Comprueba que la VM tiene internet:

```bash
curl -I https://github.com
```

Debe aparecer una respuesta HTTP. Si ves `Could not resolve host`, la VM no tiene DNS o internet.

Comprueba que puedes usar `sudo`:

```bash
sudo whoami
```

Debe responder:

```text
root
```

Comprueba disco:

```bash
df -h /
```

Debe haber espacio suficiente. Lo recomendado es que el disco total sea de unos 40 GiB.

Comprueba memoria:

```bash
free -h
```

Lo recomendado es ver unos 8 GiB. El mínimo es 4 GiB.

## Paso 7: comprobar acceso desde tu ordenador

Desde tu ordenador, no desde la pantalla de la VM, abre una terminal y prueba:

```bash
ssh dietpi@192.168.56.15
```

Si conecta, la red host-only está bien.

Si no conecta, revisa:

- Que la VM está encendida.
- Que `Adapter 2` está en `Host-only Adapter`.
- Que la IP `192.168.56.15` aparece dentro de la VM con `ip -brief addr`.
- Que tu red host-only de VirtualBox usa `192.168.56.1/24`.

## Paso 8: preparar paquetes basicos

Dentro de la VM, ejecuta:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl sudo
```

Estos paquetes permiten descargar el instalador y ejecutar comandos con permisos de administrador.

## Paso 9: ejecutar el comando que replica la app

Antes de ejecutar este paso, confirma:

- El repositorio GitHub es público.
- La VM tiene internet.
- La IP `192.168.56.15` existe dentro de la VM.
- `sudo whoami` responde `root`.
- Tienes al menos 4 GiB de RAM, idealmente 8 GiB.

Ejecuta este comando dentro de la VM:

```bash
curl -fsSL https://raw.githubusercontent.com/alvaroogaarcia-git/dena-interop/main/scripts/bootstrap-demo.sh | sudo bash
```

El proceso instalará automáticamente:

- k3s.
- kubectl, Helm y Terraform.
- Repositorio `dena-interop`.
- Namespaces de Kubernetes.
- PostgreSQL.
- Keycloak.
- APISIX.
- Grafana, Loki, Tempo y Prometheus.
- PostgREST.
- NiFi.
- Mathesar.
- Portainer.
- SPA ciudadana.
- Consola admin DENA.
- Datos externos DENA.
- Flujos NiFi de sincronización.

La instalación puede tardar bastante. No cierres la VM ni la terminal mientras se ejecuta.

## Si usas otra IP

Si tu VM no usa `192.168.56.15`, cambia el comando final.

Por ejemplo, si la IP es `192.168.56.20`, ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/alvaroogaarcia-git/dena-interop/main/scripts/bootstrap-demo.sh | sudo env DENA_NODE_IP=192.168.56.20 bash
```

Usa siempre la misma IP para SSH y para abrir las URLs de la demo.

## Resultado esperado

Al terminar, el instalador mostrará un resumen con las URLs principales.

Desde tu ordenador podrás abrir:

```text
http://192.168.56.15:30080/
http://192.168.56.15:31803/login
http://192.168.56.15:30900
https://192.168.56.15:30779
```

Para los flujos con login OIDC y passkey, usa un túnel SSH y abre la app como `localhost`:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

Luego abre:

```text
http://localhost:30080/
http://localhost:30080/dena/admin-console
```

## Comprobar que todo está funcionando

Dentro de la VM:

```bash
cd /home/dietpi/dena-interop
bash scripts/verify-stack.sh
```

También puedes ver el estado general con:

```bash
kubectl get nodes -o wide
kubectl get pods -A
helm list -A
```

## Errores comunes

### `curl: (22) The requested URL returned error: 404`

El repositorio probablemente no es público, la URL está mal escrita o la rama `main` no existe.

Comprueba que este enlace abre en un navegador sin iniciar sesión en GitHub:

```text
https://raw.githubusercontent.com/alvaroogaarcia-git/dena-interop/main/scripts/bootstrap-demo.sh
```

### `curl: Could not resolve host`

La VM no tiene internet o no tiene DNS.

Revisa que:

- `Adapter 1` está en `NAT`.
- Dentro de DietPi, la interfaz de NAT usa DHCP.
- `curl -I https://github.com` funciona.

### `La VM no tiene la IP 192.168.56.15`

La interfaz host-only no está bien configurada.

Revisa:

- `Adapter 2` está en `Host-only Adapter`.
- La red host-only de VirtualBox usa `192.168.56.1/24`.
- En DietPi, la interfaz host-only tiene IP estática `192.168.56.15`.

Si quieres usar otra IP, ejecuta el comando final con `DENA_NODE_IP=<tu-ip>`.

### `Permission denied` al usar `sudo`

El usuario no tiene permisos de administrador.

Usa el usuario `dietpi` o un usuario que pueda ejecutar:

```bash
sudo whoami
```

La respuesta debe ser:

```text
root
```

### `ssh: connect to host 192.168.56.15 port 22: No route to host`

Tu ordenador no puede llegar a la red host-only de la VM.

Revisa:

- La VM está encendida.
- `Adapter 2` está activado.
- La VM tiene la IP `192.168.56.15`.
- VirtualBox tiene la red host-only `192.168.56.1/24`.

### La instalación se queda sin memoria o va muy lenta

Apaga la VM, sube la RAM a 8192 MB y vuelve a intentarlo.

### El bootstrap dice que el repo tiene cambios locales

El instalador detecto cambios en `/home/dietpi/dena-interop`.

Para una replica limpia, usa una VM nueva. Si estás reintentando sobre la misma VM, revisa primero que no necesites conservar esos cambios.
