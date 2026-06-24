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
