# APISIX

## Que Es

APISIX es un API Gateway. Recibe peticiones HTTP externas, decide a que servicio interno enviarlas y puede aplicar plugins como autenticacion, reescritura de rutas y metricas.

## Objetivo En Este Piloto

APISIX es la unica puerta HTTP externa del flujo DENA:

- Publica Keycloak.
- Protege PostgREST con OIDC.
- Publica la RPC DENA `POST /dena/admin-files`.
- Sirve la SPA cliente demo en `/`.

## Donde Esta

- Namespace: `gateway`
- Deployment: `apisix`
- StatefulSet: `apisix-etcd`
- Gateway publico: `http://192.168.56.15:30080`
- Admin API: `svc/apisix-admin:9180`, solo por port-forward.

## Como Se Usa

Acceso publico:

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

## Que Contiene En Este Caso

Upstreams:

- `1`: PostgREST.
- `2`: Keycloak.
- `3`: SPA cliente DENA.

Rutas:

- `/api` y `/api/*`: PostgREST protegido por OIDC.
- `/realms/*`: Keycloak publico.
- `/admin/*`: consola admin Keycloak.
- `/resources/*`: assets de Keycloak.
- `POST /dena/admin-files`: RPC DENA protegida.
- `/*`: fallback a la SPA.

## Como Verificarlo

```bash
bash scripts/verify-fase13.sh
bash scripts/dena/test-curl.sh
```

## Por Que Se Usa

Porque centraliza seguridad y entrada. Las bases de datos y servicios internos no se exponen directamente.
