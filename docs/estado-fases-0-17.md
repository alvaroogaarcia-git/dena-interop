# Estado Fases 0-17

Fecha: 2026-07-02

## Resumen

El alcance consolidado queda versionado y validado hasta Fase 17:

- Fases 0-15: plataforma base, identidad, gateway, observabilidad, datalake, NiFi, verticales, API DENA y SQL reproducible.
- Fase 16: cliente demo SPA servido por APISIX en `/`.
- Fase 17: Portainer desplegado e inicializado para inspeccion operativa.
- Operacion: scripts de espera, verificacion integral y apagado controlado.

## Fase 16 - Cliente demo SPA

Estado versionado:

- `k8s-manifests/dena-interop-spa.yaml`: ConfigMap HTML, Deployment NGINX y Service interno.
- `apisix/upstreams/3-dena-interop-spa.json`: upstream APISIX de la SPA.
- `apisix/routes/dena-interop-spa.json`: fallback `/*` con prioridad `-100`.
- `scripts/dena/apply-route.sh`: aplica upstream/ruta de la SPA junto con el resto de rutas.
- `scripts/dena/test-curl.sh`: prueba discovery, token, API, RPC y SPA.

## Fase 17 - Portainer

Estado versionado:

- `k8s-manifests/portainer-deployment.yaml`: namespace, ServiceAccount, ClusterRoleBinding, PVC, Deployment y Service NodePort.
- `scripts/dena/init-portainer.sh`: inicializa `admin / T]8zJMh3U:ADu@L` de forma idempotente.

Acceso:

```text
https://192.168.56.15:30779
```

## Terraform

El realm operativo es `piloto`.

Se importaron al estado local:

- `keycloak_realm.piloto`
- clientes `piloto_react_frontend` y `piloto_apisix_gateway`
- roles `piloto_reader`, `piloto_writer`, `piloto_admin`
- usuario y role mapping de `piloto_testuser`

`terraform plan -detailed-exitcode` termina sin cambios.

## Verificacion

```bash
bash scripts/wait-ready.sh
bash scripts/verify-stack.sh
```

Resultado validado:

- todos los pods principales `Running`
- `/` devuelve `200`
- `/api/` sin token devuelve `401`
- `/api/` con token devuelve `200`
- `POST /dena/admin-files` devuelve `200`
- Portainer devuelve `200` por HTTPS
- `verify-stack.sh` finaliza con `Stack validado`
