# verticales / mathesar_django

## Qué Es

Base interna de Mathesar. No contiene los expedientes de negocio, pero Mathesar la necesita para funcionar.

## Dónde Está

- Namespace: `verticales`
- Pod: `postgresql-verticales-0`
- Base de datos: `mathesar_django`
- Usuario SQL: `postgres`

## Contraseña

La misma que `verticales / expedientes`:

```text
pyZN2eJRnVfArOgFltoTlotN
```

## Acceso Exacto

### Consola Interactiva

```bash
kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD='pyZN2eJRnVfArOgFltoTlotN' \
  psql -U postgres -d mathesar_django
```

### Consulta Rápida

```bash
kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD='pyZN2eJRnVfArOgFltoTlotN' \
  psql -U postgres -d mathesar_django -c "select current_database();"
```

### Qué Ver

```sql
\dt
select datname from pg_database where datname = 'mathesar_django';
```

## Cuándo Usarlo

- Para revisar la base interna de Mathesar.
- Para diagnosticar arranque o migraciones de Mathesar.
- Para diferenciar errores de la base de negocio `expedientes`.

