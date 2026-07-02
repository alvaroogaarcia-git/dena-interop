# Apache NiFi

## Que Es

Apache NiFi es una herramienta de flujos de datos. Permite mover, transformar y sincronizar datos entre sistemas mediante procesadores visuales.

## Objetivo En Este Piloto

NiFi sincroniza los cambios del origen `verticales` hacia el `datalake`. El flujo usa JDBC y consulta incremental basada en `updated_at`.

## Donde Esta

- Namespace: `datalake`
- Deployment: `nifi`
- Service: `nifi`
- NodePort: `30821`
- Acceso validado: port-forward a `8443`

## Como Se Usa

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

## Que Contiene En Este Caso

Flujo:

- Grupo `Fase 12 - JDBC incremental`.
- Conexion JDBC a `postgresql-verticales`.
- Procesador `Query Verticales Incremental`.
- Writer JSON.
- Persistencia de salida en PVC de NiFi.
- Driver PostgreSQL JDBC en `extensions/`.

## Como Verificarlo

```bash
bash scripts/verify-fase11.sh
bash scripts/verify-fase12.sh
```

## Por Que Se Usa

Porque simula que los datos viajan automaticamente desde una administracion origen hacia un datalake sin exportaciones manuales.
