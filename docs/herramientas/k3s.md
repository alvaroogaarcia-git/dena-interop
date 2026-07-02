# k3s

## Que Es

k3s es una distribucion ligera de Kubernetes. Kubernetes es el sistema que ejecuta contenedores, los reinicia si fallan, les da red interna, publica servicios y organiza los componentes por namespaces.

k3s mantiene la experiencia de Kubernetes, pero con menos consumo y menos piezas. Por eso encaja en este piloto de un solo servidor.

## Objetivo En Este Piloto

En `dena-interop`, k3s es la base donde corre todo:

- Keycloak y su PostgreSQL.
- APISIX y etcd.
- PostgreSQL del datalake.
- PostgREST.
- NiFi.
- PostgreSQL de verticales.
- Mathesar.
- Grafana, Prometheus, Loki, Tempo y OTel Collector.
- Portainer.
- SPA cliente demo.

## Donde Esta

- Servidor: `192.168.56.15`
- Nodo: `dietpi`
- Tipo: single-node control-plane
- API server: `https://192.168.56.15:6443`
- Kubeconfig local: `~/.kube/dena-config`

## Como Se Usa

Normalmente no se opera k3s directamente por SSH. Se opera desde la maquina de operador con `kubectl` y `helm`.

Comandos utiles:

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc -A
```

## Que Contiene

k3s contiene namespaces separados:

- `auth`: identidad.
- `gateway`: APISIX.
- `datalake`: datos consolidados y NiFi.
- `verticales`: origen editable.
- `monitoring`: observabilidad.
- `app`: SPA cliente demo.
- `portainer`: consola Portainer.
- `kube-system`: componentes internos de Kubernetes.

## Como Verificarlo

```bash
kubectl get nodes
kubectl get pods -A
bash scripts/wait-ready.sh
```

Resultado esperado:

- Nodo `dietpi` en `Ready`.
- Pods principales en `Running`.

## Por Que Se Usa

Porque permite aislar servicios, reiniciarlos automaticamente, exponer solo lo necesario y reproducir la plataforma desde manifiestos, Helm charts y Terraform.
