# SQL datos externos

Modelo PostgreSQL independiente para conservar la semantica DENA extraida de los Markdown de `/home/dietpi/codex_unzip/codex/semantica-dena`.

Archivos:

- `001_schema.sql`: esquema fisico de negocio `dena`, derivado de los Markdown y preparado para PostgreSQL 15+.
- `002_markdown_catalog.sql`: catalogo documental con los ficheros Markdown, tablas sugeridas, campos principales y valores enumerados.
- `003_demo_data.sql`: datos ficticios idempotentes para navegar el modelo desde `psql` o Mathesar.

La carga se ejecuta con `scripts/dena/apply-fase19-datos-externos.sh`.
