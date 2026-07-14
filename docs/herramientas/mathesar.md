# Mathesar

## Qué Es

Mathesar es una interfaz web para editar bases PostgreSQL como si fueran tablas de negocio. Permite introducir y modificar datos sin usar SQL directamente.

## Objetivo En Este Piloto

Mathesar simula la herramienta de un funcionario que edita expedientes en el sistema origen.

## Dónde Está

- Namespace: `verticales`
- Deployment: `mathesar`
- Service NodePort: `30900`
- URL: `http://192.168.56.15:30900`
- URL por port-forward local: `http://127.0.0.1:18000`
- Base interna: `mathesar_django`
- Base de negocio: `expedientes`

## Cómo Se Usa

Abrir:

```text
http://192.168.56.15:30900
```

Si el NodePort no es accesible desde la máquina operadora, usar port-forward:

```bash
kubectl port-forward -n verticales svc/mathesar 18000:8000 --address 127.0.0.1
```

Y abrir:

```text
http://127.0.0.1:18000
```

Login web demo:

- Usuario: `admin`
- Password: `Mathesar1234!`

Conexión que debe existir en Mathesar:

- Host: `postgresql-verticales.verticales.svc.cluster.local`
- Puerto: `5432`
- Base: `expedientes`
- Usuario: `postgres`
- Password: valor del Secret `verticales/mathesar-secret`, clave `db-password`

Para leer la password de PostgreSQL usada por Mathesar:

```bash
kubectl get secret mathesar-secret -n verticales -o jsonpath='{.data.db-password}' | base64 -d; echo
```

## Qué Contiene En Este Caso

Mathesar permite editar:

- Tabla `expedientes.admin_file`.
- 50 expedientes demo.
- Estados validados por constraint SQL.

Los cambios son detectados por NiFi y llevados al datalake.

## Cómo Verificarlo

```bash
bash scripts/verify-fase11b.sh
curl -i http://192.168.56.15:30900
```

## Por Qué Se Usa

Porque da una UI sencilla para modificar el origen de datos sin construir una aplicación de gestión completa.
