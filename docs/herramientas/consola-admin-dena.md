# Consola Admin DENA

## Qué Es

La consola admin DENA es una página web demo para personal interno. Complementa el portal ciudadano con una vista operativa sobre los expedientes sincronizados en el datalake.

## Objetivo En Este Piloto

Demuestra la parte administrativa del flujo:

1. Un usuario interno inicia sesión en Keycloak mediante Authorization Code + PKCE.
2. Keycloak exige WebAuthn al usuario admin que tiene passkey registrada.
3. La consola obtiene un token OIDC del realm `piloto`.
4. La consola llama a `POST /dena/admin-files` mediante APISIX.
5. APISIX valida el token.
6. PostgREST ejecuta la RPC `dena_data_retrieve`.
7. La consola muestra KPIs, resultados, trazabilidad, estado operativo y auditoría de la consulta.

## Dónde Está

- Namespace: `app`
- Deployment: `dena-admin-console`
- Service interno: `dena-admin-console`
- URL demo MFA por túnel: `http://localhost:30080/dena/admin-console`
- Manifiesto: `k8s-manifests/dena-admin-console.yaml`
- Ruta APISIX: `apisix/routes/dena-admin-console.json`
- Upstream APISIX: `apisix/upstreams/4-dena-admin-console.json`

## Cómo Se Usa

Abrir:

```text
http://localhost:30080/dena/admin-console
```

Antes de abrirla desde el PC operador, crear el túnel:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

El usuario demo es:

- Usuario: `adminuser`

El usuario `adminuser` se gestiona en Terraform y tiene el rol `dena-admin`. El rol `dena-admin` es compuesto e incluye `dena-reader` y `dena-writer`.

Si pierde la passkey, se usa el operador limitado `recovery-operator` en la consola Keycloak del realm `piloto`. El procedimiento completo está en [recuperacion-passkey-keycloak.md](../operacion/recuperacion-passkey-keycloak.md).

## Qué Contiene En Este Caso

La consola contiene:

- Login OIDC contra Keycloak con Authorization Code + PKCE.
- MFA WebAuthn/FIDO2 para el usuario admin enrolado.
- Recuperación operativa mediante `recovery-operator` para generar una password temporal y forzar una nueva passkey.
- Recuperación mediante backup codes de un solo uso y registro persistente de cada recuperación.
- Botón `Cerrar sesión`, que limpia sesión local y llama al logout OIDC de Keycloak.
- Filtros por estado, expediente, título y límite.
- KPIs de expedientes, importe total, incidencias y última ingesta.
- Tabla operativa de expedientes.
- Detalle del expediente seleccionado.
- Botón `Abrir ficha 360` para abrir una pestaña dedicada por ciudadano, por ejemplo `CIT-10001`.
- Ficha 360 con identidad, expedientes, notificaciones, pagos, citas y alertas funcionales agrupadas por `persona_id`.
- Render multiidioma de datos funcionales mediante campos `LanguageTexts`, por ejemplo `titulo_by_language`, `servicio_by_language`, `procedimiento_by_language` y `unidad_by_language`.
- Trazabilidad funcional: origen vertical, NiFi, datalake y API protegida.
- Panel `Validación semántica DENA`, que revisa calidad de datos frente a reglas básicas del contrato oficial:
  - `LanguageTexts` presente y con claves `SPANISH` y `BASQUE`.
  - `ENGLISH` recomendado para la demo trilingüe.
  - Fechas parseables.
  - Importes numéricos.
  - `detalle` como JSON estructurado.
  - `raw_payload.urls` como array cuando exista.
- Panel `Estado operativo` con revisión manual y automática de Keycloak, APISIX, API DENA, datos externos y sesión.
- Auditoría de la última consulta: usuario, endpoint, filtros, filas y duración.
- Exportación CSV y JSON de los resultados visibles.
- Accesos operativos a NiFi, Grafana, Mathesar y Portainer sin mezclar esas herramientas con la tabla principal.

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

Además, el explorador de `datos_externos` consume las vistas públicas definidas en `sql/datos-externos/005_demo_explorer.sql`. Estas vistas mantienen campos planos para listar rápido (`titulo`, `estado`, `servicio`) y campos multiidioma alineados con DENA (`*_by_language`) para que la consola pinte el contenido según el idioma activo.

## Cómo Verificarlo

```bash
kubectl rollout status deployment/dena-admin-console -n app
curl -H 'Host: localhost:30080' -i http://192.168.56.15:30080/dena/admin-console
```

Comprobación específica de la validación semántica:

```bash
kubectl exec -n app deploy/dena-admin-console -- \
  wget -qO- http://127.0.0.1 | rg 'semanticPanel|renderSemanticValidation'
```

Comprobación específica de `LanguageTexts` en datos externos:

```bash
PGPASSWORD="$(kubectl get secret -n datos-externos datos-externos-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -i -n datos-externos datos-externos-postgresql-0 -- \
  env PGPASSWORD="$PGPASSWORD" \
  psql -U postgres -d datos_externos -Atc \
  "select titulo_by_language::text from public.dena_external_expedientes limit 1;"
```

Validación esperada:

```text
La consola contiene code_challenge y grant_type=authorization_code.
El password grant de react-frontend devuelve unauthorized_client.
```

## Por Qué Se Usa

Porque separa claramente dos audiencias:

- Portal ciudadano: consulta simple de expedientes.
- Consola admin: operación interna, trazabilidad, revisión y auditoría.

Esta separación evita cargar al ciudadano con información técnica y permite enseñar la gobernanza del dato desde una vista específica para administración.
