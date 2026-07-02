# Estado Fases 0-13

Fecha: 2026-06-24

## Resumen

El alcance consolidado queda validado hasta Fase 13:

- Fases 0-11b: plataforma, seguridad, gateway, observabilidad, datalake, NiFi y verticales.
- Extensión 11c: flujo JDBC incremental de NiFi, conservando nombres internos históricos de Fase 12.
- Fase 12: realm, clientes, roles y usuario piloto gestionados por Terraform.
- Fase 13: rutas APISIX, OIDC obligatorio y endpoint DENA funcional.

## Fase 12 - Terraform y Keycloak

Estado validado:

- provider `keycloak/keycloak` 5.8.0 bloqueado en `.terraform.lock.hcl`
- realm `dena`
- cliente público `react-frontend` con PKCE S256
- cliente confidencial `apisix-gateway`
- roles `dena-reader`, `dena-writer` y `dena-admin`
- usuario `testuser` con roles reader y writer
- Secret Kubernetes `gateway/apisix-oidc`
- discovery OIDC operativo
- emisión e introspección de access token comprobadas

Los secretos y el estado Terraform permanecen fuera de Git.

## Fase 13 - APISIX y DENA

Upstreams:

```text
1 -> postgrest.datalake.svc.cluster.local:3000
2 -> keycloak.auth.svc.cluster.local:8080
```

Rutas públicas:

- `/realms/*`
- `/admin/*`
- `/resources/*`

Rutas protegidas mediante `openid-connect` en modo `bearer_only`:

- `GET /api` y `/api/*`
- `POST /dena/admin-files` -> `/rpc/dena_data_retrieve`

La API DENA incluye:

- esquema `dena`
- tabla `dena.admin_file`
- 50 expedientes sincronizados desde `verticales`
- función `public.dena_data_retrieve`
- permisos mínimos para el rol PostgREST `anon`

## Verificación reproducible

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config

bash scripts/dena/apply-fase12-keycloak.sh
bash scripts/verify-fase12-keycloak.sh
bash scripts/dena/apply-dena-api.sh
bash scripts/dena/apply-route.sh
bash scripts/verify-fase13.sh
```

La validación final confirma:

- `401` al acceder a `/api` sin token
- token válido para `testuser`
- OpenAPI de PostgREST accesible con token
- `POST /dena/admin-files` devuelve expedientes reales
- todos los workloads del clúster en `Running/Ready`
