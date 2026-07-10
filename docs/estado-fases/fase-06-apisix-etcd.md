# Fase 6: APISIX y etcd

## Objetivo

Instalar APISIX como gateway de entrada HTTP y su etcd embebido en el namespace `gateway`.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
GODEBUG=http2client=0 helm repo add apiseven https://apache.github.io/apisix-helm-chart --force-update
GODEBUG=http2client=0 helm repo update
GODEBUG=http2client=0 helm pull apiseven/apisix --version 2.14.1 --destination /tmp
helm upgrade --install apisix /tmp/apisix-2.14.1.tgz -n gateway --values helm-values/apisix-values.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=etcd -n gateway --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=apisix -n gateway --timeout=300s
curl -i http://192.168.56.15:30080/
```

## Que hace cada parte

- `helm repo add apiseven`: registra el repo Helm de APISIX.
- `GODEBUG=http2client=0`: evita problemas de HTTP/2 vistos en algunas redes.
- `helm pull`: descarga el chart validado.
- `helm upgrade --install`: instala APISIX y etcd.
- `--values helm-values/apisix-values.yaml`: usa NodePort `30080` y configuracion local.
- `kubectl wait`: espera a etcd y APISIX.
- `curl`: comprueba que el gateway responde.

## Verificacion

```bash
kubectl get pods,svc -n gateway -o wide
curl -i http://192.168.56.15:30080/
```

En esta fase es normal no tener rutas funcionales todavia.

## Referencias

- [Historico 0-6](historico/estado-fases-0-6.md)
- [Valores APISIX](../../helm-values/apisix-values.yaml)
