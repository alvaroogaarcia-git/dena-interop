# SPA Cliente DENA

## Qué Es

La SPA cliente DENA es una página web demo servida por NGINX. Simula un cliente DENA-CORE que se autentica y consulta expedientes.

## Objetivo En Este Piloto

Demuestra el flujo completo:

1. Usuario pulsa `Consultar expedientes`.
2. La SPA redirige a Keycloak con Authorization Code + PKCE.
3. Usuario introduce credenciales demo en Keycloak.
4. La SPA intercambia el `code` por un token OIDC.
5. La SPA llama a `POST /dena/admin-files` con bearer token para recuperar expedientes.
6. APISIX valida el token.
7. PostgREST ejecuta la RPC.
8. La SPA muestra expedientes y carpetas ciudadanas desde `datos_externos`.

## Dónde Está

- Namespace: `app`
- Deployment: `dena-interop-spa`
- Service interno: `dena-interop-spa`
- URL con login OIDC: `http://localhost:30080/` mediante tunel SSH.
- URL gateway directa para health/static: `http://192.168.56.15:30080/`
- Manifiesto: `k8s-manifests/dena-interop-spa.yaml`

## Cómo Se Usa

Abrir:

```text
http://localhost:30080/
```

Antes de abrirla desde el PC operador:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

Al pulsar `Consultar expedientes`, Keycloak pedirá las credenciales demo:

- Usuario: `testuser`
- Password: `Test1234!`

El campo `Identificador ciudadano` filtra la demo por ciudadano. El valor inicial es:

- Ciudadano demo: `CIT-10001`

Tras iniciar sesión se muestran:

- Expedientes del ciudadano.
- Notificaciones relacionadas.
- Pagos relacionados.
- Citas relacionadas.
- Datos personales consolidados.

## Qué Contiene En Este Caso

Contiene una página HTML/JS estática en un ConfigMap. No es la SPA definitiva de producción; es una demo funcional para probar OIDC con PKCE, API DENA desde navegador y el explorador ciudadano de `datos_externos`.

## Cómo Verificarlo

```bash
curl -i http://192.168.56.15:30080/
bash scripts/dena/test-curl.sh
```

Comprobaciones adicionales de las carpetas ciudadanas:

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://192.168.56.15:30080/dena/external/dena_external_expedientes?select=id,titulo,estado&persona_id=eq.CIT-10001&limit=2"
```

## Por Qué Se Usa

Porque permite enseñar el flujo a usuarios no técnicos sin ejecutar comandos manuales para token y API.
