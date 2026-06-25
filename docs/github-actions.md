# GitHub Actions

Este repositorio incluye dos workflows:

- `Repo CI`: valida cambios de codigo y configuracion en cada push a `main`, ramas `fases/**`, pull request y ejecucion manual.
- `Cluster Verify`: ejecuta manualmente las verificaciones de fases contra el cluster k3s desplegado.
- `Phase Ops`: ejecuta manualmente operaciones de fase contra el cluster k3s desplegado.

## Repo CI

El workflow `.github/workflows/repo-ci.yml` ejecuta:

- `bash -n` sobre todos los scripts.
- `shellcheck` sobre todos los scripts.
- `jq empty` sobre los JSON de APISIX.
- `actionlint` sobre workflows de GitHub Actions.
- `yamllint` sobre configuracion GitHub, values Helm y manifiestos Kubernetes.
- `terraform fmt -check`, `terraform init -backend=false` y `terraform validate`.

## Cluster Verify

El workflow `.github/workflows/cluster-verify.yml` esta pensado para ejecutarse con `workflow_dispatch`.

Como el entorno validado vive en una maquina local DietPi/k3s, este workflow debe correr en un runner con acceso de red al cluster. La opcion mas directa es instalar un GitHub Actions self-hosted runner en la maquina operadora o en otra maquina que pueda usar el mismo kubeconfig.

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

El input `phase` permite ejecutar todo (`all`) o una verificacion concreta: `fase10`, `fase11`, `fase11b`, `fase12-nifi`, `fase12-keycloak` o `fase13`.

## Phase Ops

El workflow `.github/workflows/phase-ops.yml` centraliza operaciones manuales sobre el stack:

- verificaciones completas o por fase
- `apply-fase12-keycloak`
- `provision-fase12-nifi`
- `load-expedientes`
- `apply-dena-api`
- `apply-fase13-apisix`
- `preflight-fase8`
- `recover-fase7`

Este workflow tambien requiere un runner con acceso al cluster y las mismas reglas de secretos que `Cluster Verify`.

## Regla de mantenimiento

A partir de Fase 14, cada fase debe cerrar estas tareas antes de marcar su Issue como completada:

- actualizar o crear el script local de verificacion
- actualizar `Cluster Verify` o `Phase Ops` si hay una nueva operacion o fase verificable
- actualizar la documentacion de estado
- ejecutar `Repo CI`
- comentar en la Issue el workflow o comando usado para validar
- cambiar la etiqueta `estado: pendiente` por `estado: completada` y cerrar la Issue
