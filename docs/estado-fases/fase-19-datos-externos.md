# Fase 19: datos externos DENA

## Objetivo

Crear un PostgreSQL aislado para el modelo semantico de datos externos DENA derivado de Markdown.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/apply-fase19-datos-externos.sh
bash scripts/verify-fase19-datos-externos.sh
```

## Que hace cada parte

- `apply-fase19-datos-externos.sh`: crea namespace, Secret, PostgreSQL y SQL del modelo externo.
- `sql/datos-externos/001_schema.sql`: define el esquema base.
- `sql/datos-externos/002_markdown_catalog.sql`: carga catalogo derivado de Markdown.
- `sql/datos-externos/003_demo_data.sql`: carga datos demo.
- `verify-fase19-datos-externos.sh`: valida tablas, funciones y datos esperados.

## Verificacion

```bash
bash scripts/verify-fase19-datos-externos.sh
```

## Referencias

- [Historico fase 19](estado-fases-0-19.md)
- [Guia Fase 19](../guias/fase19-datos-externos.md)
