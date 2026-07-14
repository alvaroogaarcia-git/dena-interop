# Apache NiFi

## Qué Es

Apache NiFi es una herramienta de flujos de datos. Permite mover, transformar y sincronizar datos entre sistemas mediante procesadores visuales.

## Objetivo En Este Piloto

NiFi sincroniza los cambios del origen `verticales` hacia el `datalake` y hacia `datos_externos`. Los flujos usan JDBC y consulta incremental basada en `updated_at`, con ejecución cada `30 sec`.

## Dónde Está

- Namespace: `datalake`
- Deployment: `nifi`
- Service: `nifi`
- NodePort: `30821`
- Acceso validado: port-forward a `8443`

## Cómo Se Usa

Acceso UI:

```bash
kubectl port-forward -n datalake svc/nifi 8443:8443
```

Abrir:

```text
https://localhost:8443/nifi
```

Credenciales:

```bash
kubectl get secret -n datalake nifi-secret -o jsonpath='{.data.single-user-password}' | base64 -d
```

## Qué Contiene En Este Caso

Flujo:

- Grupo `Fase 15 - DENA staging incremental`.
- Grupo `Fase 20 - DENA datos externos incremental`.
- Conexión JDBC a `postgresql-verticales`.
- Procesador `Query Verticales Incremental`.
- Procesador `Persist Staging Batch`.
- Procesador `Promote Staging To Main`.
- Writer JSON.
- Reader JSON.
- Sincronización hacia `dena.admin_file_staging` y promoción a `dena.admin_file`.
- Sincronización hacia `datos_externos.dena.dena_admin_file_staging` y promoción al modelo DENA enriquecido.
- Driver PostgreSQL JDBC en `extensions/`.

## Cómo Verificarlo

```bash
bash scripts/verify-fase11.sh
bash scripts/verify-fase15-nifi.sh
bash scripts/verify-fase20-datos-externos-nifi.sh
```

## Por Qué Se Usa

Porque simula que los datos viajan automáticamente desde una administración origen hacia un datalake sin exportaciones manuales.
