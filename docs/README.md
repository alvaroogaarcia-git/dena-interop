# Documentación

La documentación está organizada por uso para que sea fácil encontrar el documento correcto sin recorrer una lista plana.

## Para Empezar

- [Demo rápida en VM nueva](demo/demo-vm.md): camino corto para levantar y probar el piloto.
- [Guía completa de instalación](guias/guia-instalacion.md): instalación paso a paso del stack.
- [Configuración previa de la VM](operacion/configuracion-vm-previa.md): preparación de VirtualBox/DietPi antes del bootstrap.

## Guías Técnicas

- [Preparación de Fase 8](guias/fase8-preparacion.md): base para observabilidad y OTel Collector.
- [Flujo NiFi JDBC incremental](guias/fase12-nifi-jdbc.md): flujo operativo actual de staging/promoción de Fase 15; el nombre `fase12` se conserva como referencia histórica.
- [Fase 15 - SQL del datalake y carga local](guias/fase15-datalake.md): esquema DENA, staging y carga manual.
- [Fase 19 - PostgreSQL datos externos desde Markdown DENA](guias/fase19-datos-externos.md): base independiente con modelo semántico derivado de Markdown.
- [Fase 20 - NiFi hacia datos externos DENA](guias/fase20-nifi-datos-externos.md): sincronización incremental desde verticales al modelo DENA enriquecido.
- [Fase 21 - Explorador demo de datos externos](guias/fase21-demo-explorer-datos-externos.md): vistas y navegación de carpetas demo desde consola admin y SPA.
- [Guía UI de NiFi](guias/nifi-flujo-ui-guia.md): referencia visual para revisar el flujo en la interfaz.

## Operación

- [Runbook operativo](operacion/runbook.md): arranque, parada, recuperación y riesgos.
- [Recuperación de passkey en Keycloak](operacion/recuperacion-passkey-keycloak.md): recuperación controlada cuando un usuario pierde su passkey.
- [GitHub Actions](operacion/github-actions.md): automatizaciones y ejecuciones desde CI.
- [Optimización k3s 4GB](operacion/optimizacion-k3s-4gb.md): ajustes y recuperación en nodos pequeños.
- [Acceso a bases de datos](acceso-bd/README.md): comandos exactos para entrar en cada PostgreSQL del piloto.

## Arquitectura

- [Arquitectura](arquitectura/arquitectura.md): visión general del stack y sus flujos.
- [Observabilidad y Grafana](arquitectura/grafana-observabilidad.md): diseño de métricas, logs, trazas y dashboards.

## Referencia

- [Herramientas](herramientas/README.md): documentación por componente.
- [Histórico de estados por fase](estado-fases/README.md): cortes validados del piloto.
