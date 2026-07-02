# Guía completa de instalación

Esta guía reconstruye el estado validado hasta Fase 17 de `dena-interop` sobre un nodo único DietPi x86_64 con k3s, Helm y Terraform.

El objetivo es que una persona con conocimientos mínimos de Linux, Kubernetes y terminal pueda repetir la instalación sin depender de pasos implícitos.

Para entender qué hace cada herramienta antes de instalarla, consulta `docs/herramientas/README.md`.

## 0. Supuestos del entorno

Valores usados en el laboratorio validado:

| Elemento | Valor |
| --- | --- |
| Servidor DietPi | `root@192.168.56.15` |
| Alias SSH | `dena` |
| Nodo k3s | `dietpi` |
| Kubeconfig local | `~/.kube/dena-config` |
| Workspace | `/home/dietpi/dena-interop` |
| Gateway APISIX | `http://192.168.56.15:30080` |
| Namespace auth | `auth` |
| Namespace gateway | `gateway` |

Convención de comandos:

- `Servidor`: comando ejecutado dentro de la VM DietPi.
- `Local`: comando ejecutado en la máquina de operador.
- En este laboratorio, Codex opera desde `/home/dietpi`, que actúa como máquina de operador local contra el API server de k3s.

## 1. Requisitos previos

Necesitas:

- Acceso SSH al servidor DietPi.
- Permisos para instalar paquetes en DietPi.
- `kubectl`, `helm` y `terraform` en la máquina de operador.
- Acceso al repositorio del proyecto.
- Red capaz de resolver GitHub, Broadcom/Bitnami y Apache GitHub Pages.

La red corporativa validada hace inspección SSL/TLS. En este entorno se han aplicado estas reglas:

- Usar `GODEBUG=http2client=0` en operaciones Helm contra repos externos.
- Registrar `bitnami` contra `https://repo.broadcom.com/bitnami-files`.
- Registrar `apiseven` contra `https://apache.github.io/apisix-helm-chart`.
- Evitar charts Bitnami modernos que descargan desde OCI/Docker Hub cuando el proxy bloquea tokens anónimos.

## 2. Secretos locales

No guardes secretos en Git.

En `Local`, dentro del repo:

```bash
cd /home/dietpi/dena-interop
mkdir -p .local
chmod 700 .local

cat > .local/fase4-6.env <<EOF
TF_VAR_postgres_password='v3OYOpRXwCZPAK1pkvUxPvLA'
TF_VAR_postgres_replication_password='$(openssl rand -base64 24)'
TF_VAR_keycloak_admin_password='BVi8R13yKt04fE+/nWIwYcSxVpoIXZPw'
TF_VAR_apisix_admin_key='edd1c9f034335f136f87ad84b625c8f1'
EOF

chmod 600 .local/fase4-6.env
set -a
. .local/fase4-6.env
set +a
```

Comprueba que `.gitignore` contiene `.local/`.

Secretos demo usados por la plataforma validada:

| Variable / secreto | Uso | Valor demo |
| --- | --- | --- |
| `TF_VAR_postgres_password` | PostgreSQL de Keycloak | `v3OYOpRXwCZPAK1pkvUxPvLA` |
| `TF_VAR_keycloak_admin_password` | Admin de Keycloak | `BVi8R13yKt04fE+/nWIwYcSxVpoIXZPw` |
| `TF_VAR_apisix_admin_key` | Admin API de APISIX | `edd1c9f034335f136f87ad84b625c8f1` |
| `TF_VAR_grafana_admin_password` | Admin de Grafana | `hLgdC1Azsa0V7XUUhF9P8NyQEVSQyDpJ` |
| `TF_VAR_postgrest_db_password` | Rol `postgrest` en datalake | usar el valor de `terraform/terraform.tfvars` o generar uno nuevo |
| `VERTICALES_DB_PASSWORD` | PostgreSQL del namespace `verticales` | `pyZN2eJRnVfArOgFltoTlotN` |
| `NIFI_SINGLE_USER_PASSWORD` | Usuario single-user de NiFi | `dsjB2qGE9CW41rvzv8g0` |
| `DENA_TESTUSER_PASSWORD` | Usuario OIDC `testuser` | `Test1234!` |
| `PORTAINER_ADMIN_PASSWORD` | Admin de Portainer | `T]8zJMh3U:ADu@L` |

Recomendacion local:

```bash
cat > .local/demo.env <<'EOF'
TF_VAR_postgres_password='v3OYOpRXwCZPAK1pkvUxPvLA'
TF_VAR_postgres_replication_password='cambiar-en-cada-instalacion'
TF_VAR_keycloak_admin_password='BVi8R13yKt04fE+/nWIwYcSxVpoIXZPw'
TF_VAR_apisix_admin_key='edd1c9f034335f136f87ad84b625c8f1'
TF_VAR_grafana_admin_password='hLgdC1Azsa0V7XUUhF9P8NyQEVSQyDpJ'
TF_VAR_postgrest_db_password='cambiar-en-cada-instalacion'
VERTICALES_DB_PASSWORD='pyZN2eJRnVfArOgFltoTlotN'
NIFI_SINGLE_USER_PASSWORD='dsjB2qGE9CW41rvzv8g0'
DENA_TESTUSER_PASSWORD='Test1234!'
PORTAINER_ADMIN_PASSWORD='T]8zJMh3U:ADu@L'
EOF
chmod 600 .local/demo.env
```

Para una instalación nueva que no sea demo, genera valores nuevos con `openssl rand -base64 24` y no reutilices las credenciales anteriores.

## 3. Fase 0 - Preparar DietPi

En `Servidor`:

```bash
ssh dena "dietpi-update"
ssh dena "apt-get install -y curl wget git open-iscsi nfs-common iptables"
ssh dena "swapoff -a && sed -i '/swap/d' /etc/fstab"
```

Persistir módulos requeridos por k3s:

```bash
ssh dena "cat >/etc/modules-load.d/k3s.conf <<'EOF'
overlay
br_netfilter
EOF"

ssh dena "modprobe overlay && modprobe br_netfilter"
```

Persistir sysctl:

```bash
ssh dena "cat >/etc/sysctl.d/99-k3s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF"

ssh dena "sysctl --system"
```

Verificación:

```bash
ssh dena "lsmod | grep -E 'overlay|br_netfilter'"
ssh dena "sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward"
ssh dena "swapon --show"
```

Resultado esperado:

- `overlay` y `br_netfilter` aparecen cargados.
- `net.bridge.bridge-nf-call-iptables = 1`.
- `net.ipv4.ip_forward = 1`.
- `swapon --show` no muestra swap activo.

## 4. Fase 1 - Instalar k3s con DietPi

En `Servidor`, configurar k3s como server y desactivar Traefik/servicelb:

```bash
ssh dena "grep -q '^SOFTWARE_K3S_EXEC=' /boot/dietpi.txt \
  && sed -i 's/^SOFTWARE_K3S_EXEC=.*/SOFTWARE_K3S_EXEC=server/' /boot/dietpi.txt \
  || echo 'SOFTWARE_K3S_EXEC=server' >> /boot/dietpi.txt"
```

Crear configuración k3s:

```bash
ssh dena "cat >/boot/dietpi-k3s.yaml <<'EOF'
write-kubeconfig-mode: \"0644\"
disable:
  - traefik
  - servicelb
tls-san:
  - \"192.168.56.15\"
EOF"
```

Instalar k3s con DietPi. En DietPi v10+ el ID correcto de k3s es `193`:

```bash
ssh dena "/boot/dietpi/dietpi-software install 193"
```

Si k3s ya existía, asegúrate de que `/etc/rancher/k3s/config.yaml` coincide:

```bash
ssh dena "cat >/etc/rancher/k3s/config.yaml <<'EOF'
write-kubeconfig-mode: \"0644\"
disable:
  - traefik
  - servicelb
tls-san:
  - \"192.168.56.15\"
EOF"

ssh dena "systemctl restart k3s"
```

Verificación:

```bash
ssh dena "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl wait --for=condition=Ready node --all --timeout=120s"
ssh dena "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes -o wide"
ssh dena "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get all -n kube-system"
```

Resultado esperado:

- Un nodo `Ready`.
- No hay pods ni servicios de Traefik.
- No hay `servicelb`.

Si Traefik aparece como HelmChart de k3s, eliminarlo:

```bash
ssh dena "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl delete helmcharts.helm.cattle.io traefik traefik-crd -n kube-system --ignore-not-found"
```

## 5. Fase 2 - Tooling local y kubeconfig

En `Local`, copiar kubeconfig:

```bash
mkdir -p ~/.kube
scp dena:/etc/rancher/k3s/k3s.yaml ~/.kube/dena-config
chmod 600 ~/.kube/dena-config
sed -i 's|https://127.0.0.1:6443|https://192.168.56.15:6443|' ~/.kube/dena-config

grep -q 'KUBECONFIG=.*/dena-config' ~/.bashrc \
  || echo 'export KUBECONFIG=~/.kube/dena-config' >> ~/.bashrc

export KUBECONFIG=~/.kube/dena-config
```

Verificar herramientas:

```bash
kubectl version --client
helm version
terraform version
kubectl get nodes -o wide
```

Registrar repos Helm:

```bash
GODEBUG=http2client=0 helm repo add bitnami https://repo.broadcom.com/bitnami-files --force-update --insecure-skip-tls-verify
GODEBUG=http2client=0 helm repo add apiseven https://apache.github.io/apisix-helm-chart --force-update --insecure-skip-tls-verify
GODEBUG=http2client=0 helm repo add grafana https://grafana.github.io/helm-charts --force-update --insecure-skip-tls-verify
GODEBUG=http2client=0 helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update --insecure-skip-tls-verify
GODEBUG=http2client=0 helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update --insecure-skip-tls-verify

GODEBUG=http2client=0 helm repo update
helm repo list
```

Resultado esperado:

- `bitnami`
- `apiseven`
- `grafana`
- `prometheus-community`
- `open-telemetry`

Nota: `helm repo update` no tiene flag `--insecure-skip-tls-verify` para repositorios; el flag existente aplica al API server de Kubernetes.

## 6. Fase 3 - Namespaces

En `Local`:

```bash
for ns in auth gateway app monitoring datalake verticales; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
```

Verificación:

```bash
kubectl get ns
```

Resultado esperado:

- `auth`
- `gateway`
- `app`
- `monitoring`
- `datalake`
- `verticales`

No usar `apps` en plural para esta guía. El namespace correcto hasta Fase 6 es `app`.

## 7. Fase 4 - PostgreSQL para Keycloak

### 7.1 Cargar secretos en shell

En `Local`:

```bash
cd /home/dietpi/dena-interop
set -a
. .local/fase4-6.env
set +a
```

### 7.2 Crear Secret de PostgreSQL

```bash
kubectl create secret generic postgresql-auth -n auth \
  --from-literal=postgres-password="$TF_VAR_postgres_password" \
  --from-literal=password="$TF_VAR_postgres_password" \
  --from-literal=replication-password="$TF_VAR_postgres_replication_password"
```

Si el secreto ya existe y quieres recrearlo:

```bash
kubectl delete secret postgresql-auth -n auth --ignore-not-found
```

Después repite el comando `kubectl create secret`.

### 7.3 Descargar chart PostgreSQL validado

El chart Bitnami actual descarga desde OCI/Docker Hub y en esta red falla con `403 Forbidden`.

Usar la versión validada `16.2.1`, que descarga como paquete `.tgz` clásico:

```bash
curl -kL --http1.1 --fail \
  --output /tmp/postgresql-16.2.1.tgz \
  https://charts.bitnami.com/bitnami/postgresql-16.2.1.tgz
```

Validar paquete:

```bash
tar -tzf /tmp/postgresql-16.2.1.tgz | head
```

### 7.4 Instalar PostgreSQL

```bash
helm install postgresql /tmp/postgresql-16.2.1.tgz \
  -n auth \
  --values helm-values/postgresql-values.yaml
```

Esperar readiness:

```bash
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=postgresql \
  -n auth \
  --timeout=180s
```

Validar SQL:

```bash
kubectl exec -n auth postgresql-0 -- \
  env PGPASSWORD="$TF_VAR_postgres_password" \
  psql -U keycloak -d keycloak -c 'select 1;'
```

Resultado esperado:

```text
?column?
----------
1
```

## 8. Fase 5 - Keycloak

### 8.1 Crear Secret de Keycloak

```bash
kubectl create secret generic keycloak-secret -n auth \
  --from-literal=db-password="$TF_VAR_postgres_password" \
  --from-literal=admin-password="$TF_VAR_keycloak_admin_password"
```

### 8.2 Aplicar manifiesto

```bash
kubectl apply -f k8s-manifests/keycloak-deployment.yaml
```

Esperar readiness:

```bash
kubectl wait --for=condition=ready pod \
  -l app=keycloak \
  -n auth \
  --timeout=360s
```

Validar login admin:

```bash
kubectl exec -n auth deploy/keycloak -- \
  /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password "$TF_VAR_keycloak_admin_password"
```

Resultado esperado:

```text
Logging into http://localhost:8080 as user admin of realm master
```

## 9. Fase 6 - APISIX + etcd

### 9.1 Descargar chart APISIX validado

```bash
GODEBUG=http2client=0 helm pull apiseven/apisix \
  --version 2.14.1 \
  --insecure-skip-tls-verify \
  --destination /tmp
```

Validar que el paquete contiene etcd:

```bash
tar -tzf /tmp/apisix-2.14.1.tgz | grep '^apisix/charts/etcd/' | head
```

### 9.2 Instalar APISIX

```bash
helm install apisix /tmp/apisix-2.14.1.tgz \
  -n gateway \
  --values helm-values/apisix-values.yaml
```

Esperar etcd:

```bash
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=etcd \
  -n gateway \
  --timeout=240s
```

Esperar APISIX:

```bash
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=apisix \
  -n gateway \
  --timeout=240s
```

Ver servicios:

```bash
kubectl get pods,svc,pvc -n gateway -o wide
```

Resultado esperado para el gateway:

```text
service/apisix-gateway   NodePort   ...   80:30080/TCP
```

### 9.3 Validar Gateway

```bash
curl -i --max-time 10 http://192.168.56.15:30080
```

Resultado esperado:

```text
HTTP/1.1 404 Not Found
Server: APISIX/3.16.0
{"error_msg":"404 Route Not Found"}
```

Este resultado es correcto en Fase 6: APISIX está levantado, pero todavía no hay rutas configuradas.

### 9.4 Validar Admin API

```bash
kubectl run apisix-admin-check \
  --rm -i \
  --restart=Never \
  --image=nginx:alpine \
  -n gateway \
  -- wget -qO- \
  --header="X-API-KEY: $TF_VAR_apisix_admin_key" \
  http://apisix-admin.gateway.svc.cluster.local:9180/apisix/admin/routes
```

Resultado esperado:

```json
{"list":[],"total":0}
```

## 10. Comprobación parcial de Fases 4-6

```bash
kubectl get nodes -o wide
kubectl get ns
kubectl get pods,svc,pvc -n auth -o wide
kubectl get pods,svc,pvc -n gateway -o wide
helm list -A
curl -i http://192.168.56.15:30080
```

Estado esperado:

- Nodo `dietpi` en `Ready`.
- Release Helm `postgresql` en namespace `auth`.
- Release Helm `apisix` en namespace `gateway`.
- Pods `postgresql-0`, `keycloak`, `apisix` y `apisix-etcd-0` en `Running`.
- PVCs `data-postgresql-0` y `data-apisix-etcd-0` en `Bound`.
- APISIX responde `404 Route Not Found` en `:30080`.

## 11. Fase 7 - Observabilidad local

Esta fase instala Prometheus/Grafana, Loki y Tempo en el namespace `monitoring`.

Versiones validadas:

| Release | Chart | App |
| --- | --- | --- |
| `monitoring` | `kube-prometheus-stack-86.2.3` | `v0.91.0` |
| `loki` | `loki-7.0.0` | `3.6.7` |
| `tempo` | `tempo-1.24.4` | `2.9.0` |

### 11.1 Secret de Grafana

No guardes la password de Grafana en Git.

```bash
cd /home/dietpi/dena-interop

cat > .local/fase7.env <<EOF
TF_VAR_grafana_admin_password='hLgdC1Azsa0V7XUUhF9P8NyQEVSQyDpJ'
EOF

chmod 600 .local/fase7.env
set -a
. .local/fase7.env
set +a
```

Crear el Secret:

```bash
kubectl create secret generic grafana-admin -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$TF_VAR_grafana_admin_password"
```

### 11.2 Instalar kube-prometheus-stack

```bash
GODEBUG=http2client=0 helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --version 86.2.3 \
  --values helm-values/monitoring-values.yaml \
  --insecure-skip-tls-verify \
  --wait \
  --timeout 10m
```

Notas:

- Grafana queda publicado en `NodePort 31803`.
- Alertmanager queda desactivado para reducir consumo local.
- Prometheus usa `emptyDir`, retención `7d` y sin `retentionSize`.
- Para producción, define `retentionSize` y un PVC acotado.

### 11.3 Instalar Loki v7

```bash
GODEBUG=http2client=0 helm install loki grafana/loki \
  -n monitoring \
  --version 7.0.0 \
  --values helm-values/loki-values.yaml \
  --insecure-skip-tls-verify \
  --wait \
  --timeout 10m
```

Configuración validada:

- `deploymentMode: SingleBinary`
- `singleBinary.replicas: 1`
- `read.replicas: 0`
- `write.replicas: 0`
- `backend.replicas: 0`
- `chunksCache.enabled: false`
- `resultsCache.enabled: false`
- PVC local-path `4Gi`.

### 11.4 Instalar Tempo

```bash
GODEBUG=http2client=0 helm install tempo grafana/tempo \
  -n monitoring \
  --version 1.24.4 \
  --values helm-values/tempo-values.yaml \
  --insecure-skip-tls-verify \
  --wait \
  --timeout 10m
```

Configuración validada:

- Tempo local sin PVC.
- OTLP gRPC `4317`.
- OTLP HTTP `4318`.
- Readiness HTTP en `3200`.

### 11.5 Verificación de Fase 7

```bash
kubectl get pods,svc,pvc -n monitoring -o wide
helm list -n monitoring
curl -i http://192.168.56.15:31803/login
```

Validar endpoints internos:

```bash
kubectl run loki-check --rm -i --restart=Never --image=nginx:alpine -n monitoring -- \
  wget -qO- http://loki.monitoring.svc.cluster.local:3100/ready

kubectl run tempo-check --rm -i --restart=Never --image=nginx:alpine -n monitoring -- \
  wget -qO- http://tempo.monitoring.svc.cluster.local:3200/ready

kubectl run prometheus-check --rm -i --restart=Never --image=nginx:alpine -n monitoring -- \
  wget -qO- http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/-/ready
```

Resultados esperados:

- Grafana `/login` devuelve `HTTP/1.1 200 OK`.
- Loki devuelve `ready`.
- Tempo devuelve `ready`.
- Prometheus devuelve `Prometheus Server is Ready.`

Validar datasources de Grafana:

```bash
curl -s -u "admin:$TF_VAR_grafana_admin_password" \
  http://192.168.56.15:31803/api/datasources
```

Datasources esperados:

- `Prometheus`
- `Loki`
- `Tempo`

## Fase 8 - OTel Collector

La Fase 8 instala el OpenTelemetry Collector como `DaemonSet` en `monitoring`. Recoge señales del nodo y deja listas las pipelines de métricas, logs y trazas hacia Prometheus, Loki y Tempo.

### Preflight

```bash
bash scripts/preflight-fase8.sh
```

Si el preflight indica workloads no listos, recupera primero la Fase 7:

```bash
bash scripts/recover-fase7.sh
```

### Instalación

```bash
GODEBUG=http2client=0 helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  -n monitoring \
  --version 0.158.2 \
  --values helm-values/otel-collector-values.yaml \
  --wait \
  --timeout 10m
```

### Verificación

```bash
kubectl rollout status daemonset/otel-collector-opentelemetry-collector-agent -n monitoring --timeout=240s
kubectl get daemonset,svc,servicemonitor -n monitoring | grep otel
kubectl logs -n monitoring daemonset/otel-collector-opentelemetry-collector-agent --tail=80
```

Resultado esperado:

- DaemonSet `otel-collector-opentelemetry-collector-agent` con `1/1`.
- Service `otel-collector-opentelemetry-collector`.
- Pipeline de métricas expuesta para Prometheus.
- Logs sin errores de exportacion hacia Loki/Tempo.

## Fase 9 - PostgreSQL del datalake

La Fase 9 despliega la base `datalake`, que es el destino consolidado de los datos sincronizados y la base que PostgREST expone como API interna.

### Instalación

```bash
helm upgrade --install postgresql-datalake bitnami/postgresql \
  -n datalake \
  --version 18.7.5 \
  --values helm-values/postgresql-datalake-values.yaml \
  --wait \
  --timeout 10m
```

Si la red bloquea el chart remoto, descarga el `.tgz` previamente y usa la ruta local igual que en Fase 4.

### Verificación

```bash
kubectl rollout status statefulset/postgresql-datalake -n datalake --timeout=180s
kubectl get pods,svc,pvc -n datalake -o wide

PG="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$PG" \
  psql -U postgres -d datalake -c 'select current_database();'
```

Resultado esperado:

- `postgresql-datalake-0` en `Running`.
- PVC `data-postgresql-datalake-0` en `Bound`.
- La consulta devuelve `datalake`.

## Fase 10 - PostgREST

La Fase 10 instala PostgREST sobre PostgreSQL datalake. PostgREST no se expone directamente fuera del clúster; APISIX lo publicara después bajo `/api/*` y `/dena/admin-files`.

### Roles SQL

Crear el rol autenticador `postgrest`, el rol anónimo `anon` y el permiso para asumirlo:

```bash
PG="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -i -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$PG" \
  psql -U postgres -d datalake \
  -v postgrest_db_password="$TF_VAR_postgrest_db_password" \
  < sql/00-postgrest-roles.sql
```

Validación esperada:

```bash
kubectl exec -n datalake postgresql-datalake-0 -- \
  env PGPASSWORD="$PG" \
  psql -U postgres -d datalake -Atc "
    select rolname || '|' || case when rolcanlogin then 't' else 'f' end
    from pg_roles
    where rolname in ('anon', 'postgrest')
    order by rolname;
    select pg_get_userbyid(member) || '->' || pg_get_userbyid(roleid)
    from pg_auth_members
    where pg_get_userbyid(member) = 'postgrest'
      and pg_get_userbyid(roleid) = 'anon';
  "
```

Salida esperada:

```text
anon|f
postgrest|t
postgrest->anon
```

### Secret y deployment

```bash
kubectl create secret generic postgrest-secret -n datalake \
  --from-literal=db-uri="postgres://postgrest:$TF_VAR_postgrest_db_password@postgresql-datalake.datalake.svc.cluster.local:5432/datalake" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f k8s-manifests/postgrest-deployment.yaml
kubectl rollout status deployment/postgrest -n datalake --timeout=180s
```

### Verificación

```bash
bash scripts/verify-fase10.sh
```

Resultado esperado:

- `postgresql-datalake` y `postgrest` están operativos.
- `postgrest-secret` apunta a `postgresql-datalake.datalake.svc.cluster.local`.
- Roles `anon` y `postgrest` existen.
- `postgrest` puede asumir `anon`.
- `GET /` sobre el servicio interno devuelve el documento OpenAPI.

## Anexo A - Reinstalacion controlada de Fases 4-7

Usar solo si quieres volver a instalar desde cero estas fases.

```bash
helm uninstall tempo -n monitoring --ignore-not-found
helm uninstall loki -n monitoring --ignore-not-found
helm uninstall monitoring -n monitoring --ignore-not-found
helm uninstall apisix -n gateway --ignore-not-found
kubectl delete -f k8s-manifests/keycloak-deployment.yaml --ignore-not-found
helm uninstall postgresql -n auth --ignore-not-found

kubectl delete secret grafana-admin -n monitoring --ignore-not-found
kubectl delete secret keycloak-secret postgresql-auth -n auth --ignore-not-found
```

Si quieres borrar también datos persistentes:

```bash
kubectl delete pvc storage-loki-0 -n monitoring --ignore-not-found
kubectl delete pvc data-apisix-etcd-0 -n gateway --ignore-not-found
kubectl delete pvc data-postgresql-0 -n auth --ignore-not-found
```

Aviso: borrar PVCs elimina datos locales de PostgreSQL, etcd y Loki.

## Anexo B - Troubleshooting

### Helm repo update funciona, pero Bitnami latest falla

Sintoma:

```text
failed to fetch anonymous token ... auth.docker.io ... 403 Forbidden
```

Causa:

- El índice Bitnami moderno publica charts por OCI.
- La red corporativa bloquea el token anónimo de Docker Hub.

Solucion validada:

- Usar `postgresql-16.2.1.tgz`.
- Instalar desde paquete local.
- Sustituir imagen por `bitnamilegacy/postgresql`, ya configurado en `helm-values/postgresql-values.yaml`.

### charts.apiseven.com corta la conexión

Sintoma:

```text
connection reset by peer
```

Solucion validada:

```bash
GODEBUG=http2client=0 helm repo add apiseven https://apache.github.io/apisix-helm-chart --force-update --insecure-skip-tls-verify
```

### Keycloak no arranca

Comandos útiles:

```bash
kubectl get pods -n auth
kubectl logs -n auth deploy/keycloak --tail=120
kubectl describe pod -n auth -l app=keycloak
```

Puntos a revisar:

- `postgresql-0` está `Ready`.
- `keycloak-secret` existe.
- `KC_DB_PASSWORD` coincide con el password del usuario `keycloak`.
- La base `keycloak` existe.

### APISIX no queda Ready

Comandos útiles:

```bash
kubectl get pods -n gateway
kubectl logs -n gateway statefulset/apisix-etcd --tail=120
kubectl logs -n gateway deploy/apisix --tail=120
kubectl describe pod -n gateway -l app.kubernetes.io/name=apisix
```

Puntos a revisar:

- `apisix-etcd-0` está `Ready`.
- El init container `wait-etcd` puede resolver `apisix-etcd.gateway.svc.cluster.local`.
- El servicio `apisix-gateway` mantiene `80:30080/TCP`.

## Anexo C - Política de commits

Recomendacion para seguimiento:

- Un commit por fase completada.
- Un commit por cambio de infraestructura estable.
- Un commit por bloque documental relevante.
- No mezclar secretos, kubeconfigs privados ni tokens en commits.

Formato recomendado:

```text
fase-N: descripción corta del cambio
docs: actualizar guía de instalación
infra: ajustar values de apisix
```

## Fase 11 - Apache NiFi 2.9

ADR-007: NiFi 2.x arranca seguro por defecto con HTTPS y single-user. En este laboratorio se valida una sola réplica en `datalake`, con `strategy: Recreate`, `NodePort 30821`, probes HTTPS con `Host: localhost:8443`, heap JVM `256m` y un PVC persistente para `extensions/`.

### 11.1 Secret de single-user

En `Local`:

```bash
NIFI_SINGLE_USER_PASSWORD='dsjB2qGE9CW41rvzv8g0'

kubectl create secret generic nifi-secret -n datalake \
  --from-literal=single-user-username=admin \
  --from-literal=single-user-password="$NIFI_SINGLE_USER_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 11.2 Despliegue

Opcional pero recomendado, pre-descargar la imagen en el nodo:

```bash
ssh dena "k3s crictl pull docker.io/apache/nifi:2.9.0"
```

Aplicar el manifiesto versionado:

```bash
kubectl apply -f k8s-manifests/nifi-deployment.yaml
kubectl wait --for=condition=available deployment/nifi -n datalake --timeout=300s
```

Recursos validados en este nodo:

- `requests.cpu: 100m`
- `requests.memory: 384Mi`
- `limits.memory: 1Gi`
- `NIFI_JVM_HEAP_INIT=256m`
- `NIFI_JVM_HEAP_MAX=256m`

### 11.3 Verificación de Fase 11

```bash
bash scripts/verify-fase11.sh
kubectl get pods,svc,pvc -n datalake -o wide
```

Resultados esperados:

- `deployment/nifi` en `Available`
- `service/nifi` publicado en `8443:30821/TCP`
- `pvc/nifi-extensions` en `Bound`
- el endpoint HTTPS interno devuelve `HTTP/1.1 200 OK`

### 11.4 Acceso de operador

El acceso validado para esta fase es por port-forward:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
```

Abrir:

```text
https://localhost:8443/nifi
```

Recuperar la password:

```bash
kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-password}' | base64 -d
```

Notas:

- El certificado es autofirmado.
- El NodePort directo `30821` no es la ruta de acceso validada en esta fase.
- En este nodo de `4 GiB`, NiFi se ha validado sin `startupProbe`; las sondas efectivas son `readiness` y `liveness` con tiempos amplios.
- El driver JDBC de PostgreSQL y el flujo NiFi quedan fuera de esta fase; pertenecen a la Fase 11b.

## Fase 11b - Verticales: PostgreSQL origen + Mathesar

ADR-008: la fuente del vertical deja de ser CSV/GetFile y pasa a ser PostgreSQL. La tabla `expedientes.admin_file` queda como fuente de verdad editable; Mathesar la expone por web y NiFi queda preparado para sincronización incremental usando `updated_at`.

### 11b.1 Driver JDBC de PostgreSQL en NiFi

El driver JDBC no viene en la imagen oficial de NiFi 2.9. Se copia al PVC persistente de `extensions/`:

```bash
bash scripts/dena/install-nifi-postgresql-driver.sh
```

Equivalente manual:

```bash
POD="$(kubectl get pod -n datalake -l app=nifi -o jsonpath='{.items[0].metadata.name}')"
curl -fsSLO https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.4/postgresql-42.7.4.jar
kubectl cp postgresql-42.7.4.jar datalake/"$POD":/opt/nifi/nifi-current/extensions/postgresql-42.7.4.jar -c nifi
```

### 11b.2 PostgreSQL de `verticales`

Desplegar un PostgreSQL dedicado al origen:

```bash
helm upgrade --install postgresql-verticales bitnami/postgresql --namespace verticales \
  --version 18.7.5 \
  -f helm-values/postgresql-verticales-values.yaml

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n verticales --timeout=180s
```

### 11b.3 Esquema origen + base interna de Mathesar

Crear la base interna de Mathesar, el esquema origen y la carga inicial:

```bash
PGV="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"

kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$PGV" \
  psql -U postgres -d postgres -c "SELECT 'CREATE DATABASE mathesar_django' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mathesar_django')\\gexec"

kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$PGV" \
  psql -U postgres -d expedientes < sql/verticales/01-expedientes-source.sql

kubectl exec -i -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$PGV" \
  psql -U postgres -d expedientes < sql/verticales/02-state-check.sql

bash scripts/dena/load-expedientes.sh
```

Estado esperado tras la carga:

- `expedientes.admin_file` contiene `50` filas
- existe índice por `updated_at`
- el `CHECK` de `status` queda aplicado

### 11b.4 Mathesar local

Crear el secret y desplegar Mathesar:

```bash
kubectl create secret generic mathesar-secret -n verticales \
  --from-literal=db-password="$PGV" \
  --from-literal=secret-key="$(openssl rand -base64 50)" \
  --dry-run=client -o yaml | kubectl apply -f -

ssh dena "k3s crictl pull docker.io/mathesar/mathesar:0.11.0"
kubectl apply -f k8s-manifests/mathesar-deployment.yaml
kubectl rollout status deployment/mathesar -n verticales --timeout=240s
```

Acceso de operador:

```text
http://192.168.56.15:30900
```

Notas:

- En el primer arranque hay que crear el usuario admin desde la UI.
- Dentro de Mathesar hay que añadir una conexión a `expedientes` usando:
  - host `postgresql-verticales.verticales.svc.cluster.local`
  - base `expedientes`
  - usuario `postgres`
- En esta imagen, `/healthz/ready/` no resulta estable en este entorno; las probes quedan por TCP sobre `:8000`.
- En este nodo de `4 GiB`, Mathesar queda ajustado a `WEB_CONCURRENCY=1` y `128Mi/256Mi` para poder convivir con NiFi.

### 11b.5 Verificación de Fase 11b

```bash
bash scripts/verify-fase11b.sh
kubectl get pods,svc,pvc -n verticales -o wide
```

Resultados esperados:

- `statefulset/postgresql-verticales` en `Ready`
- `deployment/mathesar` en `Available`
- `service/mathesar` publicado en `8000:30900/TCP`
- `expedientes.admin_file` con `50` filas
- `postgresql-42.7.4.jar` presente en `extensions/` de NiFi

### 11b.6 Nota de acceso a NiFi 2.x

NiFi 2.x sigue requiriendo que el `Host` coincida con una entrada válida en `NIFI_WEB_PROXY_HOST`. En este laboratorio se valida el acceso por `kubectl port-forward` y también por NodePort con el host publicado en el deployment:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
```

Y la UI:

```text
https://localhost:8443/nifi
```

## Fase 12 - NiFi JDBC incremental

ADR-009: el laboratorio pasa de dejar preparado el origen a materializar un flujo NiFi incremental contra `expedientes.admin_file`. El flujo queda versionado en este repositorio y usa el driver PostgreSQL persistido en el PVC de NiFi.

### 12.1 Estructura del flujo

- Grupo de proceso: `Fase 12 - JDBC incremental`
- Fuente: `QueryDatabaseTableRecord`
- Conexión JDBC: `Verticales DBCP`
- Writer: `JSON Record Writer`
- Nombres de fichero: `Stamp Output Filename`
- Destino: `Persist Fase 12 Output`

### 12.2 Provisionamiento

```bash
bash scripts/dena/install-nifi-postgresql-driver.sh
bash scripts/dena/provision-fase12-nifi.sh
```

El script:

1. abre automáticamente el `port-forward` de NiFi
2. obtiene credenciales desde `nifi-secret`
3. crea o reutiliza el grupo y los controller services
4. reconcilia propiedades con la API de NiFi 2.9
5. crea o reutiliza los tres procesadores
6. evita conexiones duplicadas
7. habilita y arranca el flujo

### 12.3 Verificación

```bash
bash scripts/verify-fase12.sh
```

La verificación comprueba:

- grupo de proceso presente
- procesadores en `VALID/RUNNING`
- controller services en `VALID/ENABLED`
- directorio de salida accesible
- driver JDBC presente en `extensions/`

### 12.4 Prueba incremental

Actualizar una fila de `expedientes.admin_file` y comprobar que aparece un nuevo JSON en la salida del flujo:

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
PG_PASS="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl exec -n verticales postgresql-verticales-0 -- \
  env PGPASSWORD="$PG_PASS" \
  psql -U postgres -d expedientes -c "update expedientes.admin_file set status = 'archivado', updated_at = now() where id = 1;"
```

### 12.5 Notas operativas

- Si el NodePort directo no responde, usar `kubectl port-forward -n datalake svc/nifi 8443:8443`.
- El flujo escribe en `/opt/nifi/nifi-current/extensions/fase12-output`.
- El directorio de salida vive dentro del PVC de NiFi, junto al driver JDBC.
- `flow.json.gz` vive en `/persistent/conf/flow.json.gz` dentro del mismo PVC.
- `NIFI_SENSITIVE_PROPS_KEY` usa el secreto de NiFi para conservar propiedades cifradas tras reinicios.
- El procedimiento de optimización y recuperación de k3s queda en `docs/optimizacion-k3s-4gb.md`.

## Fase 13 - Terraform y Keycloak

ADR-010: el realm piloto y sus identidades se gestionan con el provider oficial `keycloak/keycloak`. Terraform se conecta al servicio mediante un port-forward local y el estado, que contiene valores sensibles, queda excluido de Git.

Nota: algunos scripts conservan nombres históricos (`apply-fase12-keycloak.sh`, `verify-fase13.sh`, `apply-fase14-grafana.sh`, `apply-fase15-datalake.sh`). La fase correcta es la indicada por esta guía; los nombres de script se mantienen para no romper automatizaciones existentes.

Recursos gestionados:

- realm `piloto`
- cliente público `react-frontend` con Authorization Code y PKCE S256
- cliente confidencial `apisix-gateway`
- roles `dena-reader`, `dena-writer` y `dena-admin`
- usuario piloto `testuser`

Aplicación y verificación:

```bash
bash scripts/dena/apply-fase12-keycloak.sh
bash scripts/verify-fase12-keycloak.sh
```

El password demo de `testuser` es `Test1234!` salvo que se overridee con `DENA_TESTUSER_PASSWORD`. El secreto del cliente confidencial se copia al Secret `gateway/apisix-oidc` sin versionarlo.

## Fase 14 - APISIX OIDC e interoperabilidad DENA

ADR-011: APISIX es la única entrada HTTP. Keycloak conserva URL pública fija `http://192.168.56.15:30080`, PostgREST sigue como `ClusterIP` y las rutas de datos requieren un bearer token validado mediante introspección OIDC.

Antes de crear las rutas se aplica la función SQL y se sincronizan los 50 expedientes actuales:

```bash
bash scripts/dena/apply-dena-api.sh
bash scripts/dena/apply-route.sh
```

Recursos APISIX:

- upstream `1`: PostgREST en `postgrest.datalake.svc.cluster.local:3000`
- upstream `2`: Keycloak en `keycloak.auth.svc.cluster.local:8080`
- rutas públicas `/realms/*`, `/admin/*` y `/resources/*`
- ruta protegida `/api` y `/api/*`, con eliminacion del prefijo
- ruta protegida `POST /dena/admin-files`, reescrita a `/rpc/dena_data_retrieve`

Verificación completa:

```bash
bash scripts/verify-fase13.sh
```

La prueba valida discovery público, rechazo `401` sin token, emisión de token para `testuser`, acceso autorizado a `/api` y respuesta con expedientes reales desde `POST /dena/admin-files`.

## Fase 15 - Terraform y Grafana

ADR-012: Grafana se mantiene desplegado por Helm, pero su configuración funcional queda gestionada por Terraform mediante el provider oficial `grafana/grafana`. Terraform se conecta por port-forward local usando las credenciales del Secret `monitoring/grafana-admin`.

Recursos gestionados:

- datasources `Prometheus`, `Loki` y `Tempo`
- carpeta `DENA`
- dashboards `DENA Stack Overview` y `DENA PostgreSQL Overview`

Aplicación y verificación:

```bash
bash scripts/dena/apply-fase14-grafana.sh
bash scripts/verify-fase14.sh
```

El script actualiza primero el release `monitoring` para desactivar el provisioning read-only de datasources de Grafana. Después Terraform crea o actualiza datasources, carpeta y dashboards por API. Los dashboards viven en `terraform/dashboards/` y no dependen del sidecar de ConfigMaps para quedar reproducidos.

## Fase 16 - SQL del datalake y carga local

La Fase 16 consolida el esquema DENA del datalake y deja una carga reproducible hacia staging:

- tabla principal `dena.admin_file`
- vista camelCase `dena."adminFile"`
- RPC `public.dena_data_retrieve`
- staging `dena.admin_file_staging`
- función de promocion `dena.dena_staging_to_main()`

Aplicación y verificación:

```bash
bash scripts/dena/apply-fase15-datalake.sh
bash scripts/verify-fase15.sh
```

La carga manual del CSV se hace con:

```bash
bash scripts/dena/load-csv.sh --file expedientes.csv --promote
```

El detalle operativo queda en `docs/fase15-datalake.md`.

## Fase 17 - Cliente demo SPA

La SPA demo queda servida por NGINX en el namespace `app` y APISIX la publica como fallback de `/`.

Aplicación:

```bash
kubectl apply -f k8s-manifests/dena-interop-spa.yaml
kubectl rollout status deployment/dena-interop-spa -n app --timeout=180s
bash scripts/dena/apply-route.sh
```

Verificación:

```bash
curl -i http://192.168.56.15:30080/
bash scripts/dena/test-curl.sh
```

Resultado esperado:

- `/` devuelve `HTTP 200` con el cliente demo.
- El cliente obtiene token en `/realms/piloto` y consulta `POST /dena/admin-files`.

## Extra - Portainer

Portainer corre dentro de k3s con ServiceAccount `cluster-admin`. Es útil para inspección operativa, no para producción sin hardening.

Aplicación:

```bash
kubectl apply -f k8s-manifests/portainer-deployment.yaml
kubectl rollout status deployment/portainer -n portainer --timeout=180s
bash scripts/dena/init-portainer.sh
```

Acceso:

```text
https://192.168.56.15:30779
```

El script deja inicializado `admin / T]8zJMh3U:ADu@L`, garantiza el environment Kubernetes `local` y valida que Portainer ve namespaces y deployments. En la UI entra en `Environments` y abre `local`.

Si caduca el bootstrap antes de inicializar:

```bash
kubectl rollout restart deployment/portainer -n portainer
```

## Verificación end-to-end

```bash
bash scripts/wait-ready.sh
bash scripts/verify-stack.sh
```

`verify-stack.sh` ejecuta las verificaciones por fase, prueba la SPA, Portainer y el flujo DENA OIDC completo.

## Operacion

Arranque/revision:

```bash
bash scripts/wait-ready.sh
```

Apagado controlado:

```bash
ssh dena 'bash -s -- --poweroff' < scripts/stop-stack.sh
```

Detalle operativo: `docs/runbook.md`.
