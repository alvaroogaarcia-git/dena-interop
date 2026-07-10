# Estados Validados Por Fase

Indice operativo de fases individuales. Cada pagina explica que se hizo, que comandos ejecutar, que hace cada comando y como verificar el resultado.

| Fase | Resumen corto | Detalle |
| --- | --- | --- |
| 0 | DietPi queda preparado como nodo base. | [Fase 0](fase-00-dietpi-base.md) |
| 1 | k3s queda instalado sin Traefik ni servicelb. | [Fase 1](fase-01-k3s.md) |
| 2 | kubectl, Helm, Terraform y kubeconfig quedan listos. | [Fase 2](fase-02-tooling-kubeconfig.md) |
| 3 | Se crean los namespaces base del piloto. | [Fase 3](fase-03-namespaces.md) |
| 4 | PostgreSQL de `auth` queda desplegado para Keycloak. | [Fase 4](fase-04-postgresql-auth.md) |
| 5 | Keycloak queda desplegado sobre PostgreSQL. | [Fase 5](fase-05-keycloak.md) |
| 6 | APISIX y etcd quedan publicados por NodePort. | [Fase 6](fase-06-apisix-etcd.md) |
| 7 | Observabilidad base queda instalada en `monitoring`. | [Fase 7](fase-07-observabilidad.md) |
| 8 | OpenTelemetry Collector queda desplegado como DaemonSet. | [Fase 8](fase-08-otel-collector.md) |
| 9 | PostgreSQL del datalake queda desplegado. | [Fase 9](fase-09-postgresql-datalake.md) |
| 10 | PostgREST queda conectado al datalake. | [Fase 10](fase-10-postgrest.md) |
| 11 | NiFi queda desplegado con HTTPS y single-user. | [Fase 11](fase-11-nifi.md) |
| 11b | Verticales, Mathesar y driver JDBC quedan preparados. | [Fase 11b](fase-11b-verticales-mathesar.md) |
| 11c | NiFi sincroniza datos hacia staging de forma incremental. | [Fase 11c](fase-11c-nifi-jdbc.md) |
| 12 | Keycloak queda gestionado por Terraform. | [Fase 12](fase-12-keycloak-terraform.md) |
| 13 | APISIX publica API DENA protegida por OIDC. | [Fase 13](fase-13-apisix-dena-api.md) |
| 14 | Grafana queda gestionado por Terraform. | [Fase 14](fase-14-grafana-terraform.md) |
| 15 | SQL DENA del datalake queda aplicado y verificable. | [Fase 15](fase-15-sql-datalake.md) |
| 16 | SPA ciudadana queda servida por APISIX. | [Fase 16](fase-16-spa-ciudadana.md) |
| 17 | Portainer queda desplegado e inicializado. | [Fase 17](fase-17-portainer.md) |
| 18 | Consola admin DENA queda protegida con passkey. | [Fase 18](fase-18-consola-admin-passkey.md) |
| 19 | PostgreSQL aislado de datos externos queda creado. | [Fase 19](fase-19-datos-externos.md) |
| 20 | NiFi sincroniza datos externos DENA incrementalmente. | [Fase 20](fase-20-nifi-datos-externos.md) |

## Historico acumulado

Los documentos antiguos se conservan como cortes de validacion historicos:

| Corte | Archivo |
| --- | --- |
| Fases 0-3 | [estado-fases-0-3.md](estado-fases-0-3.md) |
| Fases 0-6 | [estado-fases-0-6.md](estado-fases-0-6.md) |
| Fases 0-7 | [estado-fases-0-7.md](estado-fases-0-7.md) |
| Fases 0-10 | [estado-fases-0-10.md](estado-fases-0-10.md) |
| Fases 0-11 | [estado-fases-0-11.md](estado-fases-0-11.md) |
| Fases 0-11b | [estado-fases-0-11b.md](estado-fases-0-11b.md) |
| Fases 0-13 | [estado-fases-0-13.md](estado-fases-0-13.md) |
| Fases 0-14 | [estado-fases-0-14.md](estado-fases-0-14.md) |
| Fases 0-15 | [estado-fases-0-15.md](estado-fases-0-15.md) |
| Fases 0-17 | [estado-fases-0-17.md](estado-fases-0-17.md) |
| Fase 18 | [estado-fases-0-18.md](estado-fases-0-18.md) |
| Fase 19 | [estado-fases-0-19.md](estado-fases-0-19.md) |
| Fase 20 | [estado-fases-0-20.md](estado-fases-0-20.md) |

Para reconstruir una VM completa desde cero, usar tambien la [guia paso a paso de replicacion](../operacion/configuracion-vm-previa.md).
