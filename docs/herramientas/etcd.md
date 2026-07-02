# etcd

## Qué Es

etcd es una base de datos clave-valor distribuida. En Kubernetes suele usarse como almacenamiento del estado del clúster. En este piloto aparece como componente interno del chart de APISIX.

## Objetivo En Este Piloto

APISIX usa etcd para guardar su configuración:

- Upstreams.
- Rutas.
- Plugins.
- Estado de configuración del gateway.

Cuando `scripts/dena/apply-route.sh` crea rutas con la Admin API de APISIX, esa configuración queda persistida en etcd.

## Dónde Está

- Namespace: `gateway`
- StatefulSet: `apisix-etcd`
- Service: `apisix-etcd`
- PVC: `data-apisix-etcd-0`

## Cómo Se Usa

No se usa directamente en operación normal. APISIX escribe y lee de etcd internamente.

Ver estado:

```bash
kubectl get statefulset,pod,pvc -n gateway -l app.kubernetes.io/name=etcd
kubectl logs -n gateway statefulset/apisix-etcd --tail=80
```

## Qué Contiene En Este Caso

Contiene la configuración activa de APISIX:

- Ruta `/api/*`.
- Ruta `/dena/admin-files`.
- Rutas de Keycloak.
- Fallback de la SPA.
- Upstreams de PostgREST, Keycloak y SPA.

## Cómo Verificarlo

```bash
kubectl rollout status statefulset/apisix-etcd -n gateway --timeout=180s
bash scripts/dena/apply-route.sh
bash scripts/verify-fase13.sh
```

## Por Qué Se Usa

Porque APISIX necesita un almacén persistente para su configuración dinámica. Sin etcd, las rutas del gateway no se mantienen.
