# PostgreSQL

## Que Es

PostgreSQL es una base de datos relacional. Guarda datos estructurados en tablas y permite consultas SQL.

## Objetivo En Este Piloto

Hay varias bases PostgreSQL, cada una con una responsabilidad:

- `auth`: datos internos de Keycloak.
- `verticales`: origen editable de expedientes.
- `datalake`: copia consolidada y expuesta por API.

## Donde Esta

Namespaces:

- `auth`: StatefulSet `postgresql`.
- `verticales`: StatefulSet `postgresql-verticales`.
- `datalake`: StatefulSet `postgresql-datalake`.

Services:

- `postgresql.auth.svc.cluster.local:5432`
- `postgresql-verticales.verticales.svc.cluster.local:5432`
- `postgresql-datalake.datalake.svc.cluster.local:5432`

## Como Se Usa

Consulta interna con `kubectl exec`:

```bash
PG="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$PG" \
  psql -U postgres -d datalake -c 'select count(*) from dena.admin_file;'
```

## Que Contiene En Este Caso

`auth`:

- Base `keycloak`.
- Usuarios, sesiones, clientes y realms de Keycloak.

`verticales`:

- Base `expedientes`.
- Tabla `expedientes.admin_file`.
- Base `mathesar_django`.

`datalake`:

- Base `datalake`.
- Esquema `dena`.
- Tabla `dena.admin_file`.
- Staging `dena.admin_file_staging`.
- RPC `public.dena_data_retrieve`.

## Como Verificarlo

```bash
bash scripts/verify-fase10.sh
bash scripts/verify-fase11b.sh
bash scripts/verify-fase15.sh
```

## Por Que Se Usa

Porque separa identidad, origen y datos consolidados. Esto evita mezclar responsabilidades y permite simular el intercambio entre administraciones.
