#!/usr/bin/env bash

set -euo pipefail

NODE_IP="${DENA_NODE_IP:-192.168.56.15}"
HOSTNAME_VALUE="${DENA_HOSTNAME:-dena}"
REPO_URL="${DENA_REPO_URL:-https://github.com/alvaroogaarcia-git/dena-interop.git}"
REPO_BRANCH="${DENA_REPO_BRANCH:-main}"
DEMO_USER="${DENA_DEMO_USER:-${SUDO_USER:-dietpi}}"
REPO_DIR="${DENA_REPO_DIR:-/home/${DEMO_USER}/dena-interop}"
KUBECONFIG_PATH="${DENA_KUBECONFIG:-/home/${DEMO_USER}/.kube/dena-config}"
K3S_VERSION="${DENA_K3S_VERSION:-v1.35.5+k3s1}"
HELM_VERSION="${DENA_HELM_VERSION:-3.14.2}"
TERRAFORM_VERSION="${DENA_TERRAFORM_VERSION:-1.8.0}"

TF_VAR_postgres_password=""
TF_VAR_postgres_replication_password=""
TF_VAR_keycloak_admin_password=""
TF_VAR_grafana_admin_password=""
TF_VAR_postgrest_db_password=""

log() {
  printf '\n==> %s\n' "$*"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_root() {
  [[ "$(id -u)" -eq 0 ]] || fail "Ejecuta este script con sudo."
}

require_user() {
  id "$DEMO_USER" >/dev/null 2>&1 || fail "No existe el usuario $DEMO_USER. Define DENA_DEMO_USER si tu usuario es otro."
}

as_demo_user() {
  runuser -u "$DEMO_USER" -- "$@"
}

install_os_packages() {
  log "Preparando paquetes base"
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl wget git open-iscsi nfs-common iptables \
    iproute2 kmod tar gzip unzip openssl sudo
}

prepare_host() {
  log "Preparando host DietPi/k3s"

  hostnamectl set-hostname "$HOSTNAME_VALUE" || true
  if ! grep -Eq "[[:space:]]${HOSTNAME_VALUE}([[:space:]]|$)" /etc/hosts; then
    printf '%s %s\n' "$NODE_IP" "$HOSTNAME_VALUE" >>/etc/hosts
  fi

  modprobe overlay || true
  modprobe br_netfilter || true

  cat >/etc/modules-load.d/k3s.conf <<'EOF'
overlay
br_netfilter
EOF

  cat >/etc/sysctl.d/99-k3s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF
  sysctl --system >/dev/null

  swapoff -a || true
  sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab
}

check_vm_network() {
  log "Validando red de la VM"
  if ip -brief addr | grep -Fq "$NODE_IP"; then
    echo "IP demo encontrada: $NODE_IP"
  elif [[ "${DENA_SKIP_IP_CHECK:-0}" == "1" ]]; then
    echo "No se encontro $NODE_IP, pero DENA_SKIP_IP_CHECK=1 permite continuar."
  else
    ip -brief addr || true
    fail "La VM no tiene la IP $NODE_IP. Configura el adaptador host-only o usa DENA_NODE_IP=<ip>."
  fi
}

install_k3s() {
  log "Instalando o validando k3s"
  if systemctl is-active --quiet k3s; then
    echo "k3s ya esta activo."
  else
    curl -sfL https://get.k3s.io | \
      INSTALL_K3S_VERSION="$K3S_VERSION" \
      INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --write-kubeconfig-mode 0644 --node-ip ${NODE_IP} --tls-san ${NODE_IP}" \
      sh -
  fi

  systemctl enable --now k3s
  k3s kubectl wait --for=condition=Ready node --all --timeout=180s
}

install_cli_tools() {
  log "Instalando herramientas CLI"

  ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl

  if ! command -v helm >/dev/null 2>&1; then
    tmpdir="$(mktemp -d)"
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -o "$tmpdir/helm.tgz"
    tar -xzf "$tmpdir/helm.tgz" -C "$tmpdir"
    install -m 0755 "$tmpdir/linux-amd64/helm" /usr/local/bin/helm
    rm -rf "$tmpdir"
  fi

  if ! command -v terraform >/dev/null 2>&1; then
    tmpdir="$(mktemp -d)"
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
      -o "$tmpdir/terraform.zip"
    unzip -q "$tmpdir/terraform.zip" -d "$tmpdir"
    install -m 0755 "$tmpdir/terraform" /usr/local/bin/terraform
    rm -rf "$tmpdir"
  fi

  kubectl version --client=true
  helm version --short
  terraform version
}

configure_kubeconfig() {
  log "Configurando kubeconfig de $DEMO_USER"
  install -d -m 0755 -o "$DEMO_USER" -g "$DEMO_USER" "$(dirname "$KUBECONFIG_PATH")"
  cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_PATH"
  sed -i 's#https://127.0.0.1:6443#https://127.0.0.1:6443#' "$KUBECONFIG_PATH"
  chown "$DEMO_USER:$DEMO_USER" "$KUBECONFIG_PATH"
  chmod 600 "$KUBECONFIG_PATH"
}

checkout_repo() {
  log "Clonando o actualizando repositorio"
  install -d -m 0755 -o "$DEMO_USER" -g "$DEMO_USER" "$(dirname "$REPO_DIR")"
  if [[ -d "$REPO_DIR/.git" ]]; then
    as_demo_user git -C "$REPO_DIR" status --short
    if [[ -n "$(as_demo_user git -C "$REPO_DIR" status --short)" ]]; then
      fail "El repo $REPO_DIR tiene cambios locales. Limpialos antes de reejecutar el bootstrap."
    fi
    as_demo_user git -C "$REPO_DIR" fetch origin "$REPO_BRANCH"
    as_demo_user git -C "$REPO_DIR" checkout "$REPO_BRANCH"
    as_demo_user git -C "$REPO_DIR" pull --ff-only origin "$REPO_BRANCH"
  else
    as_demo_user git clone --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
  fi
}

root_stage() {
  require_root
  require_user
  install_os_packages
  prepare_host
  check_vm_network
  install_k3s
  install_cli_tools
  configure_kubeconfig
  checkout_repo

  log "Continuando instalacion como $DEMO_USER"
  exec runuser -u "$DEMO_USER" -- env \
    DENA_NODE_IP="$NODE_IP" \
    DENA_HOSTNAME="$HOSTNAME_VALUE" \
    DENA_DEMO_USER="$DEMO_USER" \
    DENA_REPO_DIR="$REPO_DIR" \
    DENA_KUBECONFIG="$KUBECONFIG_PATH" \
    bash "$REPO_DIR/scripts/bootstrap-demo.sh" --user-stage
}

require_bin() {
  command -v "$1" >/dev/null 2>&1 || fail "Falta binario requerido: $1"
}

write_demo_env() {
  log "Creando secretos demo locales"
  cd "$REPO_DIR"
  mkdir -p .local
  chmod 700 .local

  cat >.local/demo.env <<'EOF'
TF_VAR_postgres_password='v3OYOpRXwCZPAK1pkvUxPvLA'
TF_VAR_postgres_replication_password='demo-replication-password'
TF_VAR_keycloak_admin_password='BVi8R13yKt04fE+/nWIwYcSxVpoIXZPw'
TF_VAR_apisix_admin_key='edd1c9f034335f136f87ad84b625c8f1'
TF_VAR_grafana_admin_password='hLgdC1Azsa0V7XUUhF9P8NyQEVSQyDpJ'
TF_VAR_postgrest_db_password='demo-postgrest-password'
VERTICALES_DB_PASSWORD='pyZN2eJRnVfArOgFltoTlotN'
NIFI_SINGLE_USER_PASSWORD='dsjB2qGE9CW41rvzv8g0'
DENA_TESTUSER_PASSWORD='Test1234!'
PORTAINER_ADMIN_PASSWORD='T]8zJMh3U:ADu@L'
EOF

  cp .local/demo.env .local/fase4-6.env
  cat >.local/fase7.env <<'EOF'
TF_VAR_grafana_admin_password='hLgdC1Azsa0V7XUUhF9P8NyQEVSQyDpJ'
EOF
  cat >.local/fase12-keycloak.env <<'EOF'
TF_VAR_testuser_password='Test1234!'
EOF
  chmod 600 .local/*.env
}

load_demo_env() {
  set -a
  # shellcheck disable=SC1091
  . "$REPO_DIR/.local/demo.env"
  set +a
  export KUBECONFIG="$KUBECONFIG_PATH"
}

require_demo_env() {
  local name
  for name in \
    TF_VAR_postgres_password \
    TF_VAR_postgres_replication_password \
    TF_VAR_keycloak_admin_password \
    TF_VAR_grafana_admin_password \
    TF_VAR_postgrest_db_password \
    NIFI_SINGLE_USER_PASSWORD \
    PORTAINER_ADMIN_PASSWORD; do
    [[ -n "${!name:-}" ]] || fail "Falta $name en $REPO_DIR/.local/demo.env"
  done
}

configure_helm() {
  log "Registrando repos Helm"
  GODEBUG=http2client=0 helm repo add bitnami https://repo.broadcom.com/bitnami-files --force-update
  GODEBUG=http2client=0 helm repo add apiseven https://apache.github.io/apisix-helm-chart --force-update
  GODEBUG=http2client=0 helm repo add grafana https://grafana.github.io/helm-charts --force-update
  GODEBUG=http2client=0 helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
  GODEBUG=http2client=0 helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
  GODEBUG=http2client=0 helm repo update
}

create_namespaces() {
  log "Creando namespaces"
  for ns in auth gateway app monitoring datalake verticales portainer; do
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
  done
}

create_grafana_pvc() {
  kubectl apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: monitoring-grafana
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
YAML
}

install_postgresql_auth() {
  log "Fase 4 - PostgreSQL auth"
  kubectl create secret generic postgresql-auth -n auth \
    --from-literal=postgres-password="$TF_VAR_postgres_password" \
    --from-literal=password="$TF_VAR_postgres_password" \
    --from-literal=replication-password="$TF_VAR_postgres_replication_password" \
    --dry-run=client -o yaml | kubectl apply -f -

  if [[ ! -f /tmp/postgresql-16.2.1.tgz ]]; then
    curl -kL --http1.1 --fail \
      --output /tmp/postgresql-16.2.1.tgz \
      https://charts.bitnami.com/bitnami/postgresql-16.2.1.tgz
  fi

  helm upgrade --install postgresql /tmp/postgresql-16.2.1.tgz \
    -n auth \
    --values helm-values/postgresql-values.yaml

  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=postgresql \
    -n auth \
    --timeout=240s
}

install_keycloak() {
  log "Fase 5 - Keycloak"
  kubectl create secret generic keycloak-secret -n auth \
    --from-literal=db-password="$TF_VAR_postgres_password" \
    --from-literal=admin-password="$TF_VAR_keycloak_admin_password" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f k8s-manifests/keycloak-deployment.yaml
  kubectl rollout status deployment/keycloak -n auth --timeout=420s
}

install_apisix() {
  log "Fase 6 - APISIX"
  if [[ ! -f /tmp/apisix-2.14.1.tgz ]]; then
    GODEBUG=http2client=0 helm pull apiseven/apisix \
      --version 2.14.1 \
      --destination /tmp
  fi
  helm upgrade --install apisix /tmp/apisix-2.14.1.tgz \
    -n gateway \
    --values helm-values/apisix-values.yaml
  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=etcd \
    -n gateway \
    --timeout=300s
  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=apisix \
    -n gateway \
    --timeout=300s
}

install_observability() {
  log "Fase 7 - Observabilidad"
  create_grafana_pvc
  kubectl create secret generic grafana-admin -n monitoring \
    --from-literal=admin-user=admin \
    --from-literal=admin-password="$TF_VAR_grafana_admin_password" \
    --dry-run=client -o yaml | kubectl apply -f -

  GODEBUG=http2client=0 helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    -n monitoring \
    --version 86.2.3 \
    --values helm-values/monitoring-values.yaml \
    --timeout 15m
  GODEBUG=http2client=0 helm upgrade --install loki grafana/loki \
    -n monitoring \
    --version 7.0.0 \
    --values helm-values/loki-values.yaml \
    --timeout 10m
  GODEBUG=http2client=0 helm upgrade --install tempo grafana/tempo \
    -n monitoring \
    --version 1.24.4 \
    --values helm-values/tempo-values.yaml \
    --timeout 10m

  kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=300s
  kubectl rollout status statefulset/loki -n monitoring --timeout=300s
  kubectl rollout status statefulset/tempo -n monitoring --timeout=300s
}

install_otel() {
  log "Fase 8 - OTel Collector"
  GODEBUG=http2client=0 helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    -n monitoring \
    --version 0.158.2 \
    --values helm-values/otel-collector-values.yaml \
    --timeout 10m
  kubectl rollout status daemonset/otel-collector-opentelemetry-collector-agent -n monitoring --timeout=300s
}

install_datalake_postgresql() {
  log "Fase 9 - PostgreSQL datalake"
  helm upgrade --install postgresql-datalake bitnami/postgresql \
    -n datalake \
    --version 18.7.5 \
    --values helm-values/postgresql-datalake-values.yaml \
    --timeout 10m
  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=postgresql \
    -n datalake \
    --timeout=300s
}

install_postgrest() {
  log "Fase 10 - PostgREST"
  pg_password="$(kubectl get secret -n datalake postgresql-datalake -o jsonpath='{.data.postgres-password}' | base64 -d)"
  kubectl exec -i -n datalake postgresql-datalake-0 -- \
    env PGPASSWORD="$pg_password" \
    psql -v ON_ERROR_STOP=1 -U postgres -d datalake \
    -v postgrest_db_password="$TF_VAR_postgrest_db_password" \
    < sql/00-postgrest-roles.sql

  kubectl create secret generic postgrest-secret -n datalake \
    --from-literal=db-uri="postgres://postgrest:${TF_VAR_postgrest_db_password}@postgresql-datalake.datalake.svc.cluster.local:5432/datalake" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl apply -f k8s-manifests/postgrest-deployment.yaml
  kubectl rollout status deployment/postgrest -n datalake --timeout=240s
}

install_nifi() {
  log "Fase 11 - NiFi"
  kubectl create secret generic nifi-secret -n datalake \
    --from-literal=single-user-username=admin \
    --from-literal=single-user-password="$NIFI_SINGLE_USER_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl apply -f k8s-manifests/nifi-deployment.yaml
  kubectl rollout status deployment/nifi -n datalake --timeout=600s
}

install_verticales_mathesar() {
  log "Fase 11b - Verticales y Mathesar"
  bash scripts/dena/install-nifi-postgresql-driver.sh

  helm upgrade --install postgresql-verticales bitnami/postgresql \
    -n verticales \
    --version 18.7.5 \
    --values helm-values/postgresql-verticales-values.yaml \
    --timeout 10m
  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=postgresql \
    -n verticales \
    --timeout=300s

  pgv="$(kubectl get secret -n verticales postgresql-verticales -o jsonpath='{.data.postgres-password}' | base64 -d)"
  kubectl exec -i -n verticales postgresql-verticales-0 -- \
    env PGPASSWORD="$pgv" \
    psql -v ON_ERROR_STOP=1 -U postgres -d postgres \
    -c "SELECT 'CREATE DATABASE mathesar_django' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mathesar_django')\\gexec"
  kubectl exec -i -n verticales postgresql-verticales-0 -- \
    env PGPASSWORD="$pgv" \
    psql -v ON_ERROR_STOP=1 -U postgres -d expedientes < sql/verticales/01-expedientes-source.sql
  kubectl exec -i -n verticales postgresql-verticales-0 -- \
    env PGPASSWORD="$pgv" \
    psql -v ON_ERROR_STOP=1 -U postgres -d expedientes < sql/verticales/02-state-check.sql
  bash scripts/dena/load-expedientes.sh

  kubectl create secret generic mathesar-secret -n verticales \
    --from-literal=db-password="$pgv" \
    --from-literal=secret-key="$(openssl rand -base64 50)" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f k8s-manifests/mathesar-deployment.yaml
  kubectl rollout status deployment/mathesar -n verticales --timeout=300s
  kubectl exec -n verticales deployment/mathesar -- \
    env MATHESAR_ADMIN_PASSWORD='Mathesar1234!' \
    python manage.py shell -c "import os; from django.contrib.auth import get_user_model; User=get_user_model(); user, _ = User.objects.get_or_create(username='admin', defaults={'is_staff': True, 'is_superuser': True, 'is_active': True}); user.is_staff = True; user.is_superuser = True; user.is_active = True; user.set_password(os.environ['MATHESAR_ADMIN_PASSWORD']); user.save(); print('Mathesar admin listo')"
}

install_nifi_sync() {
  log "Fase 11c - Sincronizacion NiFi incremental"
  bash scripts/dena/install-nifi-postgresql-driver.sh
  bash scripts/dena/provision-fase15-nifi.sh
}

install_keycloak_terraform() {
  log "Fase 12 - Keycloak por Terraform"
  bash scripts/dena/apply-fase12-keycloak.sh
}

install_apisix_dena_api() {
  log "Fase 13 - API DENA y rutas APISIX"
  bash scripts/dena/apply-dena-api.sh
  bash scripts/dena/apply-route.sh
}

install_grafana_terraform() {
  log "Fase 14 - Grafana por Terraform"
  kubectl apply -f k8s-manifests/keycloak-servicemonitor.yaml
  kubectl apply -f k8s-manifests/postgresql-exporters.yaml
  bash scripts/dena/apply-fase14-grafana.sh
}

install_datalake_sql() {
  log "Fase 15 - SQL datalake y staging"
  bash scripts/dena/apply-fase15-datalake.sh
}

install_spa_and_portainer() {
  log "Fases 16-18 - SPA, Portainer y consola admin"
  kubectl apply -f k8s-manifests/dena-interop-spa.yaml
  kubectl rollout status deployment/dena-interop-spa -n app --timeout=240s
  kubectl apply -f k8s-manifests/dena-admin-console.yaml
  kubectl rollout status deployment/dena-admin-console -n app --timeout=240s
  bash scripts/dena/apply-route.sh

  kubectl apply -f k8s-manifests/portainer-deployment.yaml
  kubectl rollout status deployment/portainer -n portainer --timeout=240s
  PORTAINER_ADMIN_PASSWORD="$PORTAINER_ADMIN_PASSWORD" bash scripts/dena/init-portainer.sh
}

install_datos_externos() {
  log "Fase 19 - PostgreSQL datos externos DENA"
  bash scripts/dena/apply-fase19-datos-externos.sh
}

install_datos_externos_nifi() {
  log "Fase 20 - NiFi hacia datos externos DENA"
  bash scripts/dena/provision-fase20-datos-externos-nifi.sh
}

print_summary() {
  cat <<EOF

DENA Interop demo lista.

Desde el host:
  SPA:        http://${NODE_IP}:30080/
  Grafana:    http://${NODE_IP}:31803/login
  Mathesar:   http://${NODE_IP}:30900
  Portainer:  https://${NODE_IP}:30779

Acceso SSH:
  ssh ${DEMO_USER}@${NODE_IP}
  ssh ${DEMO_USER}@${HOSTNAME_VALUE}   # si el host resuelve '${HOSTNAME_VALUE}' a ${NODE_IP}

Credenciales demo:
  SPA/OIDC:   testuser / Test1234!
  Grafana:    admin / ${TF_VAR_grafana_admin_password}
  Portainer:  admin / ${PORTAINER_ADMIN_PASSWORD}

Verificacion:
  cd ${REPO_DIR}
  bash scripts/verify-stack.sh

EOF
}

user_stage() {
  REPO_DIR="${DENA_REPO_DIR:-$REPO_DIR}"
  KUBECONFIG_PATH="${DENA_KUBECONFIG:-$KUBECONFIG_PATH}"
  export KUBECONFIG="$KUBECONFIG_PATH"

  cd "$REPO_DIR"
  for bin in kubectl helm terraform curl git openssl; do
    require_bin "$bin"
  done

  write_demo_env
  load_demo_env
  require_demo_env
  configure_helm
  create_namespaces
  install_postgresql_auth
  install_keycloak
  install_apisix
  install_observability
  install_otel
  install_datalake_postgresql
  install_postgrest
  install_nifi
  install_verticales_mathesar
  install_keycloak_terraform
  install_apisix_dena_api
  install_grafana_terraform
  install_datalake_sql
  install_nifi_sync
  install_spa_and_portainer
  install_datos_externos
  install_datos_externos_nifi

  log "Verificacion final"
  bash scripts/wait-ready.sh
  bash scripts/verify-fase19-datos-externos.sh
  bash scripts/verify-fase20-datos-externos-nifi.sh
  bash scripts/verify-stack.sh
  print_summary
}

case "${1:-}" in
  --user-stage)
    user_stage
    ;;
  *)
    root_stage
    ;;
esac
