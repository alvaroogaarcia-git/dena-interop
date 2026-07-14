# Fase 16: SPA ciudadana

## Objetivo

Servir la SPA ciudadana con NGINX en el namespace `app` y publicarla por APISIX como fallback de `/`.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
kubectl apply -f k8s-manifests/dena-interop-spa.yaml
kubectl rollout status deployment/dena-interop-spa -n app --timeout=240s
bash scripts/dena/apply-route.sh
curl -i http://192.168.56.15:30080/
```

## Que hace cada parte

- `dena-interop-spa.yaml`: crea ConfigMap, Deployment y Service de la SPA.
- `rollout status`: espera a que NGINX este sirviendo.
- `apply-route.sh`: actualiza upstreams y rutas de APISIX.
- `curl`: comprueba que APISIX publica la página.

## Verificación

```bash
kubectl get pods,svc -n app -l app=dena-interop-spa -o wide
curl -i http://192.168.56.15:30080/
```

## Referencias

- [Histórico 0-17](historico/estado-fases-0-17.md)
- [SPA cliente](../herramientas/spa-cliente-dena.md)
