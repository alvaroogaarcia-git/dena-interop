# Recuperacion De Passkey En Keycloak

## Objetivo

Esta guia describe el proceso operativo para recuperar el acceso de un usuario del realm `piloto` cuando pierde su passkey/WebAuthn.

El caso de uso principal es `adminuser`, pero el mismo procedimiento aplica a cualquier usuario del realm al que se le haya registrado una credencial WebAuthn.

## Problema Que Resuelve

Si un usuario solo tiene una passkey y la pierde, quedaria bloqueado de forma permanente.

Para evitarlo, el piloto incorpora un usuario de recuperacion:

- Usuario: `recovery-operator`
- Realm: `piloto`
- Permisos: ver usuarios y gestionar credenciales de usuario
- No permisos: clientes, roles, realm completo ni administracion global

La idea es que este usuario sirva como puente operativo, no como superadministrador.

## Arquitectura Del Flujo

El flujo se compone de estas piezas:

1. Keycloak autentica al operador con `recovery-operator`.
2. El operador entra en la consola admin de Keycloak.
3. Localiza el usuario bloqueado.
4. Revoca la credencial WebAuthn perdida.
5. Emite una password temporal.
6. Fuerza al usuario a registrar una nueva passkey.
7. El usuario vuelve al estado normal de acceso con WebAuthn.

El piloto añade además:

- códigos de respaldo de un solo uso para el usuario
- registro persistente de cada emisión y cada consumo de esos códigos

## Componentes Implicados

- Consola admin de Keycloak: `http://localhost:30080/admin/piloto/console/`
- Consola admin DENA: `http://localhost:30080/dena/admin-console`
- Script de alta del operador: [scripts/dena/apply-recovery-operator.sh](/home/dietpi/dena-interop/scripts/dena/apply-recovery-operator.sh)
- Script de generación de backup codes: [scripts/dena/generate-recovery-backup-codes.sh](/home/dietpi/dena-interop/scripts/dena/generate-recovery-backup-codes.sh)
- Script de consumo de backup code y alta temporal: [scripts/dena/use-recovery-backup-code.sh](/home/dietpi/dena-interop/scripts/dena/use-recovery-backup-code.sh)
- Script principal de Fase 12: [scripts/dena/apply-fase12-keycloak.sh](/home/dietpi/dena-interop/scripts/dena/apply-fase12-keycloak.sh)
- Password local no versionada: `.local/fase12-keycloak.env`

## Credenciales Del Operador

La password del operador se guarda en el fichero local:

```bash
/home/dietpi/dena-interop/.local/fase12-keycloak.env
```

Para verla desde la VM:

```bash
grep '^TF_VAR_recovery_operator_password=' /home/dietpi/dena-interop/.local/fase12-keycloak.env
```

La salida tiene este formato:

```text
TF_VAR_recovery_operator_password=...
```

No se debe copiar a Git ni a tickets públicos.

## Permisos Del Operador

El operador `recovery-operator` tiene roles del cliente interno `realm-management`:

```text
view-users
query-users
manage-users
```

Con esos permisos puede:

- ver usuarios del realm `piloto`
- buscar usuarios por nombre
- resetear contraseñas de usuario
- gestionar credenciales de usuario

No puede:

- crear o editar clientes OIDC
- cambiar roles de negocio
- cambiar el flujo de autenticacion del realm
- tocar la configuracion global de Keycloak

## Procedimiento Operativo

### 0. Generar Y Entregar Códigos De Respaldo

Primero se generan los códigos de respaldo para `adminuser`:

```bash
bash scripts/dena/generate-recovery-backup-codes.sh
```

Por defecto el script:

- crea 10 códigos de un solo uso
- los guarda en `/home/dietpi/dena-interop/.local/recovery/piloto-adminuser-backup-codes.txt`
- deja el hash en la tabla `dena.recovery_backup_code`
- crea un evento `backup_codes_issued` en `dena.recovery_event`

El fichero local debe entregarse al usuario por un canal seguro y guardarse fuera de Git.

### 1. Entrar En Keycloak Con El Operador

Abre la consola:

```text
http://localhost:30080/admin/piloto/console/
```

Inicia sesion con:

- Usuario: `recovery-operator`
- Password: la registrada en `.local/fase12-keycloak.env`

### 2. Localizar El Usuario A Recuperar

En la consola:

1. Selecciona el realm `piloto`.
2. Abre `Users`.
3. Busca `adminuser`.
4. Entra en el usuario.

### 3. Revisar Las Credenciales

En la pestaña `Credentials` deberias ver:

- una password normal
- una credencial `webauthn` con etiqueta tipo `Passkey (Default Label)`

Si la passkey sigue existiendo pero el usuario solo la perdio fisicamente, el sistema no puede distinguirlo. En ese caso se sigue el mismo flujo de recuperacion para reemplazar la credencial.

### 4. Eliminar La Passkey Perdida

Si quieres invalidar el autenticador perdido:

1. Localiza la credencial `webauthn`.
2. Eliminala.

Con esto la passkey anterior deja de servir.

### 5. Emitir Una Password Temporal

En el mismo usuario:

1. Abre `Credentials`.
2. Usa `Reset password`.
3. Define una password temporal fuerte.
4. Marca `Temporary` si la UI lo permite.

La password temporal debe ser solo de uso puente.

Si quieres usar un backup code en lugar de inventar una password manualmente, usa:

```bash
export DENA_RECOVERY_CODE='XXXX-XXXX-XXXX-XXXX'
bash scripts/dena/use-recovery-backup-code.sh
```

Ese script:

- valida que el código sea uno de los emitidos
- marca el código como usado
- aplica el mismo código como password temporal de Keycloak
- deja un evento `backup_code_consumed` en `dena.recovery_event`

### 6. Forzar El Reenrolado

La idea operativa es que el usuario vuelva a terminar con passkey nueva.

Haz que el siguiente acceso obligue a:

- cambiar la password temporal si la consola lo pide
- registrar de nuevo WebAuthn/passkey

Si la UI no expone claramente la accion requerida, el criterio operativo es simple: la password temporal solo habilita una unica reentrada para volver a registrar una passkey.

### 7. Comunicar La Password Temporal

Entrega la password temporal por un canal seguro:

- llamada directa
- canal interno privado
- procedimiento equivalente que no deje historial en claro

No la dejes en correo, chat abierto o documentación publica.

### 8. Confirmar Que El Usuario Recupero El Acceso

El usuario debe volver a entrar en:

```text
http://localhost:30080/dena/admin-console
```

Y registrar una nueva passkey cuando el flujo OIDC se lo pida.

## Variante Por CLI

Si prefieres hacerlo por comandos, puedes usar `kcadm.sh` dentro del pod de Keycloak.

Autenticacion de ejemplo:

```bash
kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password "$(kubectl get secret keycloak-secret -n auth -o jsonpath='{.data.admin-password}' | base64 -d)"
```

Buscar el usuario:

```bash
kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh get users -r piloto \
  -q username=adminuser \
  --fields id,username \
  --format csv \
  --noquotes
```

Buscar credenciales:

```bash
kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh get users/<USER_ID>/credentials -r piloto
```

Asignar password temporal:

```bash
kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh set-password -r piloto \
  --username adminuser \
  --new-password 'Temporal-Use-Only-2026!' \
  --temporary=true
```

Generar y consumir códigos de respaldo de forma automatizada:

```bash
bash scripts/dena/generate-recovery-backup-codes.sh
export DENA_RECOVERY_CODE='XXXX-XXXX-XXXX-XXXX'
bash scripts/dena/use-recovery-backup-code.sh
```

Asignar el operador de recuperacion se automatiza con:

```bash
bash scripts/dena/apply-recovery-operator.sh
```

## Comandos De Verificacion

Comprobar que el operador existe:

```bash
kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh get users -r piloto \
  -q username=recovery-operator \
  --fields username,enabled \
  --format csv \
  --noquotes \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password "$(kubectl get secret keycloak-secret -n auth -o jsonpath='{.data.admin-password}' | base64 -d)"
```

Comprobar que tiene acceso a usuarios:

```bash
set -a
. /home/dietpi/dena-interop/.local/fase12-keycloak.env
set +a

kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh get users -r piloto \
  -q username=adminuser \
  --fields username \
  --format csv \
  --noquotes \
  --server http://localhost:8080 \
  --realm piloto \
  --user recovery-operator \
  --password "$TF_VAR_recovery_operator_password"
```

Consultar el registro de recuperaciones:

```bash
kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)" \
  psql -U postgres -d datalake -c "
    select id, realm, username, event_type, operator_username, created_at
    from dena.recovery_event
    order by created_at desc
    limit 20;
  "
```

## Riesgos Y Criterio Operativo

- La password temporal debe expirar o dejar de ser util cuanto antes.
- La passkey vieja debe revocarse si hay sospecha de perdida fisica.
- El operador de recuperacion no debe convertirse en el camino normal de acceso.
- El acceso normal del admin debe volver a ser WebAuthn.
- Los backup codes deben entregarse y custodiarse como credenciales, no como documentación.

## Dónde Encaja En El Repo

Esta guia complementa:

- [Keycloak](../herramientas/keycloak.md)
- [Consola admin DENA](../herramientas/consola-admin-dena.md)
- [Runbook operativo](runbook.md)
- [Guia completa de instalacion](../guias/guia-instalacion.md)
