# Estado Fase 20

Fecha: 2026-07-10

## Resumen

Se incorpora un flujo NiFi incremental que replica cambios de `verticales.expedientes.admin_file` hacia el modelo DENA enriquecido de `datos_externos`.

## Cambios Principales

- Nuevo SQL `sql/datos-externos/004_nifi_staging.sql`.
- Nuevo script `scripts/dena/provision-fase20-datos-externos-nifi.sh`.
- Nuevo script `scripts/verify-fase20-datos-externos-nifi.sh`.
- Nueva guia `docs/guias/fase20-nifi-datos-externos.md`.
- Nuevo grupo NiFi `Fase 20 - DENA datos externos incremental`.

## Verificacion Esperada

```bash
bash scripts/verify-fase20-datos-externos-nifi.sh
```

Resultado esperado:

- Procesadores NiFi `VALID/RUNNING`.
- Controller services `VALID/ENABLED`.
- Cambios de `EXP-0001` coincidentes entre `verticales` y `datos_externos`.

## Prueba Validada

Se actualizo `verticales.expedientes.admin_file` para `id = 1`:

```text
title = Expediente demo 1 reflejado automaticamente
status = archivado
amount_eur = 9876.54
```

Tras el siguiente ciclo de NiFi, `datos_externos.dena.dena_expediente` reflejo:

```text
external_id = EXP-0001
state_code = CLOSED
title = Expediente demo 1 reflejado automaticamente
amount_eur = 9876.54
```
