# auth / keycloak

## Qué Es

Base PostgreSQL que usa Keycloak para usuarios, realms, clientes, sesiones y credenciales.

## Dónde Está

- Namespace: `auth`
- Pod: `postgresql-0`
- Base de datos: `keycloak`
- Usuario SQL: `keycloak`

## Contraseña

Valor demo fijo:

```text
v3OYOpRXwCZPAK1pkvUxPvLA
```

También vive en el secret:

```bash
kubectl get secret -n auth postgresql-auth -o jsonpath='{.data.postgres-password}' | base64 -d
```

## Acceso Exacto

### Consola Interactiva

```bash
kubectl exec -i -n auth postgresql-0 -- \
  env PGPASSWORD='v3OYOpRXwCZPAK1pkvUxPvLA' \
  psql -U keycloak -d keycloak
```

### Consulta Rápida

```bash
kubectl exec -i -n auth postgresql-0 -- \
  env PGPASSWORD='v3OYOpRXwCZPAK1pkvUxPvLA' \
  psql -U keycloak -d keycloak -c "select count(*) from pg_catalog.pg_roles;"
```

### Qué Ver

Dentro de `psql`:

```sql
\c keycloak
\dt
\dn
select current_database();
select count(*) from pg_catalog.pg_roles;
```

## Cuándo Usarlo

- Para revisar realms, clientes y usuarios desde SQL interno.
- Para comprobar que Keycloak arranca contra la base correcta.
- Para diagnósticos cuando un login falla por persistencia o migraciones.
