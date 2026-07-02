# etcd

## Que Es

etcd es una base de datos clave-valor distribuida. En Kubernetes suele usarse como almacenamiento del estado del cluster. En este piloto aparece como componente interno del chart de APISIX.

## Objetivo En Este Piloto

APISIX usa etcd para guardar su configuracion:

- Upstreams.
- Rutas.
- Plugins.
- Estado de configuracion del gateway.

Cuando `scripts/dena/apply-route.sh` crea rutas con la Admin API de APISIX, esa configuracion queda persistida en etcd.

## Donde Esta

- Namespace: `gateway`
- StatefulSet: `apisix-etcd`
- Service: `apisix-etcd`
- PVC: `data-apisix-etcd-0`

## Como Se Usa

No se usa directamente en operacion normal. APISIX escribe y lee de etcd internamente.

Ver estado:

```bash
kubectl get statefulset,pod,pvc -n gateway -l app.kubernetes.io/name=etcd
kubectl logs -n gateway statefulset/apisix-etcd --tail=80
```

## Que Contiene En Este Caso

Contiene la configuracion activa de APISIX:

- Ruta `/api/*`.
- Ruta `/dena/admin-files`.
- Rutas de Keycloak.
- Fallback de la SPA.
- Upstreams de PostgREST, Keycloak y SPA.

## Como Verificarlo

```bash
kubectl rollout status statefulset/apisix-etcd -n gateway --timeout=180s
bash scripts/dena/apply-route.sh
bash scripts/verify-fase13.sh
```

## Por Que Se Usa

Porque APISIX necesita un almacen persistente para su configuracion dinamica. Sin etcd, las rutas del gateway no se mantienen.
