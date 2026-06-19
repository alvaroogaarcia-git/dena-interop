# Estado Fases 0-11

Fecha: 2026-06-19

## Resumen

El clúster queda validado hasta Fase 11:

- Fases 0-10: ver `docs/estado-fases-0-10.md`.
- Fase 11: NiFi 2.9 desplegado en `datalake` con HTTPS y single-user.

Todavia no se ha empezado la Fase 11b:

- No hay recursos en `verticales`.
- No hay Mathesar.
- No hay JDBC driver PostgreSQL copiado a `extensions/`.
- No hay flujo NiFi cargado.
- APISIX sigue sin rutas.
- El esquema DENA de Fase 15 todavia no esta aplicado.

## Fase 11 - Apache NiFi 2.9

- Deployment: `nifi`
- Service: `nifi`
- Namespace: `datalake`
- Imagen: `docker.io/apache/nifi:2.9.0`
- Service type: `NodePort`
- Puerto HTTPS: `8443`
- NodePort: `30821`
- Strategy: `Recreate`
- Secret: `nifi-secret`
- PVC: `nifi-extensions`, `4Gi`, `local-path`
- Heap JVM: `256m`
- Requests/Limits: `100m CPU`, `384Mi` request, `1Gi` limit

Configuracion validada:

- `NIFI_WEB_HTTPS_PORT=8443`
- `NIFI_WEB_HTTPS_HOST=0.0.0.0`
- `NIFI_WEB_PROXY_HOST=localhost:8443`
- probes HTTPS con `Host: localhost:8443`
- sin `startupProbe`; `readiness` y `liveness` relajadas para el arranque real del nodo
- autenticacion single-user desde `nifi-secret`

Validacion:

```text
nifi-...   1/1   Running
service/nifi   NodePort   ...   8443:30821/TCP
pvc/nifi-extensions   Bound
```

Validacion HTTPS interna:

```text
HTTP/1.1 200 OK
```

La UI queda pensada para acceso por port-forward:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
```

URL de operador:

```text
https://localhost:8443/nifi
```

Nota operativa:

- El NodePort directo `https://192.168.56.15:30821/nifi` no es la via validada para esta fase.
- En este nodo de `4 GiB`, NiFi quedo estable solo tras reducir heap a `256m`.
- El flujo JDBC y el driver PostgreSQL quedan para la Fase 11b.

## Comandos de cierre

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config

bash scripts/verify-fase11.sh
kubectl get pods,svc,pvc -n datalake -o wide
kubectl logs -n datalake deploy/nifi --tail=80
```

Estado esperado:

- `deployment/nifi` en `Available`
- `service/nifi` publicado en `30821`
- `pvc/nifi-extensions` en `Bound`
- `scripts/verify-fase11.sh` termina sin error

## Siguiente fase

La siguiente fase de la guia es la Fase 11b, pero no forma parte de este cierre.
