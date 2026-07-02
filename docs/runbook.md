# Runbook Operativo

## Arranque

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/wait-ready.sh
bash scripts/verify-stack.sh
```

## Apagado Controlado

Desde la maquina de operador:

```bash
ssh dena 'bash -s -- --poweroff' < scripts/stop-stack.sh
```

Sin apagar la VM:

```bash
ssh dena 'bash -s' < scripts/stop-stack.sh
```

## Recuperacion Rapida Tras Reinicio

```bash
sudo systemctl restart k3s
bash scripts/wait-ready.sh
bash scripts/verify-stack.sh
```

Si aparecen pods en `Unknown` o `CreateContainerError` tras una caida de runtime:

```bash
kubectl get pods -A
kubectl delete pod -n <namespace> <pod>
```

No borres PVCs salvo que quieras eliminar datos persistentes.

## Riesgos Operativos

- R1: credenciales demo en claro. Solo valido para piloto.
- R2: APISIX Admin API no debe exponerse fuera del port-forward.
- R3: Portainer usa `cluster-admin`; limitar o retirar antes de produccion.
- R4: Prometheus usa retencion local; acotar PVC/retentionSize en produccion.
- R5: NiFi 2.x exige acceso por port-forward por validacion de Host.
- R6: Terraform state contiene secretos y queda excluido de Git.
- R7: en VirtualBox el VDI crece y no encoge automaticamente; compactar con la VM apagada si el host se queda sin espacio.
