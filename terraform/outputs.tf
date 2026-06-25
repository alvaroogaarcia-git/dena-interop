output "realm" {
  value = keycloak_realm.dena.realm
}

output "apisix_client_id" {
  value = keycloak_openid_client.apisix_gateway.client_id
}

output "apisix_client_secret" {
  value     = keycloak_openid_client.apisix_gateway.client_secret
  sensitive = true
}

output "testuser_username" {
  value = keycloak_user.testuser.username
}

output "grafana_folder_uid" {
  value = grafana_folder.dena.uid
}

output "grafana_dashboard_uids" {
  value = [
    "dena-stack-overview",
    "dena-postgresql-overview"
  ]
}
