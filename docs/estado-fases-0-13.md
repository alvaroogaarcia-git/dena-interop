# Estado Fases 0-13

Fecha: 2026-06-24

## Resumen

El cluster queda validado hasta Fase 13:

- Fases 0-12: ver `docs/estado-fases-0-11b.md` y `docs/fase12-nifi-jdbc.md`.
- Fase 13: APISIX publica PostgREST bajo `/api` mediante una ruta reproducible e idempotente.

Pendiente a partir de aqui:

- esquema DENA de Fase 15
- Terraform de fases posteriores

## Fase 13 - API de datalake mediante APISIX

La ruta `fase13-postgrest` acepta `GET`, `HEAD` y `OPTIONS` sobre `/api` y `/api/*`. El plugin `proxy-rewrite` elimina el prefijo `/api` antes de enviar la peticion al servicio interno:

```text
APISIX /api/* -> postgrest.datalake.svc.cluster.local:3000/*
```

Los metodos de escritura no se publican en esta fase. La ruta queda limitada a la API anonima de lectura que expone PostgREST.

Recursos versionados:

- Ruta: `apisix/routes/fase13-postgrest.json`
- Provisionamiento: `scripts/dena/provision-fase13-apisix.sh`
- Verificacion: `scripts/verify-fase13.sh`

## Provisionamiento y verificacion

```bash
cd /home/dietpi/dena-interop
export KUBECONFIG=/home/dietpi/.kube/dena-config

bash scripts/dena/provision-fase13-apisix.sh
bash scripts/verify-fase13.sh
```

El provisionamiento usa `PUT` sobre un identificador estable, por lo que puede ejecutarse varias veces sin duplicar rutas.

Acceso desde la red del nodo:

```text
http://192.168.56.15:30080/api
```

Estado esperado:

- ruta `fase13-postgrest` presente en APISIX
- upstream `postgrest.datalake.svc.cluster.local:3000`
- `GET /api` devuelve `HTTP 200`
- cabecera `Server: APISIX/3.16.0`
- cuerpo con el documento OpenAPI de PostgREST
