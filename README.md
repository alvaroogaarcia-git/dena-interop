# dena-interop

Stack local de interoperabilidad desplegado sobre un nodo único DietPi x86_64 con k3s, Helm y configuración como código.

## Estado actual

El entorno está validado hasta Fase 18 de la guía de instalación:

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
| 15 | SQL del datalake, staging y carga local | Validado |
| 16 | Cliente demo SPA servido por APISIX | Validado |
| 17 | Portainer para inspección operativa | Validado |
| 18 | Consola admin DENA para operación funcional | Validado |
| 19 | PostgreSQL aislado para datos externos Markdown DENA | Validado |

## Qué hay desplegado

- Namespace `auth`
  - PostgreSQL `17.1.0` mediante chart `postgresql-16.2.1`.
  - Keycloak `26.0` conectado a PostgreSQL.
  - Realm `piloto`, clientes `react-frontend` y `apisix-gateway`, roles y `testuser` gestionados por Terraform.
- Namespace `gateway`
  - APISIX `3.16.0` mediante chart `apisix-2.14.1`.
  - etcd embebido del chart APISIX.
  - Gateway HTTP publicado en `NodePort 30080`.
  - Keycloak publicado en `/realms/*`, `/admin/*` y `/resources/*`.
  - PostgREST publicado con OIDC obligatorio en `/api`.
  - Interoperabilidad DENA publicada en `POST /dena/admin-files`.
- Namespace `app`
  - SPA cliente demo `dena-interop-spa` servida por NGINX.
  - Consola admin `dena-admin-console` servida por NGINX.
  - APISIX enruta `/*` como fallback hacia la SPA.
  - APISIX enruta `/dena/admin-console` hacia la consola admin.
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
  - Staging `dena.admin_file_staging` y promocion `dena.dena_staging_to_main()` validadas.
- Apache NiFi
  - Deployment `nifi` en `datalake`.
  - HTTPS en `NodePort 30821`.
  - Acceso validado por `kubectl port-forward`.
- Namespace `verticales`
  - PostgreSQL origen `17.1.0` mediante chart `postgresql-18.7.5`.
  - Base `expedientes` con tabla `expedientes.admin_file`.
  - Mathesar `0.11.0` publicado en `NodePort 30900`.
- Namespace `portainer`
  - Portainer CE `2.39.3` publicado en HTTPS `NodePort 30779`.
- Namespace `datos-externos`
  - PostgreSQL independiente preparado mediante chart Bitnami.
  - Base `datos_externos` para el modelo semantico DENA derivado de Markdown.
  - Seed demo con 50 expedientes, notificaciones, pagos, citas, personas y trazas REST.
  - Sin exposicion externa, APISIX, Ingress ni NodePort.
- El alcance definido hasta Fase 19 está completado.

## Accesos Demo

| Uso | URL | Credenciales |
| --- | --- | --- |
| Portal ciudadano con login OIDC | `http://localhost:30080/` via tunel SSH | `testuser` / `Test1234!` |
| Consola admin DENA con passkey | `http://localhost:30080/dena/admin-console` via tunel SSH | `adminuser` / `Admin1234!` + passkey |
| Recuperacion de passkey Keycloak | `http://localhost:30080/admin/piloto/console/` via tunel SSH | `recovery-operator` / password local en `.local/fase12-keycloak.env` |
| Grafana | `http://192.168.56.15:31803/login` | `admin` / secret `monitoring/grafana-admin` |
| Mathesar | `http://192.168.56.15:30900` | Usuario creado en la UI |
| Portainer | `https://192.168.56.15:30779` | `admin` / password local de Portainer |
| NiFi | `https://192.168.56.15:30821/nifi/` | secret `datalake/nifi-secret` |

La consola admin está pensada para personal interno. Permite revisar expedientes con filtros, KPIs, detalle, trazabilidad origen -> NiFi -> datalake -> API, salud básica del stack, auditoría de consulta y exportación CSV/JSON.

Para los flujos web con OIDC y passkey, abrir primero un tunel local desde el PC operador:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

WebAuthn/passkey requiere origen seguro. En esta demo HTTP se usa `localhost:30080`; no usar la IP directa para la consola admin con passkey.

## Recuperacion De Passkey

Si `adminuser` pierde la passkey, entrar en Keycloak con `recovery-operator` y seguir la guia operativa:

```bash
grep '^TF_VAR_recovery_operator_password=' .local/fase12-keycloak.env
```

La guia documenta como revocar la credencial WebAuthn perdida, emitir una password temporal, forzar el reenrolado y generar/consumir backup codes:

```bash
bash scripts/dena/generate-recovery-backup-codes.sh
export DENA_RECOVERY_CODE='XXXX-XXXX-XXXX-XXXX'
bash scripts/dena/use-recovery-backup-code.sh
```

Referencia completa: [Recuperacion de passkey en Keycloak](docs/operacion/recuperacion-passkey-keycloak.md).

## Verificación rápida

Desde la máquina de operador:

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
bash scripts/verify-fase15-nifi.sh         # flujo NiFi incremental consolidado
bash scripts/verify-fase12-keycloak.sh     # Fase 12 del plan consolidado
bash scripts/verify-fase13.sh
bash scripts/verify-fase14.sh
bash scripts/verify-fase15.sh
bash scripts/dena/test-curl.sh
bash scripts/verify-fase19-datos-externos.sh
bash scripts/verify-stack.sh
```

Resultado esperado del gateway desde Fase 13:

```text
HTTP/1.1 401 Unauthorized
Server: APISIX/3.16.0
```

La ruta `/api` exige un bearer token válido del realm `piloto`. `scripts/verify-fase13.sh` comprueba el rechazo sin token, obtiene un token de `testuser` y valida `/api` y `/dena/admin-files`.

Resultado esperado de `scripts/verify-fase10.sh`:

- `postgresql-datalake` y `postgrest` en `Running`.
- `postgrest-secret` apunta a `postgresql-datalake.datalake.svc.cluster.local`.
- Roles `anon` y `postgrest` existen y `postgrest` puede asumir `anon`.
- `GET /` sobre el servicio `postgrest` devuelve `HTTP/1.1 200 OK` con el documento OpenAPI.
- `nifi` responde `HTTP/1.1 200 OK` por HTTPS interno con `Host: localhost:8443`.
- `mathesar` queda escuchando en `:8000` y accesible mediante el servicio `mathesar`.

## Documentación principal

- [Índice de documentación](docs/README.md)
- [Demo rápida en VM nueva](docs/demo/demo-vm.md)
- [Guía completa de instalación](docs/guias/guia-instalacion.md)
- [GitHub Actions](docs/operacion/github-actions.md)
- [Histórico de estados validados por fase](docs/estado-fases/README.md)
- [Fase 15 - SQL del datalake y carga local](docs/guias/fase15-datalake.md)
- [Fase 19 - PostgreSQL datos externos desde Markdown DENA](docs/guias/fase19-datos-externos.md)
- [Acceso a datos-externos / datos_externos](docs/acceso-bd/datos-externos-dena.md)
- [Flujo NiFi JDBC incremental actual, Fase 15](docs/guias/fase12-nifi-jdbc.md)
- [Consola admin DENA](docs/herramientas/consola-admin-dena.md)
- [Recuperacion de passkey en Keycloak](docs/operacion/recuperacion-passkey-keycloak.md)
- [Runbook operativo](docs/operacion/runbook.md)
- [Arquitectura](docs/arquitectura/arquitectura.md)
- [Documentación de herramientas](docs/herramientas/README.md)

## Estructura

```text
docs/           Documentación organizada por guías, demo, operación, arquitectura y referencia
helm-values/    Values Helm versionados
k8s-manifests/  Manifiestos Kubernetes versionados
scripts/        Provisionamiento y verificaciones reproducibles
sql/            SQL de verticales y API DENA
terraform/      Realm, clientes, roles y usuario piloto de Keycloak
```

## Secretos

Los secretos locales no se versionan. El archivo `.local/fase4-6.env` queda ignorado por Git y debe generarse en cada entorno.

Nunca guardes tokens de GitHub, passwords o kubeconfigs privados dentro del repositorio.
