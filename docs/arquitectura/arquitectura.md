# Arquitectura

## Entrada Única

APISIX publica el `NodePort 30080` y concentra el tráfico externo:

- `/`: SPA cliente demo.
- `/realms/*`, `/admin/*`, `/resources/*`: Keycloak.
- `/api/*`: PostgREST protegido por OIDC.
- `POST /dena/admin-files`: RPC DENA protegida por OIDC.
- `/dena/external/*`: PostgREST de `datos_externos` protegido por OIDC.

## Identidad

Keycloak vive en `auth` y usa PostgreSQL propio. El realm operativo del piloto es `piloto`.

Clientes:

- `react-frontend`: cliente público para la SPA.
- `apisix-gateway`: cliente confidencial para introspección OIDC desde APISIX.

Usuario demo:

- `testuser / Test1234!`

## Datos

`verticales` simula el sistema origen editable:

- PostgreSQL `expedientes`.
- Mathesar para edición manual.

`datalake` consolida y expone:

- PostgreSQL `datalake`.
- PostgREST.
- NiFi para sincronización incremental desde `verticales`.

`datos-externos` mantiene el modelo DENA enriquecido:

- PostgreSQL `datos_externos`.
- PostgREST interno `postgrest-datos-externos`.
- Vistas `public.dena_external_*` consumidas por la consola admin y la SPA.
- Sincronización incremental desde `verticales` mediante NiFi.

## Observabilidad

`monitoring` contiene:

- Prometheus.
- Grafana.
- Loki.
- Tempo.
- OTel Collector.

Grafana publica `NodePort 31803`.

## Operación

Portainer es opcional y vive en namespace `portainer`, publicado en:

- HTTPS `30779`.
- HTTP `30777`.

La cuenta demo se inicializa y reconcilia con `scripts/dena/init-portainer.sh`.
