# SPA Cliente DENA

## Qué Es

La SPA cliente DENA es una página web demo servida por NGINX. Simula un cliente DENA-CORE que se autentica y consulta expedientes.

## Objetivo En Este Piloto

Demuestra el flujo completo:

1. Usuario introduce credenciales demo.
2. La SPA pide un token a Keycloak.
3. La SPA llama a `POST /dena/admin-files` con bearer token.
4. APISIX valida el token.
5. PostgREST ejecuta la RPC.
6. La SPA muestra expedientes.

## Dónde Está

- Namespace: `app`
- Deployment: `dena-interop-spa`
- Service interno: `dena-interop-spa`
- URL pública: `http://192.168.56.15:30080/`
- Manifiesto: `k8s-manifests/dena-interop-spa.yaml`

## Cómo Se Usa

Abrir:

```text
http://192.168.56.15:30080/
```

Credenciales demo:

- Usuario: `testuser`
- Password: `Test1234!`

## Qué Contiene En Este Caso

Contiene una página HTML/JS estática en un ConfigMap. No es la SPA definitiva de producción; es una demo funcional para probar OIDC y API DENA desde navegador.

## Cómo Verificarlo

```bash
curl -i http://192.168.56.15:30080/
bash scripts/dena/test-curl.sh
```

## Por Qué Se Usa

Porque permite enseñar el flujo a usuarios no técnicos sin ejecutar comandos manuales para token y API.
