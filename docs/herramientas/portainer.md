# Portainer

## Que Es

Portainer es una consola web para inspeccionar y operar entornos de contenedores. En este piloto se usa para ver Kubernetes sin depender siempre de la linea de comandos.

## Objetivo En Este Piloto

Portainer sirve como consola operativa de apoyo:

- Ver namespaces.
- Ver workloads.
- Ver pods, services y volumes.
- Consultar estado del cluster.
- Tener una vista rapida para demos o diagnostico.

No sustituye a Git, Helm, Terraform ni kubectl. La fuente de verdad sigue siendo el repositorio.

## Donde Esta

- Namespace: `portainer`
- Deployment: `portainer`
- Service NodePort:
  - HTTPS: `30779`
  - HTTP: `30777`
- URL: `https://192.168.56.15:30779`

## Como Se Usa

Abrir:

```text
https://192.168.56.15:30779
```

Login demo:

- Usuario: `admin`
- Password: `T]8zJMh3U:ADu@L`

Despues de entrar:

1. Ir a `Environments`.
2. Abrir `local`.
3. Entrar en la seccion Kubernetes.
4. Revisar namespaces, applications, pods, services, config maps, secrets o volumes.

## Que Contiene En Este Caso

Environment:

- Nombre: `local`
- Tipo: Kubernetes
- URL interna: `https://kubernetes.default.svc`
- Permisos: ServiceAccount `portainer` con `cluster-admin`

Recursos visibles:

- Namespaces del piloto.
- Deployments y StatefulSets.
- Services y PVCs.
- Pods y eventos.

## Como Verificarlo

```bash
bash scripts/dena/init-portainer.sh
```

Salida esperada:

```text
Environment Kubernetes local ya existe en Portainer (id=1).
Portainer ve el cluster: namespaces=11 deployments=16.
```

## Por Que Se Usa

Porque facilita inspeccionar el cluster visualmente, especialmente para personas que no trabajan a diario con `kubectl`.

## Riesgo

La cuenta de Portainer tiene acceso `cluster-admin`. Es aceptable para piloto, pero en produccion debe limitarse o retirarse.
