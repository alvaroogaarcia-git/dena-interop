# Consola Admin DENA

## Qué Es

La consola admin DENA es una página web demo para personal interno. Complementa el portal ciudadano con una vista operativa sobre los expedientes sincronizados en el datalake.

## Objetivo En Este Piloto

Demuestra la parte administrativa del flujo:

1. Un usuario interno se autentica en Keycloak.
2. La consola obtiene un token OIDC del realm `piloto`.
3. La consola llama a `POST /dena/admin-files` mediante APISIX.
4. APISIX valida el token.
5. PostgREST ejecuta la RPC `dena_data_retrieve`.
6. La consola muestra KPIs, resultados, trazabilidad, salud básica y auditoría de la consulta.

## Dónde Está

- Namespace: `app`
- Deployment: `dena-admin-console`
- Service interno: `dena-admin-console`
- URL pública: `http://192.168.56.15:30080/dena/admin-console`
- Manifiesto: `k8s-manifests/dena-admin-console.yaml`
- Ruta APISIX: `apisix/routes/dena-admin-console.json`
- Upstream APISIX: `apisix/upstreams/4-dena-admin-console.json`

## Cómo Se Usa

Abrir:

```text
http://192.168.56.15:30080/dena/admin-console
```

Credenciales demo:

- Usuario: `adminuser`
- Password: `Admin1234!`

El usuario `adminuser` se gestiona en Terraform y tiene el rol `dena-admin`. El rol `dena-admin` es compuesto e incluye `dena-reader` y `dena-writer`.

## Qué Contiene En Este Caso

La consola contiene:

- Login OIDC contra Keycloak.
- Filtros por estado, expediente, título y límite.
- KPIs de expedientes, importe total, incidencias y última ingesta.
- Tabla operativa de expedientes.
- Detalle del expediente seleccionado.
- Trazabilidad funcional: origen vertical, NiFi, datalake y API protegida.
- Salud básica del stack vista desde la sesión web.
- Auditoría de la última consulta: usuario, endpoint, filtros, filas y duración.
- Exportación CSV y JSON de los resultados visibles.

## Datos Que Usa

La consola reutiliza la RPC protegida:

```text
POST /dena/admin-files
```

La función SQL `public.dena_data_retrieve` acepta:

- `p_status`
- `p_updated_since`
- `p_limit`
- `p_code`
- `p_title`
- `p_opened_from`
- `p_opened_to`

También devuelve `ingested_at` para enseñar la diferencia entre la actualización en origen y la ingesta en el datalake.

## Cómo Verificarlo

```bash
kubectl rollout status deployment/dena-admin-console -n app
curl -i http://192.168.56.15:30080/dena/admin-console
bash scripts/dena/test-curl.sh
bash scripts/verify-stack.sh
```

Validación esperada:

```text
OK  Consola admin (200)
6 OK · 0 KO
```

## Por Qué Se Usa

Porque separa claramente dos audiencias:

- Portal ciudadano: consulta simple de expedientes.
- Consola admin: operación interna, trazabilidad, revisión y auditoría.

Esta separación evita cargar al ciudadano con información técnica y permite enseñar la gobernanza del dato desde una vista específica para administración.
