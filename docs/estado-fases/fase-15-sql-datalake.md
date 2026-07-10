# Fase 15: SQL del datalake

## Objetivo

Aplicar el modelo SQL DENA del datalake, staging y carga local reproducible.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/apply-fase15-datalake.sh
bash scripts/verify-fase15.sh
```

## Que hace cada parte

- `apply-fase15-datalake.sh`: ejecuta los SQL versionados contra `postgresql-datalake`.
- `sql/01-dena-admin-file.sql`: crea el modelo principal.
- `sql/02-dena-rpc.sql`: crea funciones/RPC usadas por la API.
- `sql/03-dena-staging.sql`: crea staging y promocion desde NiFi.
- `verify-fase15.sh`: comprueba objetos SQL y recuentos esperados.

## Verificacion

```bash
bash scripts/verify-fase15.sh
```

## Referencias

- [Historico 0-15](historico/estado-fases-0-15.md)
- [Guia Fase 15](../guias/fase15-datalake.md)
