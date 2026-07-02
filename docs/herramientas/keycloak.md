# Keycloak

## Que Es

Keycloak es un servidor de identidad. Gestiona usuarios, clientes, roles y emite tokens OIDC/OAuth2.

## Objetivo En Este Piloto

Keycloak decide quien puede pedir datos. APISIX valida los tokens emitidos por Keycloak antes de dejar pasar peticiones a la API.

## Donde Esta

- Namespace: `auth`
- Deployment: `keycloak`
- Service: `keycloak`
- Base de datos: PostgreSQL `auth`
- URL admin: `http://192.168.56.15:30080/admin/`
- Realm operativo: `piloto`

## Como Se Usa

Consola admin:

```text
http://192.168.56.15:30080/admin/
```

Discovery OIDC:

```text
http://192.168.56.15:30080/realms/piloto/.well-known/openid-configuration
```

Token demo:

```bash
curl -X POST http://192.168.56.15:30080/realms/piloto/protocol/openid-connect/token \
  -d client_id=react-frontend \
  -d grant_type=password \
  -d username=testuser \
  -d password='Test1234!' \
  -d scope=openid
```

## Que Contiene En Este Caso

Realm `piloto`:

- Cliente publico `react-frontend`.
- Cliente confidencial `apisix-gateway`.
- Usuario `testuser`.
- Roles `dena-reader`, `dena-writer`, `dena-admin`.

Tambien existe realm historico `dena`, pero el operativo del piloto es `piloto`.

## Como Verificarlo

```bash
bash scripts/verify-fase12-keycloak.sh
```

## Por Que Se Usa

Porque evita que la API acepte llamadas anonimas. El consumidor necesita un token valido antes de pedir expedientes.
