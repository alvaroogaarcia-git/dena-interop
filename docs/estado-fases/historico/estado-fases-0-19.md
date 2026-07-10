# Estado Fase 19

Fecha: 2026-07-09

## Resumen

Se incorpora un PostgreSQL independiente para datos externos derivados de la documentacion Markdown de semantica DENA.

## Cambios Principales

- Nuevo namespace aislado `datos-externos`.
- Nuevo release Helm `datos-externos-postgresql`.
- Nuevo values file `helm-values/datos-externos-postgresql-values.yaml`.
- Nuevo modelo SQL en `sql/datos-externos/001_schema.sql`.
- Nuevo seed documental en `sql/datos-externos/002_markdown_catalog.sql`.
- Nuevo seed demo operativo en `sql/datos-externos/003_demo_data.sql`.
- Nuevo script de despliegue `scripts/dena/apply-fase19-datos-externos.sh`.
- Nuevo script de verificacion `scripts/verify-fase19-datos-externos.sh`.
- Nueva guia `docs/guias/fase19-datos-externos.md`.

## Recursos Kubernetes Nuevos

```text
Namespace/datos-externos
Secret/datos-externos-postgresql
Service/datos-externos-postgresql
StatefulSet/datos-externos-postgresql
PVC/data-datos-externos-postgresql-0
```

## Verificacion Esperada

```bash
bash scripts/verify-fase19-datos-externos.sh
```

Resultado esperado:

- Tablas principales del esquema `dena` presentes.
- 21 documentos Markdown catalogados.
- Catalogo de campos y enumeraciones cargado.
- Tipos DENA base disponibles.
- Datos demo DENA cargados: expedientes, notificaciones, pagos, citas, personas y trazas.

## Notas De Operacion

La base no se expone por APISIX, Ingress ni NodePort. El acceso operativo se realiza con `kubectl exec` sobre el pod `datos-externos-postgresql-0`.

El password se conserva localmente en `.local/fase19-datos-externos.env` y tambien en el Secret del release Helm. No se versiona en el repositorio.
