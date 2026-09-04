# DENA Interop — Infraestructura de Interoperabilidad para Carpeta Ciudadana

> ⚠️ **Nota / Descargo de responsabilidad (Disclaimer)**
> 
> Este proyecto ha sido desarrollado como una **Prueba de Concepto (PoC)** y base de infraestructura durante un periodo de prácticas de empresa (estudiante de 3.º del Grado en Ingeniería Informática, con una duración aproximada de 1,5 meses).
> 
> El objetivo principal del repositorio es servir como prototipo inicial y punto de partida funcional para la integración con DENA Interop. Por ello:
> - **Entorno de producción:** Requiere auditoría de seguridad, refactorización y adaptación a estándares de producción antes de su despliegue real.
> - **Contribuciones:** La comunidad y los colaboradores son bienvenid@s a revisar, corregir, ampliar o reestructurar el código existente.

## 📌 Introducción y Objetivo del Proyecto

El proyecto **DENA Interop** nace con el objetivo de proporcionar la **base técnica e infraestructura de integración** necesaria para conectar las aplicaciones y sistemas de las administraciones públicas con **DENA Interop**, la plataforma de **Carpeta Ciudadana del Gobierno Vasco**.

La iniciativa **DENA** busca unificar y simplificar la relación entre la ciudadanía y las distintas administraciones de la Comunidad Autónoma del País Vasco. A través de su Carpeta Ciudadana, las personas pueden consultar de manera centralizada sus datos, expedientes, certificados, notificaciones y trámites administrativos.

### 🎯 Propósito de esta solución

Para que la Carpeta Ciudadana funcione de forma eficaz, las administraciones emisoras de información deben exponer sus datos garantizando altos estándares de disponibilidad, seguridad e interoperabilidad. 

Este repositorio desarrolla un componente base de infraestructura que actúa como **módulo de enlace / middleware**, simplificando:

- **La integración de datos:** Estandarización de las respuestas y modelos de datos requeridos por las especificaciones de DENA Interop.
- **La comunicación segura:** Facilitar el intercambio de información entre los sistemas origen de las administraciones públicas y el bus de interoperabilidad del Gobierno Vasco.
- **La escalabilidad:** Ofrecer una arquitectura reutilizable que reduzca la complejidad técnica y el tiempo de despliegue para los organismos que necesiten compartir información con la plataforma.

## 🏗️ Arquitectura y Flujo de Datos

El módulo actúa como una capa intermedia entre los sistemas backend de la entidad emisora (Base de datos / ERP municipal) y el nodo de interoperabilidad de DENA.
+------------------------+      +----------------------------+      +--------------------------+
|  Sistema Origen / ERP  | ---> |   dena-interop (Middleware)| ---> |   Plataforma DENA        |
|  (Entidad Emisora)     | <--- |   - Mapeo de esquema       | <--- |   (Carpeta Ciudadana EJ) |
+------------------------+      |   - Autenticación/Firma    |      +--------------------------+
                                |   - Trazabilidad y Logs    |
                                +----------------------------+


### Principales Funcionalidades del Middleware:
1. **Transformación y Mapeo:** Modela los datos de los expedientes/trámites locales al estándar JSON/XML requerido por las especificaciones de DENA Interop.
2. **Seguridad y Cifrado:** Gestiona la autenticación de la entidad emisora mediante certificados digitales / tokens OAuth2 según los criterios de seguridad del Gobierno Vasco.
3. **Auditoría y Trazabilidad:** Garantiza el registro de peticiones para dar cumplimiento a los requerimientos de auditoría en la transmisión de datos ciudadanos.

* ---
Stack local de interoperabilidad desplegado sobre un nodo único DietPi x86_64 con k3s, Helm y configuración como código.

## Estado actual

El entorno está validado hasta Fase 21 de la guía de instalación:

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
| 20 | NiFi incremental hacia datos externos DENA | Validado |
| 21 | Explorador demo de datos externos en consola admin y SPA | Validado |

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
  - SPA y consola consultan las rutas protegidas de datos externos bajo `/dena/external`.
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
  - Staging `dena.admin_file_staging` y promoción `dena.dena_staging_to_main()` validadas.
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
  - Base `datos_externos` para el modelo semántico DENA derivado de Markdown.
  - Seed demo actual con 55 expedientes, 31 notificaciones, 27 pagos, 11 citas, 20 fichas de persona y 50 trazas REST.
  - Sincronización incremental desde `verticales` mediante NiFi.
  - PostgREST interno `postgrest-datos-externos` publicado por APISIX solo en rutas OIDC `/dena/external/*`.
- El alcance definido hasta Fase 21 está completado.

## Accesos Demo

| Uso | URL | Credenciales |
| --- | --- | --- |
| Portal ciudadano con login OIDC | `http://localhost:30080/` vía túnel SSH | `testuser` / `Test1234!` |
| Consola admin DENA con passkey | `http://localhost:30080/dena/admin-console` vía túnel SSH | `adminuser` / `Admin1234!` + passkey |
| Recuperación de passkey Keycloak | `http://localhost:30080/admin/piloto/console/` vía túnel SSH | `recovery-operator` / password local en `.local/fase12-keycloak.env` |
| Grafana | `http://192.168.56.15:31803/login` | `admin` / secret `monitoring/grafana-admin` |
| Mathesar | `http://192.168.56.15:30900` o port-forward `http://127.0.0.1:18000` | `admin` / `Mathesar1234!` |
| Portainer | `https://192.168.56.15:30779` | `admin` / `T]8zJMh3U:ADu@L` |
| NiFi | `https://192.168.56.15:30821/nifi/` | secret `datalake/nifi-secret` |

La consola admin está pensada para personal interno. Permite revisar expedientes con filtros, KPIs, detalle, trazabilidad origen -> NiFi -> datalake -> API, salud básica del stack, auditoría de consulta y exportación CSV/JSON.

Para los flujos web con OIDC y passkey, abrir primero un túnel local desde el PC operador:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

WebAuthn/passkey requiere origen seguro. En esta demo HTTP se usa `localhost:30080`; no usar la IP directa para la consola admin con passkey.

## Recuperación De Passkey

Si `adminuser` pierde la passkey, entrar en Keycloak con `recovery-operator` y seguir la guía operativa:

```bash
grep '^TF_VAR_recovery_operator_password=' .local/fase12-keycloak.env
```

La guía documenta cómo revocar la credencial WebAuthn perdida, emitir una password temporal, forzar el reenrolado y generar/consumir backup codes:

```bash
bash scripts/dena/generate-recovery-backup-codes.sh
export DENA_RECOVERY_CODE='XXXX-XXXX-XXXX-XXXX'
bash scripts/dena/use-recovery-backup-code.sh
```

Referencia completa: [Recuperación de passkey en Keycloak](docs/operacion/recuperacion-passkey-keycloak.md).

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
bash scripts/verify-fase20-datos-externos-nifi.sh
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
- [Fase 20 - NiFi hacia datos externos DENA](docs/guias/fase20-nifi-datos-externos.md)
- [Fase 21 - Explorador demo de datos externos](docs/guias/fase21-demo-explorer-datos-externos.md)
- [Acceso a datos-externos / datos_externos](docs/acceso-bd/datos-externos-dena.md)
- [Flujo NiFi JDBC incremental actual, Fase 15](docs/guias/fase12-nifi-jdbc.md)
- [Consola admin DENA](docs/herramientas/consola-admin-dena.md)
- [Recuperación de passkey en Keycloak](docs/operacion/recuperacion-passkey-keycloak.md)
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
