# Fase 3: namespaces

## Objetivo

Crear los namespaces Kubernetes usados por el piloto.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
for ns in auth gateway app monitoring datalake verticales portainer; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
kubectl get ns
```

## Que hace cada parte

- `export KUBECONFIG`: selecciona el cluster local.
- `for ns in ...`: recorre todos los namespaces requeridos.
- `kubectl create namespace --dry-run=client -o yaml`: genera el YAML sin crearlo directamente.
- `kubectl apply -f -`: aplica el YAML de forma idempotente.
- `kubectl get ns`: lista los namespaces creados.

## Verificacion

```bash
kubectl get ns auth gateway app monitoring datalake verticales portainer
```

Todos deben aparecer con estado `Active`.

## Referencias

- [Historico 0-3](historico/estado-fases-0-3.md)
