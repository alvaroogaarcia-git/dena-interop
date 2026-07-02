# Runbook Operativo

## Arranque

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/wait-ready.sh
bash scripts/verify-stack.sh
```

## Apagado Controlado

Desde la máquina de operador:

```bash
ssh dena 'bash -s -- --poweroff' < scripts/stop-stack.sh
```

Sin apagar la VM:

```bash
ssh dena 'bash -s' < scripts/stop-stack.sh
```

## Recuperación Rápida Tras Reinicio

```bash
sudo systemctl restart k3s
bash scripts/wait-ready.sh
bash scripts/verify-stack.sh
```

Si aparecen pods en `Unknown` o `CreateContainerError` tras una caída de runtime:

```bash
kubectl get pods -A
kubectl delete pod -n <namespace> <pod>
```

No borres PVCs salvo que quieras eliminar datos persistentes.

## Portainer Vacio

Si al entrar en Portainer no aparece ningún entorno:

```bash
bash scripts/dena/init-portainer.sh
```

El script debe terminar con una salida similar a:

```text
Environment Kubernetes local ya existe en Portainer (id=1).
Portainer ve el cluster: namespaces=11 deployments=16.
```

En la UI abre `Environments` y selecciona `local`.

## Riesgos Operativos

- R1: credenciales demo en claro. Solo válido para piloto.
- R2: APISIX Admin API no debe exponerse fuera del port-forward.
- R3: Portainer usa `cluster-admin`; limitar o retirar antes de producción.
- R4: Prometheus usa retención local; acotar PVC/retentionSize en producción.
- R5: NiFi 2.x exige acceso por port-forward por validación de Host.
- R6: Terraform state contiene secretos y queda excluido de Git.
- R7: en VirtualBox el VDI crece y no encoge automáticamente; compactar con la VM apagada si el host se queda sin espacio.
