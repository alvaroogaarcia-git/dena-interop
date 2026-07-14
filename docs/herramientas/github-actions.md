# GitHub Actions

## Qué Es

GitHub Actions es el sistema de automatización de GitHub. Ejecuta workflows para validar o aplicar tareas del repositorio.

## Objetivo En Este Piloto

Centraliza verificaciones y operaciones manuales reproducibles.

## Dónde Está

Workflows:

- `.github/workflows/cluster-verify.yml`
- `.github/workflows/phase-ops.yml`
- `.github/workflows/repo-ci.yml`

Documentación específica:

- [github-actions.md](../operacion/github-actions.md)

## Cómo Se Usa

Desde GitHub se lanza manualmente el workflow con inputs:

- Verificación completa.
- Verificación por fase.
- Aplicación de fases concretas.

## Qué Contiene En Este Caso

`cluster-verify.yml`:

- Ejecuta `verify-stack.sh` para `all` y verificaciones concretas hasta Fase 21.

`phase-ops.yml`:

- Aplica Keycloak.
- Aplica Grafana.
- Aplica SQL del datalake.
- Aplica datos externos.
- Provisiona NiFi hacia datos externos.
- Aplica el explorador demo de Fase 21.
- Provisiona NiFi.
- Ejecuta verificaciones.

## Cómo Verificarlo

Localmente, los mismos scripts se pueden ejecutar:

```bash
bash scripts/verify-stack.sh
```

## Por Qué Se Usa

Porque evita que las comprobaciones dependan de memoria o pasos manuales. Lo que se valida en local también puede automatizarse en CI.
