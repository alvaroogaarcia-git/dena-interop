# Portainer

## Qué Es

Portainer es una consola web para inspeccionar y operar entornos de contenedores. En este piloto se usa para ver Kubernetes sin depender siempre de la línea de comandos.

## Objetivo En Este Piloto

Portainer sirve como consola operativa de apoyo:

- Ver namespaces.
- Ver workloads.
- Ver pods, services y volumes.
- Consultar estado del clúster.
- Tener una vista rápida para demos o diagnóstico.

No sustituye a Git, Helm, Terraform ni kubectl. La fuente de verdad sigue siendo el repositorio.

## Dónde Está

- Namespace: `portainer`
- Deployment: `portainer`
- Service NodePort:
  - HTTPS: `30779`
  - HTTP: `30777`
- URL: `https://192.168.56.15:30779`

## Cómo Se Usa

Abrir:

```text
https://192.168.56.15:30779
```

Login demo:

- Usuario: `admin`
- Password: `T]8zJMh3U:ADu@L`

Después de entrar:

1. Ir a `Environments`.
2. Abrir `local`.
3. Entrar en la sección Kubernetes.
4. Revisar namespaces, applications, pods, services, config maps, secrets o volumes.

## Qué Contiene En Este Caso

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

## Cómo Verificarlo

```bash
bash scripts/dena/init-portainer.sh
```

Salida esperada:

```text
Environment Kubernetes local ya existe en Portainer (id=1).
Portainer ve el cluster: namespaces=11 deployments=16.
```

## Por Qué Se Usa

Porque facilita inspeccionar el clúster visualmente, especialmente para personas que no trabajan a diario con `kubectl`.

## Riesgo

La cuenta de Portainer tiene acceso `cluster-admin`. Es aceptable para piloto, pero en producción debe limitarse o retirarse.
