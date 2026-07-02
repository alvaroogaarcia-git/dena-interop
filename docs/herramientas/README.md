# Documentacion de Herramientas

Esta carpeta explica las herramientas principales del piloto `dena-interop` desde un punto de vista informativo y operativo: que son, para que se usan, donde viven en este entorno, como se accede, que contienen y como se comprueba que funcionan.

## Indice

| Herramienta | Documento | Funcion en el piloto |
| --- | --- | --- |
| k3s | [k3s.md](k3s.md) | Kubernetes ligero que ejecuta todo el stack |
| kubectl | [kubectl.md](kubectl.md) | CLI para inspeccionar y operar Kubernetes |
| Helm | [helm.md](helm.md) | Instalador de aplicaciones Kubernetes |
| Terraform | [terraform.md](terraform.md) | Configuracion declarativa de Keycloak y Grafana |
| APISIX | [apisix.md](apisix.md) | Gateway HTTP unico de entrada |
| etcd | [etcd.md](etcd.md) | Almacen interno de configuracion de APISIX |
| Keycloak | [keycloak.md](keycloak.md) | Identidad, login y tokens OIDC |
| PostgreSQL | [postgresql.md](postgresql.md) | Bases de datos internas y de negocio |
| PostgREST | [postgrest.md](postgrest.md) | API REST generada sobre PostgreSQL |
| Apache NiFi | [nifi.md](nifi.md) | Sincronizacion incremental de datos |
| Mathesar | [mathesar.md](mathesar.md) | Edicion visual del origen de datos |
| Grafana | [grafana.md](grafana.md) | Visualizacion de observabilidad |
| Prometheus | [prometheus.md](prometheus.md) | Metricas del cluster y servicios |
| Loki | [loki.md](loki.md) | Logs centralizados |
| Tempo | [tempo.md](tempo.md) | Trazas distribuidas |
| OTel Collector | [otel-collector.md](otel-collector.md) | Recolector de logs, metricas y trazas |
| Portainer | [portainer.md](portainer.md) | Consola web para inspeccionar Kubernetes |
| SPA cliente DENA | [spa-cliente-dena.md](spa-cliente-dena.md) | Cliente demo del flujo OIDC + API |
| NGINX | [nginx.md](nginx.md) | Servidor web estatico de la SPA demo |
| GitHub Actions | [github-actions.md](github-actions.md) | Automatizacion de verificaciones y operaciones |

## Lectura Recomendada

Para entender el sistema completo:

1. Leer [k3s.md](k3s.md), [kubectl.md](kubectl.md) y [helm.md](helm.md).
2. Leer [apisix.md](apisix.md) y [keycloak.md](keycloak.md).
3. Leer [postgresql.md](postgresql.md), [postgrest.md](postgrest.md), [nifi.md](nifi.md) y [mathesar.md](mathesar.md).
4. Leer [grafana.md](grafana.md), [prometheus.md](prometheus.md), [loki.md](loki.md), [tempo.md](tempo.md) y [otel-collector.md](otel-collector.md).
5. Leer [portainer.md](portainer.md) y [spa-cliente-dena.md](spa-cliente-dena.md).
