# Estado Fases 0-15

Fecha: 2026-07-01

## Resumen

El alcance consolidado queda versionado hasta Fase 15:

- Fases 0-14: plataforma, autenticación, gateway, observabilidad, datalake, NiFi, verticales, API DENA protegida por OIDC y Grafana gestionado por Terraform.
- Fase 15: SQL DENA del datalake separado en piezas reproducibles y verificación automatizada de esquema/staging.

## Fase 15 - SQL del datalake

Estado versionado:

- `sql/01-dena-admin-file.sql`: esquema principal, tabla `dena.admin_file` y vista `dena."adminFile"`.
- `sql/02-dena-rpc.sql`: RPC `public.dena_data_retrieve`.
- `sql/03-dena-staging.sql`: staging `dena.admin_file_staging` y función `dena.dena_staging_to_main()`.
- `scripts/dena/apply-fase15-datalake.sh`: aplica los tres SQL contra `postgresql-datalake`.
- `scripts/verify-fase15.sh`: comprueba objetos SQL y recuentos de staging/main.
- `docs/fase15-datalake.md`: procedimiento operativo de carga manual y flujo NiFi.

## Aplicación reproducible

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config

bash scripts/dena/apply-fase15-datalake.sh
bash scripts/verify-fase15.sh
```

## Integración CI/ops

`Cluster Verify` y `Phase Ops` incluyen Fase 15:

- `Cluster Verify`: input `fase15` y ejecución incluida en `all`.
- `Phase Ops`: operaciones `verify-fase15` y `apply-fase15-datalake`.

## Continuacion

La Fase 16, Portainer y los scripts de operación quedan cerrados en `docs/estado-fases-0-17.md`.
