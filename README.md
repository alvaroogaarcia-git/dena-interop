# dena-interop

Stack local de interoperabilidad desplegado sobre un nodo unico DietPi x86_64 con k3s, Helm y configuracion como codigo.

## Estado actual

El entorno esta validado hasta Fase 14 de la guia de instalacion:

| Fase | Componente | Estado |
| --- | --- | --- |
| 0 | DietPi preparado para k3s | Validado |
| 1 | k3s sin Traefik ni servicelb | Validado |
| 2 | Tooling local, kubeconfig y repos Helm | Validado |
| 3 | Namespaces base | Validado |
| 4 | PostgreSQL para Keycloak | Desplegado |
| 5 | Keycloak con imagen oficial | Desplegado |
| 6 | APISIX + etcd | Desplegado |
| 7 | Observabilidad local | Validado |
| 8 | OTel Collector | Validado |
| 9 | PostgreSQL del datalake | Validado |
| 10 | PostgREST | Validado |
| 11 | Apache NiFi 2.9 | Validado |
| 11b | Verticales + Mathesar local | Validado |
| 11c | Flujo NiFi JDBC incremental | Validado |
| 12 | Terraform: realm, clientes, roles y testuser en Keycloak | Validado |
| 13 | APISIX: OIDC, rutas Keycloak y API DENA | Validado |
| 14 | Terraform: datasources y dashboards de Grafana | Validado |

## Que hay desplegado

- Namespace `auth`
  - PostgreSQL `17.1.0` mediante chart `postgresql-16.2.1`.
  - Keycloak `26.0` conectado a PostgreSQL.
  - Realm `dena`, clientes `react-frontend` y `apisix-gateway`, roles y `testuser` gestionados por Terraform.
- Namespace `gateway`
  - APISIX `3.16.0` mediante chart `apisix-2.14.1`.
  - etcd embebido del chart APISIX.
  - Gateway HTTP publicado en `NodePort 30080`.
  - Keycloak publicado en `/realms/*`, `/admin/*` y `/resources/*`.
  - PostgREST publicado con OIDC obligatorio en `/api`.
  - Interoperabilidad DENA publicada en `POST /dena/admin-files`.
- Namespace `monitoring`
  - Prometheus Operator mediante `kube-prometheus-stack`.
  - Grafana publicado en `NodePort 31803`.
  - Datasources, carpeta `DENA` y dashboards gestionados por Terraform.
  - Loki `3.6.7` en modo SingleBinary.
  - Tempo `2.9.0` con OTLP `4317/4318`.
- OTel Collector
  - Release `otel-collector` en `monitoring`.
  - DaemonSet operativo exportando a Loki y Tempo.
- Namespace `datalake`
  - PostgreSQL `18.4.0` mediante chart `postgresql-18.7.5`.
  - PostgREST `13.0.4` publicado como `ClusterIP` interno en `:3000`.
  - Roles `anon` y `postgrest` validados en la base `datalake`.
  - Esquema `dena`, 50 expedientes sincronizados y RPC `dena_data_retrieve`.
- Apache NiFi
  - Deployment `nifi` en `datalake`.
  - HTTPS en `NodePort 30821`.
  - Acceso validado por `kubectl port-forward`.
- Namespace `verticales`
  - PostgreSQL origen `17.1.0` mediante chart `postgresql-18.7.5`.
  - Base `expedientes` con tabla `expedientes.admin_file`.
  - Mathesar `0.11.0` publicado en `NodePort 30900`.
- El alcance definido hasta Fase 14 esta completado.

## Verificacion rapida

Desde la maquina de operador:

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config

kubectl get nodes -o wide
kubectl get pods,svc,pvc -n auth -o wide
kubectl get pods,svc,pvc -n gateway -o wide
kubectl get pods,svc,pvc -n monitoring -o wide
kubectl get pods,svc,pvc -n datalake -o wide
kubectl get pods,svc,pvc -n verticales -o wide
helm list -A
curl -i http://192.168.56.15:30080/api
curl -i http://192.168.56.15:31803/login
bash scripts/verify-fase10.sh
bash scripts/verify-fase11.sh
bash scripts/verify-fase11b.sh
bash scripts/verify-fase12.sh              # flujo NiFi, nombre legado
bash scripts/verify-fase12-keycloak.sh     # Fase 12 del plan consolidado
bash scripts/verify-fase13.sh
bash scripts/verify-fase14.sh
```

Resultado esperado del gateway desde Fase 13:

```text
HTTP/1.1 401 Unauthorized
Server: APISIX/3.16.0
```

La ruta `/api` exige un bearer token valido del realm `dena`. `scripts/verify-fase13.sh` comprueba el rechazo sin token, obtiene un token de `testuser` y valida `/api` y `/dena/admin-files`.

Resultado esperado de `scripts/verify-fase10.sh`:

- `postgresql-datalake` y `postgrest` en `Running`.
- `postgrest-secret` apunta a `postgresql-datalake.datalake.svc.cluster.local`.
- Roles `anon` y `postgrest` existen y `postgrest` puede asumir `anon`.
- `GET /` sobre el servicio `postgrest` devuelve `HTTP/1.1 200 OK` con el documento OpenAPI.
- `nifi` responde `HTTP/1.1 200 OK` por HTTPS interno con `Host: localhost:8443`.
- `mathesar` queda escuchando en `:8000` y accesible mediante el servicio `mathesar`.

## Documentacion principal

- [Guia completa de instalacion](docs/guia-instalacion.md)
- [GitHub Actions](docs/github-actions.md)
- [Estado validado Fases 0-7](docs/estado-fases-0-7.md)
- [Estado validado Fases 0-10](docs/estado-fases-0-10.md)
- [Estado validado Fases 0-11](docs/estado-fases-0-11.md)
- [Estado validado Fases 0-11b](docs/estado-fases-0-11b.md)
- [Estado validado Fases 0-13](docs/estado-fases-0-13.md)
- [Estado validado Fases 0-14](docs/estado-fases-0-14.md)
- [Fase 15 - SQL del datalake y carga local](docs/fase15-datalake.md)
- [Flujo NiFi JDBC incremental (extension 11c)](docs/fase12-nifi-jdbc.md)
- [Estado validado Fases 0-6](docs/estado-fases-0-6.md)
- [Estado validado Fases 0-3](docs/estado-fases-0-3.md)
- [Preparacion de Fase 8](docs/fase8-preparacion.md)
- [Observabilidad y Grafana](docs/grafana-observabilidad.md)

## Estructura

```text
docs/           Documentacion operativa y estado validado
helm-values/    Values Helm versionados
k8s-manifests/  Manifiestos Kubernetes versionados
scripts/        Provisionamiento y verificaciones reproducibles
sql/            SQL de verticales y API DENA
terraform/      Realm, clientes, roles y usuario piloto de Keycloak
```

## Secretos

Los secretos locales no se versionan. El archivo `.local/fase4-6.env` queda ignorado por Git y debe generarse en cada entorno.

Nunca guardes tokens de GitHub, passwords o kubeconfigs privados dentro del repositorio.
