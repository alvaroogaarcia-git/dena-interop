# Documentacion

La documentacion esta organizada por uso para que sea facil encontrar el documento correcto sin recorrer una lista plana.

## Para Empezar

- [Demo rapida en VM nueva](demo/demo-vm.md): camino corto para levantar y probar el piloto.
- [Guia completa de instalacion](guias/guia-instalacion.md): instalacion paso a paso del stack.
- [Configuracion previa de la VM](operacion/configuracion-vm-previa.md): preparacion de VirtualBox/DietPi antes del bootstrap.

## Guias Tecnicas

- [Preparacion de Fase 8](guias/fase8-preparacion.md): base para observabilidad y OTel Collector.
- [Flujo NiFi JDBC incremental](guias/fase12-nifi-jdbc.md): flujo operativo actual de staging/promocion de Fase 15; el nombre `fase12` se conserva como referencia historica.
- [Fase 15 - SQL del datalake y carga local](guias/fase15-datalake.md): esquema DENA, staging y carga manual.
- [Guia UI de NiFi](guias/nifi-flujo-ui-guia.md): referencia visual para revisar el flujo en la interfaz.

## Operacion

- [Runbook operativo](operacion/runbook.md): arranque, parada, recuperacion y riesgos.
- [Recuperacion de passkey en Keycloak](operacion/recuperacion-passkey-keycloak.md): recuperacion controlada cuando un usuario pierde su passkey.
- [GitHub Actions](operacion/github-actions.md): automatizaciones y ejecuciones desde CI.
- [Optimizacion k3s 4GB](operacion/optimizacion-k3s-4gb.md): ajustes y recuperacion en nodos pequenos.

## Arquitectura

- [Arquitectura](arquitectura/arquitectura.md): vision general del stack y sus flujos.
- [Observabilidad y Grafana](arquitectura/grafana-observabilidad.md): diseno de metricas, logs, trazas y dashboards.

## Referencia

- [Herramientas](herramientas/README.md): documentacion por componente.
- [Historico de estados por fase](estado-fases/README.md): cortes validados del piloto.
