# NGINX

## Qué Es

NGINX es un servidor web. En este piloto se usa en su forma más simple: servir archivos estáticos HTML, CSS y JavaScript.

## Objetivo En Este Piloto

NGINX sirve las dos páginas estáticas del namespace `app`: el portal ciudadano y la consola admin. APISIX enruta `/` hacia el portal ciudadano y `/dena/admin-console` hacia la consola admin.

## Dónde Está

- Namespace: `app`
- Deployment: `dena-interop-spa`
- Deployment: `dena-admin-console`
- Contenedor: `nginx:1.27-alpine`
- Service interno: `dena-interop-spa:80`
- Service interno: `dena-admin-console:80`
- URL gateway directa: `http://192.168.56.15:30080/`
- URL web OIDC por túnel: `http://localhost:30080/`
- URL admin con passkey por túnel: `http://localhost:30080/dena/admin-console`

## Cómo Se Usa

Normalmente no se entra a NGINX directamente. Se accede por APISIX:

```text
http://192.168.56.15:30080/
http://localhost:30080/
http://localhost:30080/dena/admin-console
```

Los logins de navegador usan `localhost:30080` porque WebAuthn/passkey solo funciona en origen seguro. En esta demo HTTP, `localhost` es el origen seguro; la IP directa se mantiene para comprobaciones de gateway/API.

Ver logs:

```bash
kubectl logs -n app deploy/dena-interop-spa --tail=80
kubectl logs -n app deploy/dena-admin-console --tail=80
```

## Qué Contiene En Este Caso

El contenido web vive en un ConfigMap:

- `k8s-manifests/dena-interop-spa.yaml`
- `ConfigMap/dena-interop-spa`
- `k8s-manifests/dena-admin-console.yaml`
- `ConfigMap/dena-admin-console`
- `index.html`

La página hace:

- Login demo contra Keycloak.
- Petición a `POST /dena/admin-files`.
- Render JSON de expedientes.
- Panel admin con KPIs, trazabilidad, auditoría y export CSV/JSON.

## Cómo Verificarlo

```bash
kubectl rollout status deployment/dena-interop-spa -n app
kubectl rollout status deployment/dena-admin-console -n app
curl -i http://192.168.56.15:30080/
curl -H 'Host: localhost:30080' -i http://192.168.56.15:30080/dena/admin-console
```

## Por Qué Se Usa

Porque es una forma sencilla y estable de servir una demo web sin introducir todavía una cadena completa de build frontend.
