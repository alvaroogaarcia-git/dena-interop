# Mathesar

## Que Es

Mathesar es una interfaz web para editar bases PostgreSQL como si fueran tablas de negocio. Permite introducir y modificar datos sin usar SQL directamente.

## Objetivo En Este Piloto

Mathesar simula la herramienta de un funcionario que edita expedientes en el sistema origen.

## Donde Esta

- Namespace: `verticales`
- Deployment: `mathesar`
- Service NodePort: `30900`
- URL: `http://192.168.56.15:30900`
- Base interna: `mathesar_django`
- Base de negocio: `expedientes`

## Como Se Usa

Abrir:

```text
http://192.168.56.15:30900
```

Conexion que debe existir en Mathesar:

- Host: `postgresql-verticales.verticales.svc.cluster.local`
- Puerto: `5432`
- Base: `expedientes`
- Usuario: `postgres`

## Que Contiene En Este Caso

Mathesar permite editar:

- Tabla `expedientes.admin_file`.
- 50 expedientes demo.
- Estados validados por constraint SQL.

Los cambios son detectados por NiFi y llevados al datalake.

## Como Verificarlo

```bash
bash scripts/verify-fase11b.sh
curl -i http://192.168.56.15:30900
```

## Por Que Se Usa

Porque da una UI sencilla para modificar el origen de datos sin construir una aplicacion de gestion completa.
