# GitHub Actions

## Que Es

GitHub Actions es el sistema de automatizacion de GitHub. Ejecuta workflows para validar o aplicar tareas del repositorio.

## Objetivo En Este Piloto

Centraliza verificaciones y operaciones manuales reproducibles.

## Donde Esta

Workflows:

- `.github/workflows/cluster-verify.yml`
- `.github/workflows/phase-ops.yml`

Documentacion especifica:

- `docs/github-actions.md`

## Como Se Usa

Desde GitHub se lanza manualmente el workflow con inputs:

- Verificacion completa.
- Verificacion por fase.
- Aplicacion de fases concretas.

## Que Contiene En Este Caso

`cluster-verify.yml`:

- Ejecuta verificaciones de fases.

`phase-ops.yml`:

- Aplica Keycloak.
- Aplica Grafana.
- Aplica SQL del datalake.
- Provisiona NiFi.
- Ejecuta verificaciones.

## Como Verificarlo

Localmente, los mismos scripts se pueden ejecutar:

```bash
bash scripts/verify-stack.sh
```

## Por Que Se Usa

Porque evita que las comprobaciones dependan de memoria o pasos manuales. Lo que se valida en local tambien puede automatizarse en CI.
