# GitHub Actions

Este repositorio incluye dos workflows:

- `Repo CI`: valida cambios de código y configuración en cada push a `main`, ramas `fases/**`, pull request y ejecución manual.
- `Cluster Verify`: ejecuta manualmente las verificaciones de fases contra el clúster k3s desplegado.
- `Phase Ops`: ejecuta manualmente operaciones de fase contra el clúster k3s desplegado.

## Repo CI

El workflow `.github/workflows/repo-ci.yml` ejecuta:

- `bash -n` sobre todos los scripts.
- `shellcheck` sobre todos los scripts.
- `jq empty` sobre los JSON de APISIX.
- `actionlint` sobre workflows de GitHub Actions.
- `yamllint` sobre configuración GitHub, values Helm y manifiestos Kubernetes.
- `terraform fmt -check`, `terraform init -backend=false` y `terraform validate`.

## Cluster Verify

El workflow `.github/workflows/cluster-verify.yml` está pensado para ejecutarse con `workflow_dispatch`.

Como el entorno validado vive en una máquina local DietPi/k3s, este workflow debe correr en un runner con acceso de red al clúster. La opción más directa es instalar un GitHub Actions self-hosted runner en la máquina operadora o en otra máquina que pueda usar el mismo kubeconfig.

Secretos opcionales:

- `KUBECONFIG_B64`: contenido de `/home/dietpi/.kube/dena-config` codificado con `base64 -w0`.
- `FASE12_KEYCLOAK_ENV_B64`: contenido de `.local/fase12-keycloak.env` codificado con `base64 -w0`.

Si el runner ya tiene `KUBECONFIG` exportado o usa el kubeconfig por defecto de los scripts (`$HOME/.kube/dena-config`), no hace falta definir `KUBECONFIG_B64`. Si se define, el workflow lo restaura dentro del workspace y exporta `KUBECONFIG` antes de ejecutar las verificaciones.

Si el runner ya tiene `.local/fase12-keycloak.env` preparado, no hace falta definir `FASE12_KEYCLOAK_ENV_B64`. Si se define, el workflow lo restaura dentro del workspace.

Ejemplo para generar secretos localmente:

```bash
base64 -w0 /home/dietpi/.kube/dena-config
base64 -w0 .local/fase12-keycloak.env
```

El input `phase` permite ejecutar todo (`all`) o una verificación concreta: `fase10`, `fase11`, `fase11b`, `fase12-nifi`, `fase12-keycloak`, `fase13`, `fase14` o `fase15`.

## Phase Ops

El workflow `.github/workflows/phase-ops.yml` centraliza operaciones manuales sobre el stack:

- verificaciones completas o por fase
- `apply-fase12-keycloak`
- `apply-fase14-grafana`
- `apply-fase15-datalake`
- `provision-fase12-nifi`
- `load-expedientes`
- `apply-dena-api`
- `apply-fase13-apisix`
- `preflight-fase8`
- `recover-fase7`

Este workflow también requiere un runner con acceso al clúster y las mismas reglas de secretos que `Cluster Verify`.

## Regla de mantenimiento

A partir de Fase 14, cada fase debe cerrar estas tareas antes de marcar su Issue como completada:

- actualizar o crear el script local de verificación
- actualizar `Cluster Verify` o `Phase Ops` si hay una nueva operación o fase verificable
- actualizar la documentación de estado
- ejecutar `Repo CI`
- comentar en la Issue el workflow o comando usado para validar
- cambiar la etiqueta `estado: pendiente` por `estado: completada` y cerrar la Issue
