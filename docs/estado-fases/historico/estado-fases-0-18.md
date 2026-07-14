# Estado Fase 18

Fecha: 2026-07-06

## Resumen

Se habilito MFA WebAuthn/FIDO2 para la consola admin DENA. El usuario `adminuser` tiene una credencial WebAuthn registrada en Keycloak y la consola dejo de usar password grant.

## Cambios Principales

- `k8s-manifests/dena-admin-console.yaml`
  - sustituye `grant_type=password` por Authorization Code + PKCE.
  - redirige a Keycloak para autenticar.
  - intercambia el `code` por token OIDC en el navegador.
  - usa el bearer token para `POST /dena/admin-files`.
  - incorpora botón `Cerrar sesion`, que limpia `sessionStorage` y llama a logout OIDC.

- Keycloak realm `piloto`
  - flujo browser activo: `browser-dena-webauthn`.
  - subflujo condicional WebAuthn después de usuario/password.
  - `webAuthnPolicyRpId=localhost` para la demo por túnel SSH.
  - `react-frontend` con `directAccessGrantsEnabled=false`.
  - redirect y web origin `http://localhost:30080`.

- `k8s-manifests/keycloak-deployment.yaml`
  - `KC_HOSTNAME=http://localhost:30080` para que Keycloak emita URLs coherentes con el origen seguro de WebAuthn por túnel.
  - memoria aumentada a `512Mi` request y `1Gi` limit para evitar timeouts durante login/MFA.

- Rutas APISIX de Keycloak
  - `X-Forwarded-Host=localhost`.
  - `X-Forwarded-Port=30080`.
  - `X-Forwarded-Proto=http`.

## Acceso De Demo

En el PC operador:

```bash
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

Después abrir:

```text
http://localhost:30080/dena/admin-console
```

Flujo esperado:

1. Pulsar `Iniciar sesion y cargar consola`.
2. Keycloak pide usuario y password.
3. Keycloak pide passkey/WebAuthn.
4. El operador toca la tarjeta e introduce el PIN local si el sistema lo pide.
5. La consola vuelve a cargar y consulta expedientes.

## Verificaciones Realizadas

Desde el cluster:

```text
Consola contiene PKCE: OK
OpenID config: 200
Password grant react-frontend: 400 unauthorized_client
browserFlow: browser-dena-webauthn
webAuthnPolicyRpId: localhost
dena-admin-console: Running
keycloak: Running
```

La verificación negativa confirma que `react-frontend` ya no puede obtener token con password grant, evitando saltarse MFA.

## Notas De Operación

La configuración `localhost` es una solucion de demo para no requerir permisos de administrador en Windows ni editar `hosts`. En un despliegue real se debe sustituir por un FQDN HTTPS, por ejemplo:

```text
https://admin.dena.example
```

En ese caso hay que actualizar:

- `KC_HOSTNAME`
- `webAuthnPolicyRpId`
- redirect URIs y web origins del cliente `react-frontend`
- cabeceras `X-Forwarded-*` de APISIX
- certificados TLS del punto de entrada
