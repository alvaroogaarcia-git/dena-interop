# Fase 13: APISIX OIDC y API DENA

## Objetivo

Publicar rutas de APISIX, proteger `/api` con OIDC y exponer la interoperabilidad DENA en `/dena/admin-files`.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/apply-dena-api.sh
bash scripts/dena/apply-route.sh
bash scripts/verify-fase13.sh
```

## Que hace cada parte

- `apply-dena-api.sh`: aplica SQL y sincronización necesaria para la API DENA.
- `apply-route.sh`: crea upstreams y rutas de APISIX usando la Admin API.
- Las rutas de Keycloak publican `/realms/*`, `/admin/*` y `/resources/*`.
- La ruta `/api` exige token OIDC valido.
- La ruta `/dena/admin-files` expone el endpoint DENA funcional.
- `verify-fase13.sh`: prueba rechazo sin token, login OIDC y llamadas autenticadas.

## Verificación

```bash
curl -i http://192.168.56.15:30080/api
bash scripts/verify-fase13.sh
```

`/api` debe responder `401 Unauthorized` sin token.

## Referencias

- [Histórico 0-13](historico/estado-fases-0-13.md)
- [APISIX](../herramientas/apisix.md)
