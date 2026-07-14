# Fase 21: explorador demo de datos externos

## Objetivo

Publicar las vistas demo de `datos_externos` por APISIX y añadir navegación funcional en la consola admin y la SPA ciudadana.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/apply-fase21-demo-explorer.sh
bash scripts/verify-fase21-demo-explorer.sh
```

## Que hace cada parte

- `apply-fase21-demo-explorer.sh`: aplica `005_demo_explorer.sql` y `006_citizen_rich_demo.sql`, crea el Secret de PostgREST de datos externos, despliega `postgrest-datos-externos`, reaplica rutas APISIX y actualiza la consola admin.
- `k8s-manifests/datos-externos/postgrest.yaml`: publica PostgREST interno para `datos_externos`.
- `apisix/upstreams/5-postgrest-datos-externos.json` y `apisix/routes/dena-external-data.template.json`: publican `/dena/external/*` con OIDC.
- `verify-fase21-demo-explorer.sh`: valida deployment, service, secret, vistas `dena_external_*` y recuentos de `CIT-10001`.
- `verify-stack.sh`: valida el stack completo, SPA, Portainer, API DENA y rutas OIDC `/dena/external/*`.

## Estado actual verificado

- `postgrest-datos-externos` está `Running` en namespace `datos-externos`.
- APISIX publica `/dena/external/*` protegido por OIDC.
- Las vistas `public.dena_external_*` existen en `datos_externos`.
- Para `CIT-10001`, las vistas ciudadanas devuelven 6 expedientes, 2 notificaciones, 3 pagos, 2 citas y 1 registro de datos personales.

## Referencias

- [Guía Fase 21](../guias/fase21-demo-explorer-datos-externos.md)
- [Acceso a datos-externos](../acceso-bd/datos-externos-dena.md)
