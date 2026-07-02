# APISIX

## Qué Es

APISIX es un API Gateway. Recibe peticiones HTTP externas, decide a qué servicio interno enviarlas y puede aplicar plugins como autenticación, reescritura de rutas y métricas.

## Objetivo En Este Piloto

APISIX es la única puerta HTTP externa del flujo DENA:

- Publica Keycloak.
- Protege PostgREST con OIDC.
- Publica la RPC DENA `POST /dena/admin-files`.
- Sirve la SPA cliente demo en `/`.

## Dónde Está

- Namespace: `gateway`
- Deployment: `apisix`
- StatefulSet: `apisix-etcd`
- Gateway público: `http://192.168.56.15:30080`
- Admin API: `svc/apisix-admin:9180`, solo por port-forward.

## Cómo Se Usa

Acceso público:

```bash
curl -i http://192.168.56.15:30080/
```

Admin API:

```bash
kubectl port-forward -n gateway svc/apisix-admin 9180:9180
curl http://localhost:9180/apisix/admin/routes \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1"
```

Aplicar rutas versionadas:

```bash
bash scripts/dena/apply-route.sh
```

## Qué Contiene En Este Caso

Upstreams:

- `1`: PostgREST.
- `2`: Keycloak.
- `3`: SPA cliente DENA.

Rutas:

- `/api` y `/api/*`: PostgREST protegido por OIDC.
- `/realms/*`: Keycloak público.
- `/admin/*`: consola admin Keycloak.
- `/resources/*`: assets de Keycloak.
- `POST /dena/admin-files`: RPC DENA protegida.
- `/*`: fallback a la SPA.

## Cómo Verificarlo

```bash
bash scripts/verify-fase13.sh
bash scripts/dena/test-curl.sh
```

## Por Qué Se Usa

Porque centraliza seguridad y entrada. Las bases de datos y servicios internos no se exponen directamente.
