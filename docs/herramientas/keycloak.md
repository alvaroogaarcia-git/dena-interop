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
- URL admin: `http://192.168.56.15:30080/admin/`
- Realm operativo: `piloto`

## Cómo Se Usa

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

## Qué Contiene En Este Caso

Realm `piloto`:

- Cliente público `react-frontend`.
- Cliente confidencial `apisix-gateway`.
- Usuario `testuser`.
- Roles `dena-reader`, `dena-writer`, `dena-admin`.

También existe realm histórico `dena`, pero el operativo del piloto es `piloto`.

## Cómo Verificarlo

```bash
bash scripts/verify-fase12-keycloak.sh
```

## Por Qué Se Usa

Porque evita que la API acepte llamadas anónimas. El consumidor necesita un token válido antes de pedir expedientes.
