# Estado Fases 0-6

Fecha: 2026-06-16

## Resumen

El clúster queda alineado hasta Fase 6 de la guía:

- Fase 0: DietPi preparado para k3s.
- Fase 1: k3s activo sin Traefik ni servicelb.
- Fase 2: tooling local operativo con kubeconfig dedicado.
- Fase 3: namespaces de la guía creados.
- Fase 4: PostgreSQL de `auth` instalado con Helm.
- Fase 5: Keycloak desplegado con imagen oficial.
- Fase 6: APISIX + etcd instalado con Helm y NodePort `30080`.

## Fase 2 - Helm y red corporativa

Repos Helm configurados:

- `bitnami`: `https://repo.broadcom.com/bitnami-files`
- `apiseven`: `https://apache.github.io/apisix-helm-chart`
- `prometheus-community`: `https://prometheus-community.github.io/helm-charts`
- `grafana`: `https://grafana.github.io/helm-charts`
- `open-telemetry`: `https://open-telemetry.github.io/opentelemetry-helm-charts`

Notas de red:

- Usar `GODEBUG=http2client=0` para operaciones Helm contra repos externos.
- `helm repo update` no soporta `--insecure-skip-tls-verify` para repositorios, solo para el API server de Kubernetes.
- `charts.apiseven.com` corta la conexión; el índice Apache de APISIX funciona y conserva el chart `apiseven/apisix`.
- Los charts Bitnami actuales descargan desde OCI/Docker Hub; en esta red falla el token anónimo con `403 Forbidden`.

## Fase 4 - PostgreSQL auth

Release Helm:

- Nombre: `postgresql`
- Namespace: `auth`
- Chart: `postgresql-16.2.1`
- App: `17.1.0`
- Values: `helm-values/postgresql-values.yaml`

Decision operativa:

- Se usa `bitnami/postgresql` versión `16.2.1` porque descarga como `.tgz` clásico.
- Se sustituye la imagen por `docker.io/bitnamilegacy/postgresql:17.1.0-debian-12-r0`, ya que `docker.io/bitnami/postgresql:17.1.0-debian-12-r0` fue retirado.
- PVC local-path: `data-postgresql-0`, `4Gi`.

Validación realizada:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n auth --timeout=180s
kubectl exec -n auth postgresql-0 -- env PGPASSWORD='<secret>' psql -U keycloak -d keycloak -c 'select 1;'
```

Resultado SQL:

```text
?column?
----------
1
```

## Fase 5 - Keycloak

Manifiesto:

- `k8s-manifests/keycloak-deployment.yaml`

Recursos:

- Deployment: `keycloak`
- Service: `keycloak`
- Namespace: `auth`
- Imagen: `quay.io/keycloak/keycloak:26.0`
- Base de datos: `postgresql.auth.svc.cluster.local:5432/keycloak`

Secret:

- `keycloak-secret`
- Usuario admin: `admin`
- La password admin está en `.local/fase4-6.env`, archivo ignorado por Git.

Validación realizada:

```bash
kubectl wait --for=condition=ready pod -l app=keycloak -n auth --timeout=360s
kubectl exec -n auth deploy/keycloak -- /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password '<secret>'
```

## Fase 6 - APISIX + etcd

Release Helm:

- Nombre: `apisix`
- Namespace: `gateway`
- Chart: `apisix-2.14.1`
- App: `3.16.0`
- Values: `helm-values/apisix-values.yaml`

Recursos:

- Deployment: `apisix`
- StatefulSet: `apisix-etcd`
- Service Gateway: `apisix-gateway`
- Service Admin: `apisix-admin`
- PVC local-path: `data-apisix-etcd-0`, `4Gi`

Exposicion:

- `apisix-gateway`: `NodePort`
- HTTP: `80:30080/TCP`
- URL esperada: `http://192.168.56.15:30080`

Admin API:

- Admin key: `edd1c9f034335f136f87ad84b625c8f1`
- Viewer key: default del chart.
- Admin Service: `apisix-admin.gateway.svc.cluster.local:9180`

Validaciones realizadas:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=etcd -n gateway --timeout=240s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=apisix -n gateway --timeout=240s
curl -i --max-time 10 http://192.168.56.15:30080
kubectl run apisix-admin-check --rm -i --restart=Never --image=nginx:alpine -n gateway -- wget -qO- --header='X-API-KEY: <admin-key>' http://apisix-admin.gateway.svc.cluster.local:9180/apisix/admin/routes
```

Resultado Gateway:

```text
HTTP/1.1 404 Not Found
Server: APISIX/3.16.0
{"error_msg":"404 Route Not Found"}
```

Resultado Admin API:

```json
{"list":[],"total":0}
```

## Estado final

Releases Helm:

```text
apisix      gateway   deployed   apisix-2.14.1       3.16.0
postgresql  auth      deployed   postgresql-16.2.1   17.1.0
```

Namespaces de aplicación:

- `auth`: PostgreSQL + Keycloak.
- `gateway`: APISIX + etcd.
- `app`, `monitoring`, `datalake`, `verticales`: creados, sin workloads de fases posteriores.

## Comandos rápidos de comprobación

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config

kubectl get nodes -o wide
kubectl get pods,svc,pvc -n auth -o wide
kubectl get pods,svc,pvc -n gateway -o wide
helm list -A
curl -i http://192.168.56.15:30080
```

