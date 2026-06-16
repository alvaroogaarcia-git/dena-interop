# dena-interop

Stack local de interoperabilidad desplegado sobre un nodo unico DietPi x86_64 con k3s, Helm y configuracion como codigo.

## Estado actual

El entorno esta validado hasta Fase 6 de la guia de instalacion:

| Fase | Componente | Estado |
| --- | --- | --- |
| 0 | DietPi preparado para k3s | Validado |
| 1 | k3s sin Traefik ni servicelb | Validado |
| 2 | Tooling local, kubeconfig y repos Helm | Validado |
| 3 | Namespaces base | Validado |
| 4 | PostgreSQL para Keycloak | Desplegado |
| 5 | Keycloak con imagen oficial | Desplegado |
| 6 | APISIX + etcd | Desplegado |

## Que hay desplegado

- Namespace `auth`
  - PostgreSQL `17.1.0` mediante chart `postgresql-16.2.1`.
  - Keycloak `26.0` conectado a PostgreSQL.
- Namespace `gateway`
  - APISIX `3.16.0` mediante chart `apisix-2.14.1`.
  - etcd embebido del chart APISIX.
  - Gateway HTTP publicado en `NodePort 30080`.
- Namespaces preparados para fases posteriores:
  - `app`
  - `monitoring`
  - `datalake`
  - `verticales`

## Verificacion rapida

Desde la maquina de operador:

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config

kubectl get nodes -o wide
kubectl get pods,svc,pvc -n auth -o wide
kubectl get pods,svc,pvc -n gateway -o wide
helm list -A
curl -i http://192.168.56.15:30080
```

Resultado esperado del gateway en Fase 6:

```text
HTTP/1.1 404 Not Found
Server: APISIX/3.16.0
{"error_msg":"404 Route Not Found"}
```

Ese `404` es correcto: APISIX esta vivo, pero todavia no hay rutas configuradas.

## Documentacion principal

- [Guia completa de instalacion](docs/guia-instalacion.md)
- [Estado validado Fases 0-6](docs/estado-fases-0-6.md)
- [Estado validado Fases 0-3](docs/estado-fases-0-3.md)

## Estructura

```text
docs/           Documentacion operativa y estado validado
helm-values/    Values Helm versionados
k8s-manifests/  Manifiestos Kubernetes versionados
scripts/        Scripts auxiliares futuros
sql/            SQL de fases posteriores
terraform/      Terraform de fases posteriores
```

## Secretos

Los secretos locales no se versionan. El archivo `.local/fase4-6.env` queda ignorado por Git y debe generarse en cada entorno.

Nunca guardes tokens de GitHub, passwords o kubeconfigs privados dentro del repositorio.

