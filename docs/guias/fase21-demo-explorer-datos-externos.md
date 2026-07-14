# Fase 21 - Explorador demo de datos externos

Esta fase añade una vista navegable en la consola admin para consultar la PostgreSQL `datos_externos` por carpetas funcionales.

## Objetivo

- Mantener la demo actual de expedientes administrativos.
- Añadir un explorador tipo carpetas para otras SQL/tablas creadas desde `codex_unzip`.
- Consultar datos reales de `datos_externos`, no datos incrustados en HTML.
- Reutilizar Keycloak + APISIX para proteger las consultas del navegador.

## Componentes creados

- SQL: `sql/datos-externos/005_demo_explorer.sql`
  - `public.dena_external_folders`
  - `public.dena_external_expedientes`
  - `public.dena_external_notificaciones`
  - `public.dena_external_pagos`
  - `public.dena_external_citas`
  - `public.dena_external_personas`
  - `public.dena_external_semantica`
- Datos extra cliente: `sql/datos-externos/006_citizen_rich_demo.sql`
  - Amplia `CIT-10001` para que la demo cliente tenga varios elementos por carpeta.
- Kubernetes: `k8s-manifests/datos-externos/postgrest.yaml`
  - Deployment `postgrest-datos-externos`
  - Service `postgrest-datos-externos`
- APISIX:
  - Upstream `apisix/upstreams/5-postgrest-datos-externos.json`
  - Route `apisix/routes/dena-external-data.template.json`
  - URL publica protegida: `/dena/external/...`
- Consola admin:
  - Panel lateral `Carpetas demo`
  - Panel central `Explorador datos externos`
  - Filtro por texto, limite, tabla de resultados y detalle JSON.
- Demo cliente:
  - Campo `Identificador ciudadano`.
  - Panel `Mis carpetas`.
  - Panel `Mis datos conectados`.
  - Panel `Requiere mi atención` con avisos prioritarios.
  - Panel `Línea de vida` con actividad consolidada.
  - Carpetas filtradas por ciudadano: expedientes, notificaciones, pagos, citas y datos personales.

## Despliegue

```bash
bash scripts/dena/apply-fase21-demo-explorer.sh
bash scripts/verify-fase21-demo-explorer.sh
```

El script aplica las vistas SQL, crea el secret de PostgREST, despliega el servicio, reaplica APISIX y actualiza la consola admin.

## Acceso

- Consola admin con OIDC/WebAuthn: `http://localhost:30080/dena/admin-console`
- Demo cliente con OIDC/WebAuthn: `http://localhost:30080/`
- Túnel requerido desde el PC operador:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

- La URL directa `http://192.168.56.15:30080/dena/admin-console` sirve para comprobar gateway, pero la consola redirige a `localhost:30080` al iniciar sesión porque Keycloak y WebAuthn están configurados para ese origen.
- Iniciar sesión con un usuario con rol `dena-admin`.
- Usar el bloque `Carpetas demo`:
  - Expedientes
  - Notificaciones
  - Pagos
  - Citas
  - Personas
  - Semántica

En la demo cliente:

- Entrar en `http://localhost:30080/`.
- Usar `testuser / Test1234!`.
- Mantener `CIT-10001` para ver el ciudadano demo con datos enlazados.
- Pulsar `Consultar expedientes`.
- Revisar `Requiere mi atención` y `Línea de vida`.
- Usar `Mis carpetas` para alternar entre expedientes, notificaciones, pagos, citas y datos personales.

`Requiere mi atención` agrega avisos de:

- Expedientes en espera de respuesta.
- Notificaciones pendientes de lectura.
- Pagos pendientes, rechazados o con error.
- Citas próximas o de prioridad alta.

`Línea de vida` mezcla las carpetas ciudadanas y ordena los eventos por fecha para mostrar una historia única del ciudadano.

Los paneles `Requiere mi atención`, `Línea de vida`, `Expedientes` y `Mis datos conectados` se pueden plegar o desplegar desde el botón del encabezado para compactar la vista durante una presentación.

## Comprobación rápida

Con token OIDC valido, las rutas responden en:

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://192.168.56.15:30080/dena/external/dena_external_folders?select=*"
```

Y para expedientes:

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://192.168.56.15:30080/dena/external/dena_external_expedientes?select=*&limit=5"
```

Comprobaciones realizadas tras el despliegue:

- `bash scripts/verify-fase21-demo-explorer.sh` termina sin error.
- `GET /dena/admin-console` devuelve `200`.
- `GET /realms/piloto/protocol/openid-connect/auth` acepta `redirect_uri=http://localhost:30080/dena/admin-console`.
- `POST /dena/admin-files` devuelve expedientes con token valido.
- `GET /dena/external/dena_external_folders` devuelve 6 carpetas.
- `GET /dena/external/dena_external_expedientes` devuelve expedientes desde `datos_externos`.
- En la demo cliente, `CIT-10001` devuelve 6 expedientes, 2 notificaciones, 3 pagos, 2 citas y 1 registro de datos personales.
- Para `CIT-10001`, `Requiere mi atención` muestra la notificación pendiente `NOT-0001`.

## Relacion con NiFi

La carpeta `Expedientes` lee la vista `public.dena_external_expedientes`, construida sobre `dena.dena_expediente` y `dena.dena_business_object`.

El flujo de Fase 20 sigue sincronizando desde `verticales.expedientes.admin_file_nifi` hacia `datos_externos.dena.dena_admin_file_staging`. Cuando NiFi inserta una fila nueva o actualizada, el trigger de staging actualiza `dena_expediente`; al refrescar la carpeta `Expedientes` en la consola admin se ve el cambio.
