# Fase 18: consola admin con passkey

## Objetivo

Publicar la consola admin DENA y proteger su acceso con flujo OIDC y WebAuthn/FIDO2.

## Comandos

```bash
export KUBECONFIG=/home/dietpi/.kube/dena-config
bash scripts/dena/apply-fase12-keycloak.sh
kubectl apply -f k8s-manifests/dena-admin-console.yaml
kubectl rollout status deployment/dena-admin-console -n app --timeout=240s
bash scripts/dena/apply-route.sh
```

## Que hace cada parte

- `apply-fase12-keycloak.sh`: asegura realm, clientes, usuarios y configuracion de autenticacion.
- `dena-admin-console.yaml`: publica la consola admin en NGINX.
- `rollout status`: espera a que la consola este lista.
- `apply-route.sh`: publica `/dena/admin-console` en APISIX.

## Verificacion

```bash
kubectl get pods,svc -n app -l app=dena-admin-console -o wide
ssh -L 30080:127.0.0.1:30080 dietpi@192.168.56.15
```

Abrir despues:

```text
http://localhost:30080/dena/admin-console
```

## Referencias

- [Historico fase 18](historico/estado-fases-0-18.md)
- [Consola admin DENA](../herramientas/consola-admin-dena.md)
- [Recuperacion passkey](../operacion/recuperacion-passkey-keycloak.md)
