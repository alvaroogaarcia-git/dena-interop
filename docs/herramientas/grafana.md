# Grafana

## Qué Es

Grafana es una herramienta de visualización. Muestra dashboards con métricas, logs y trazas desde distintos datasources.

## Objetivo En Este Piloto

Grafana es la consola principal de observabilidad. Permite ver el estado del stack, consumo, disponibilidad y señales técnicas.

## Dónde Está

- Namespace: `monitoring`
- Deployment: `monitoring-grafana`
- Service NodePort: `31803`
- URL: `http://192.168.56.15:31803`

## Cómo Se Usa

Abrir:

```text
http://192.168.56.15:31803
```

Login demo:

- Usuario: `admin`
- Password: secret `monitoring/grafana-admin`

Recuperar password:

```bash
kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

## Qué Contiene En Este Caso

Datasources:

- Prometheus.
- Loki.
- Tempo.

Carpeta:

- `DENA`

Dashboards:

- `DENA Stack Overview`
- `DENA API Observability`
- `DENA PostgreSQL Overview`
- `Observability Prometheus`
- `Observability Loki`
- `Observability Tempo`

Todos los paneles de estos dashboards incluyen descripción. En Grafana se ve como un icono de información junto al título del panel; al pasar el ratón por encima explica que mide el panel y cómo interpretarlo.

## Dashboard `DENA API Observability`

Este dashboard sirve para entender la ruta de la API sin tener que conocer todos los comandos de Kubernetes.

La ruta observada es:

```text
Cliente o SPA -> APISIX -> Keycloak -> PostgREST -> PostgreSQL datalake
```

Paneles principales:

- `Gateway Disponible`: indica si APISIX tiene una replica disponible. Si aparece en rojo o vale `0`, la entrada HTTP principal no está lista.
- `API Datos Disponible`: indica si PostgREST está disponible. Si APISIX está bien pero este panel falla, el gateway puede recibir llamadas pero la API de datos no podrá responder.
- `Autenticacion Disponible`: indica si Keycloak está disponible. Si falla, las rutas protegidas pueden devolver errores de autenticación aunque la API y la base de datos esten levantadas.
- `Reinicios API`: muestra los reinicios de APISIX, PostgREST y Keycloak dentro del rango de tiempo seleccionado. Un valor mayor que `0` no siempre es grave, pero conviene revisar logs si no coincide con un reinicio planificado.
- `CPU Componentes API`: muestra la CPU usada por APISIX, PostgREST y Keycloak. Picos breves son normales; uso alto sostenido puede explicar lentitud.
- `Memoria Componentes API`: muestra la memoria usada por los componentes de la ruta API. Si sube mucho y coincide con reinicios, puede haber falta de memoria o limites demasiado bajos.
- `Conexiones PostgreSQL Datalake`: muestra cuantas conexiones están abiertas contra la base del datalake. Si crece y no baja, puede haber consultas bloqueadas o demasiados clientes.
- `Filas Leidas por Segundo`: muestra actividad de lectura en PostgreSQL del datalake. Ayuda a ver si la API está consultando datos o si no llega tráfico a la base.
- `Respuestas HTTP por Codigo`: cuenta respuestas vistas en los access logs de APISIX. Los `2xx` y `3xx` suelen ser correctos; `401` y `403` indican autenticación o permisos; `5xx` indica error en el gateway o en el servicio al que llama.
- `Latencia p95 Gateway`: muestra el tiempo por debajo del cual queda el 95% de las peticiones observadas por APISIX. Si sube, los usuarios pueden notar lentitud aunque la API siga respondiendo.
- `Logs APISIX`: muestra logs recientes del gateway. Se usa para buscar problemas de rutas, autenticación OIDC, errores `401/403/5xx` o fallos al llamar al upstream.
- `Logs PostgREST`: muestra logs recientes de la API de datos. Se usa para buscar errores SQL, errores de conexión a PostgreSQL o problemas de configuración.

Cómo leerlo ante una incidencia:

- Si `Gateway Disponible` vale `0`, revisar primero APISIX.
- Si `Gateway Disponible` está bien pero `API Datos Disponible` vale `0`, revisar PostgREST.
- Si los usuarios reciben `401` o `403`, revisar `Autenticacion Disponible` y `Logs APISIX`.
- Si suben los `5xx`, mirar `Logs APISIX`, `Logs PostgREST` y disponibilidad de PostgREST.
- Si todo está disponible pero la API va lenta, mirar `Latencia p95 Gateway`, `CPU Componentes API`, `Memoria Componentes API`, `Conexiones PostgreSQL Datalake` y `Filas Leidas por Segundo`.
- Si hay reinicios, abrir `Logs APISIX` o `Logs PostgREST` y comparar la hora del error con el panel `Reinicios API`.

Limitacion actual:

- El dashboard usa métricas que ya existen en el piloto: Kubernetes, contenedores, PostgreSQL y logs en Loki.
- Los códigos HTTP y la latencia salen de los access logs de APISIX, no de métricas Prometheus nativas.
- Todavía no separa latencia y errores por endpoint concreto, por ejemplo `/api` frente a `/dena/admin-files`. Para eso conviene habilitar métricas HTTP específicas en APISIX/PostgREST o enriquecer el parseo de logs con la ruta normalizada.

## Cómo Verificarlo

```bash
bash scripts/verify-fase14.sh
curl -i http://192.168.56.15:31803/login
```

## Por Qué Se Usa

Porque centraliza la observabilidad. Sin Grafana, las métricas/logs/trazas existen, pero son más difíciles de consultar.
