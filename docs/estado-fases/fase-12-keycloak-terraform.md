# Fase 12: Keycloak por Terraform

## Objetivo

Gestionar en Keycloak el realm `piloto`, clientes, roles, usuarios demo y recuperación mediante Terraform.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/apply-fase12-keycloak.sh
bash scripts/verify-fase12-keycloak.sh
```

## Que hace cada parte

- `apply-fase12-keycloak.sh`: carga secretos locales, inicializa Terraform si hace falta y aplica recursos de Keycloak.
- Terraform crea o actualiza el realm `piloto`.
- Terraform configura los clientes `react-frontend` y `apisix-gateway`.
- Terraform crea roles, usuario de prueba y operador de recuperación.
- `verify-fase12-keycloak.sh`: valida endpoints OIDC y objetos esperados.

## Verificación

```bash
bash scripts/verify-fase12-keycloak.sh
```

## Nota de numeracion

Algunos scripts conservan `fase12` en el nombre por compatibilidad histórica. Esta página documenta el alcance actual de Keycloak gestionado por Terraform.

## Referencias

- [Histórico 0-13](historico/estado-fases-0-13.md)
- [Recuperación passkey](../operacion/recuperacion-passkey-keycloak.md)
