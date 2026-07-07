# Keycloak

## Qué Es

Keycloak es un servidor de identidad. Gestiona usuarios, clientes, roles y emite tokens OIDC/OAuth2.

## Objetivo En Este Piloto

Keycloak decide quién puede pedir datos. APISIX valida los tokens emitidos por Keycloak antes de dejar pasar peticiones a la API.

## Dónde Está

- Namespace: `auth`
- Deployment: `keycloak`
- Service: `keycloak`
- Base de datos: PostgreSQL `auth`
- URL MFA vía túnel local: `http://localhost:30080/admin/`
- Realm operativo: `piloto`

## Cómo Se Usa

Consola admin:

```text
http://localhost:30080/admin/
```

Discovery OIDC:

```text
http://localhost:30080/realms/piloto/.well-known/openid-configuration
```

La consola admin usa Authorization Code + PKCE. El cliente público `react-frontend` no permite `grant_type=password`, para evitar saltarse MFA.

```bash
curl -X POST http://localhost:30080/realms/piloto/protocol/openid-connect/token \
  -d client_id=react-frontend \
  -d grant_type=password \
  -d username=testuser \
  -d password='Test1234!' \
  -d scope=openid
```

Resultado esperado:

```json
{"error":"unauthorized_client","error_description":"Client not allowed for direct access grants"}
```

## Qué Contiene En Este Caso

Realm `piloto`:

- Cliente público `react-frontend`.
- Cliente confidencial `apisix-gateway`.
- Usuario `testuser`.
- Usuario `recovery-operator`, operador limitado para recuperar credenciales.
- Roles `dena-reader`, `dena-writer`, `dena-admin`.
- Flujo browser `browser-dena-webauthn`.
- WebAuthn RP ID `localhost`, usado por la demo mediante túnel SSH.
- Credencial WebAuthn registrada para `adminuser`.

También existe realm histórico `dena`, pero el operativo del piloto es `piloto`.

## Cómo Verificarlo

```bash
bash scripts/verify-fase12-keycloak.sh
```

## Recuperación De Passkey

La guía operativa detallada está en [recuperacion-passkey-keycloak.md](../operacion/recuperacion-passkey-keycloak.md).

Puntos clave:

- `recovery-operator` existe solo en el realm `piloto`.
- Tiene los roles `view-users`, `query-users` y `manage-users` sobre `realm-management`.
- Su password se guarda fuera de Git en `.local/fase12-keycloak.env`.
- La password temporal del usuario afectado solo debe servir para reenrolar una nueva passkey.
- El usuario puede recibir backup codes de un solo uso generados con `scripts/dena/generate-recovery-backup-codes.sh`.
- Cada emisión y cada consumo se registra en `dena.recovery_event` dentro del datalake.

## Por Qué Se Usa

Porque evita que la API acepte llamadas anónimas. El consumidor necesita un token válido antes de pedir expedientes.
