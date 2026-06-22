# Optimizacion de k3s para el nodo de 4 GiB

Fecha de validacion: 2026-06-22

## Incidente observado

`k3s` termino con `status=1` durante una compactacion de Kine/SQLite:

```text
Transaction commit failed: sql: transaction has already been committed or rolled back
```

Antes del cierre se observaron consultas Kine lentas, timeouts de API, `PLEG is not healthy`, un pico de `1.5 GiB` de memoria para el servicio, `1010 MiB` de swap y el filesystem raiz al `91-92 %`.

No fue un fallo de NiFi ni del flujo de Fase 12. La causa fue la combinacion de presion de memoria, swap e I/O sobre un nodo unico de `4 GiB`.

## Correcciones aplicadas

- Limpieza de contenedores detenidos del runtime de k3s.
- Limpieza inicial del filesystem raiz del `91-92 %` al `75 %`.
- Estado final al `86 %` tras desplegar todas las capas activas y reducir la reserva ext4 del `5 %` al `1 %`.
- Prometheus reducido de `7d` a `3d` de retencion.
- Scrape y evaluacion de Prometheus ajustados a `60s`.
- OpenTelemetry host metrics ajustado de `10s` a `30s`.
- Requests y limits revisados para PostgreSQL, Keycloak, NiFi, Grafana, Prometheus, Loki, Tempo, OpenTelemetry y PostgREST.
- NiFi reserva `640Mi`, acorde con su consumo real, y mantiene un limite de `768Mi`.
- Deployments de una replica de monitorizacion configurados con estrategia `Recreate` para no duplicar memoria durante upgrades.
- Flujo y clave sensible de NiFi persistidos en el PVC `nifi-extensions`.

## Recuperacion

Comprobar la causa antes de reiniciar:

```bash
sudo journalctl -u k3s -n 120 --no-pager
df -h /
free -h
```

Reiniciar y comprobar el nodo:

```bash
sudo systemctl restart k3s
kubectl get nodes -o wide
kubectl get pods -A
```

Retirar contenedores detenidos. El comando no elimina contenedores en ejecucion:

```bash
sudo k3s crictl rm --all
```

En esta particion ext4 de `20 GiB` se redujo la reserva para root al `1 %`:

```bash
sudo tune2fs -m 1 /dev/sda1
```

Esto libero aproximadamente `800 MiB` sin eliminar datos. No se debe aplicar a otro dispositivo sin comprobar antes su filesystem y funcion.

No se deben borrar manualmente `/var/lib/rancher/k3s`, los PVC ni snapshots activos de containerd.

## Aplicacion de valores

Los valores optimizados estan versionados en `helm-values/` y los recursos directos en `k8s-manifests/`.

```bash
helm upgrade monitoring prometheus-community/kube-prometheus-stack --version 86.2.3 \
  -n monitoring -f helm-values/monitoring-values.yaml --wait --timeout 10m

helm upgrade loki grafana/loki --version 7.0.0 \
  -n monitoring -f helm-values/loki-values.yaml --wait --timeout 10m

helm upgrade tempo grafana/tempo --version 1.24.4 \
  -n monitoring -f helm-values/tempo-values.yaml --wait --timeout 10m

helm upgrade otel-collector open-telemetry/opentelemetry-collector --version 0.158.2 \
  -n monitoring -f helm-values/otel-collector-values.yaml --wait --timeout 10m

kubectl apply -f k8s-manifests/keycloak-deployment.yaml
kubectl apply -f k8s-manifests/postgrest-deployment.yaml
kubectl apply -f k8s-manifests/nifi-deployment.yaml
```

Las releases PostgreSQL usan sus respectivos ficheros de `helm-values/`.

## Validacion final

```bash
systemctl is-active k3s
kubectl get nodes
kubectl get pods -A
kubectl top pods -A --containers
kubectl describe node dietpi
df -h /
free -h
```

Condiciones esperadas:

- `k3s` en `active`
- nodo `Ready`
- `MemoryPressure=False`
- `DiskPressure=False`
- todos los workloads activos en `Running/Ready`
- filesystem raiz por debajo del `90 %`; estado validado: `86 %`
- Fase 12 valida despues de reiniciar NiFi

El disco de `20 GiB` sigue siendo el minimo operativo para todas las imagenes actuales. Antes de incorporar mas componentes pesados se recomienda ampliar la VM a `30-40 GiB`.
