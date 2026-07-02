# PostgREST

## Qué Es

PostgREST convierte una base PostgreSQL en una API REST. Lee tablas, vistas y funciones SQL y las expone como endpoints HTTP.

## Objetivo En Este Piloto

PostgREST expone el datalake como API sin escribir una aplicación backend a medida.

## Dónde Está

- Namespace: `datalake`
- Deployment: `postgrest`
- Service interno: `postgrest.datalake.svc.cluster.local:3000`
- Publicación externa: APISIX en `http://192.168.56.15:30080/api/`

## Cómo Se Usa

No se accede directamente desde fuera. Se accede por APISIX con token:

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://192.168.56.15:30080/api/
```

RPC DENA:

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"p_limit":2}' \
  http://192.168.56.15:30080/dena/admin-files
```

## Qué Contiene En Este Caso

PostgREST usa:

- Rol autenticador `postgrest`.
- Rol anónimo `anon`.
- Schema expuesto: `public`.
- Función `public.dena_data_retrieve`.

APISIX elimina el header `Authorization` antes de pasar a PostgREST porque la autorización ya se valida en el gateway.

## Cómo Verificarlo

```bash
bash scripts/verify-fase10.sh
bash scripts/verify-fase13.sh
```

## Por Qué Se Usa

Porque permite servir datos del datalake como API REST de forma simple y reproducible, dejando la lógica de consulta en SQL.
