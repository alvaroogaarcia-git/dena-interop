# Fase 12: Keycloak por Terraform

## Objetivo

Gestionar en Keycloak el realm `piloto`, clientes, roles, usuarios demo y recuperacion mediante Terraform.

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
- Terraform crea roles, usuario de prueba y operador de recuperacion.
- `verify-fase12-keycloak.sh`: valida endpoints OIDC y objetos esperados.

## Verificacion

```bash
bash scripts/verify-fase12-keycloak.sh
```

## Nota de numeracion

Algunos scripts conservan `fase12` en el nombre por compatibilidad historica. Esta pagina documenta el alcance actual de Keycloak gestionado por Terraform.

## Referencias

- [Historico 0-13](estado-fases-0-13.md)
- [Recuperacion passkey](../operacion/recuperacion-passkey-keycloak.md)
