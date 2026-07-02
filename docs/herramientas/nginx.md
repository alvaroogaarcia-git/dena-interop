# NGINX

## Que Es

NGINX es un servidor web. En este piloto se usa en su forma mas simple: servir archivos estaticos HTML, CSS y JavaScript.

## Objetivo En Este Piloto

NGINX sirve la SPA cliente DENA desde el namespace `app`. APISIX enruta `/` y cualquier ruta no especifica hacia este servicio.

## Donde Esta

- Namespace: `app`
- Deployment: `dena-interop-spa`
- Contenedor: `nginx:1.27-alpine`
- Service interno: `dena-interop-spa:80`
- URL publica: `http://192.168.56.15:30080/`

## Como Se Usa

Normalmente no se entra a NGINX directamente. Se accede por APISIX:

```text
http://192.168.56.15:30080/
```

Ver logs:

```bash
kubectl logs -n app deploy/dena-interop-spa --tail=80
```

## Que Contiene En Este Caso

El contenido web vive en un ConfigMap:

- `k8s-manifests/dena-interop-spa.yaml`
- `ConfigMap/dena-interop-spa`
- `index.html`

La pagina hace:

- Login demo contra Keycloak.
- Peticion a `POST /dena/admin-files`.
- Render JSON de expedientes.

## Como Verificarlo

```bash
kubectl rollout status deployment/dena-interop-spa -n app
curl -i http://192.168.56.15:30080/
```

## Por Que Se Usa

Porque es una forma sencilla y estable de servir una demo web sin introducir todavia una cadena completa de build frontend.
