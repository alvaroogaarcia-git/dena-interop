# Acceso A Bases De Datos

Esta carpeta documenta el acceso exacto a cada base PostgreSQL del piloto.

Formato recomendado:

1. Abrir la página de la base.
2. Copiar el comando exacto.
3. Usar la contraseña indicada en el propio documento o leerla desde el secret si no está fijada en la demo.

## Índice

- [auth / keycloak](auth-keycloak.md)
- [verticales / expedientes](verticales-expedientes.md)
- [verticales / mathesar_django](verticales-mathesar-django.md)
- [datalake / dena](datalake-dena.md)

## Comando Base

Desde la VM del piloto:

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
```

Para entrar en `psql`, el patrón general es:

```bash
kubectl exec -i -n <namespace> <pod> -- \
  env PGPASSWORD="<password>" \
  psql -U <user> -d <database>
```

## Notas

- Los valores demo que sí están fijados aparecen en los documentos individuales.
- Los secretos que no están fijados en Git se leen desde `kubectl get secret`.
- Si quieres solo consultar una tabla concreta, usa `-c "select ..."` en lugar de abrir la consola interactiva.

