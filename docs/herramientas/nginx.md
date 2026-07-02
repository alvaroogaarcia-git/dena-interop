# NGINX

## Qué Es

NGINX es un servidor web. En este piloto se usa en su forma más simple: servir archivos estáticos HTML, CSS y JavaScript.

## Objetivo En Este Piloto

NGINX sirve la SPA cliente DENA desde el namespace `app`. APISIX enruta `/` y cualquier ruta no específica hacia este servicio.

## Dónde Está

- Namespace: `app`
- Deployment: `dena-interop-spa`
- Contenedor: `nginx:1.27-alpine`
- Service interno: `dena-interop-spa:80`
- URL pública: `http://192.168.56.15:30080/`

## Cómo Se Usa

Normalmente no se entra a NGINX directamente. Se accede por APISIX:

```text
http://192.168.56.15:30080/
```

Ver logs:

```bash
kubectl logs -n app deploy/dena-interop-spa --tail=80
```

## Qué Contiene En Este Caso

El contenido web vive en un ConfigMap:

- `k8s-manifests/dena-interop-spa.yaml`
- `ConfigMap/dena-interop-spa`
- `index.html`

La página hace:

- Login demo contra Keycloak.
- Petición a `POST /dena/admin-files`.
- Render JSON de expedientes.

## Cómo Verificarlo

```bash
kubectl rollout status deployment/dena-interop-spa -n app
curl -i http://192.168.56.15:30080/
```

## Por Qué Se Usa

Porque es una forma sencilla y estable de servir una demo web sin introducir todavía una cadena completa de build frontend.
