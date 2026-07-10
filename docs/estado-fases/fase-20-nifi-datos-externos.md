# Fase 20: NiFi hacia datos externos DENA

## Objetivo

Provisionar el flujo NiFi incremental que replica cambios desde `verticales` hacia el modelo enriquecido de `datos-externos`.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/provision-fase20-datos-externos-nifi.sh
bash scripts/verify-fase20-datos-externos-nifi.sh
```

## Que hace cada parte

- `provision-fase20-datos-externos-nifi.sh`: crea el grupo NiFi `Fase 20 - DENA datos externos incremental`.
- El flujo lee cambios de `verticales.expedientes.admin_file`.
- El flujo escribe en staging y aplica enriquecimiento en `datos-externos`.
- `verify-fase20-datos-externos-nifi.sh`: valida procesadores, controladores, schedule y resultado funcional.

## Verificacion

```bash
bash scripts/verify-fase20-datos-externos-nifi.sh
```

## Referencias

- [Historico fase 20](historico/estado-fases-0-20.md)
- [Guia Fase 20](../guias/fase20-nifi-datos-externos.md)
