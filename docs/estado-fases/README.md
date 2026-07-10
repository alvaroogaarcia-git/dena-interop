# Estados Validados Por Fase

Esta carpeta guarda el historico de validaciones del piloto. Son documentos de referencia para consultar como quedo el entorno en cada corte de fase, pero no forman parte de la documentacion operativa principal.

| Corte | Archivo | Contenido principal |
| --- | --- | --- |
| Fases 0-3 | [estado-fases-0-3.md](estado-fases-0-3.md) | Preparacion inicial, k3s, tooling y namespaces base |
| Fases 0-6 | [estado-fases-0-6.md](estado-fases-0-6.md) | PostgreSQL auth, Keycloak y APISIX |
| Fases 0-7 | [estado-fases-0-7.md](estado-fases-0-7.md) | Observabilidad local inicial |
| Fases 0-10 | [estado-fases-0-10.md](estado-fases-0-10.md) | OTel Collector, PostgreSQL datalake y PostgREST |
| Fases 0-11 | [estado-fases-0-11.md](estado-fases-0-11.md) | Apache NiFi |
| Fases 0-11b | [estado-fases-0-11b.md](estado-fases-0-11b.md) | Verticales, Mathesar y driver JDBC |
| Fases 0-13 | [estado-fases-0-13.md](estado-fases-0-13.md) | Keycloak por Terraform y rutas APISIX/OIDC |
| Fases 0-14 | [estado-fases-0-14.md](estado-fases-0-14.md) | Grafana gestionado por Terraform |
| Fases 0-15 | [estado-fases-0-15.md](estado-fases-0-15.md) | SQL del datalake, staging y carga local |
| Fases 0-17 | [estado-fases-0-17.md](estado-fases-0-17.md) | Estado consolidado actual hasta Portainer |
| Fase 18 | [estado-fases-0-18.md](estado-fases-0-18.md) | MFA WebAuthn/FIDO2 en consola admin DENA |
| Fase 19 | [estado-fases-0-19.md](estado-fases-0-19.md) | PostgreSQL aislado para datos externos Markdown DENA |

Para operacion diaria, usar el [runbook](../operacion/runbook.md) y la [guia de instalacion](../guias/guia-instalacion.md).
