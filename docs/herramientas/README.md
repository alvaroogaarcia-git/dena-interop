# Documentación de Herramientas

Esta carpeta explica las herramientas principales del piloto `dena-interop` desde un punto de vista informativo y operativo: qué son, para qué se usan, dónde viven en este entorno, cómo se accede, qué contienen y cómo se comprueba que funcionan.

## Índice

| Herramienta | Documento | Función en el piloto |
| --- | --- | --- |
| k3s | [k3s.md](k3s.md) | Kubernetes ligero que ejecuta todo el stack |
| kubectl | [kubectl.md](kubectl.md) | CLI para inspeccionar y operar Kubernetes |
| Helm | [helm.md](helm.md) | Instalador de aplicaciones Kubernetes |
| Terraform | [terraform.md](terraform.md) | Configuración declarativa de Keycloak y Grafana |
| APISIX | [apisix.md](apisix.md) | Gateway HTTP único de entrada |
| etcd | [etcd.md](etcd.md) | Almacén interno de configuración de APISIX |
| Keycloak | [keycloak.md](keycloak.md) | Identidad, login y tokens OIDC |
| PostgreSQL | [postgresql.md](postgresql.md) | Bases de datos internas y de negocio |
| PostgREST | [postgrest.md](postgrest.md) | API REST generada sobre PostgreSQL |
| Apache NiFi | [nifi.md](nifi.md) | Sincronización incremental de datos |
| Mathesar | [mathesar.md](mathesar.md) | Edición visual del origen de datos |
| Grafana | [grafana.md](grafana.md) | Visualización de observabilidad |
| Prometheus | [prometheus.md](prometheus.md) | Métricas del clúster y servicios |
| Loki | [loki.md](loki.md) | Logs centralizados |
| Tempo | [tempo.md](tempo.md) | Trazas distribuidas |
| OTel Collector | [otel-collector.md](otel-collector.md) | Recolector de logs, métricas y trazas |
| Portainer | [portainer.md](portainer.md) | Consola web para inspeccionar Kubernetes |
| SPA cliente DENA | [spa-cliente-dena.md](spa-cliente-dena.md) | Cliente demo del flujo OIDC + API |
| NGINX | [nginx.md](nginx.md) | Servidor web estático de la SPA demo |
| GitHub Actions | [github-actions.md](github-actions.md) | Automatización de verificaciones y operaciones |

## Lectura Recomendada

Para entender el sistema completo:

1. Leer [k3s.md](k3s.md), [kubectl.md](kubectl.md) y [helm.md](helm.md).
2. Leer [apisix.md](apisix.md) y [keycloak.md](keycloak.md).
3. Leer [postgresql.md](postgresql.md), [postgrest.md](postgrest.md), [nifi.md](nifi.md) y [mathesar.md](mathesar.md).
4. Leer [grafana.md](grafana.md), [prometheus.md](prometheus.md), [loki.md](loki.md), [tempo.md](tempo.md) y [otel-collector.md](otel-collector.md).
5. Leer [portainer.md](portainer.md) y [spa-cliente-dena.md](spa-cliente-dena.md).
