# Fase 11c: NiFi JDBC incremental

## Objetivo

Provisionar el flujo NiFi que lee cambios desde `verticales.expedientes.admin_file` y los lleva al staging del datalake.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/install-nifi-postgresql-driver.sh
bash scripts/dena/provision-fase15-nifi.sh
bash scripts/verify-fase15-nifi.sh
```

## Que hace cada parte

- `install-nifi-postgresql-driver.sh`: garantiza que NiFi tiene el driver PostgreSQL.
- `provision-fase15-nifi.sh`: crea o reconcilia el grupo NiFi `Fase 15 - DENA staging incremental`.
- `verify-fase15-nifi.sh`: comprueba controladores, procesadores, conexiones y estado del flujo.

## Verificacion

```bash
bash scripts/verify-fase15-nifi.sh
```

Debe terminar sin procesadores invalidos ni conexiones duplicadas.

## Referencias

- [Flujo NiFi JDBC](../guias/fase12-nifi-jdbc.md)
- [Historico 0-11b](historico/estado-fases-0-11b.md)
