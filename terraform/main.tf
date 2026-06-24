resource "keycloak_realm" "dena" {
  realm                         = "dena"
  display_name                  = "DENA Interoperabilidad"
  enabled                       = true
  ssl_required                  = "none"
  login_with_email_allowed      = true
  duplicate_emails_allowed      = false
  reset_password_allowed        = false
  registration_allowed          = false
  access_token_lifespan         = "15m"
  sso_session_idle_timeout      = "30m"
  sso_session_max_lifespan      = "10h"
  terraform_deletion_protection = true
}

resource "keycloak_openid_client" "react_frontend" {
  realm_id                     = keycloak_realm.dena.id
  client_id                    = "react-frontend"
  name                         = "DENA React Frontend"
  enabled                      = true
  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  pkce_code_challenge_method   = "S256"
  valid_redirect_uris = [
    "${var.gateway_base_url}/*",
    "http://localhost:3000/*"
  ]
  web_origins = [
    var.gateway_base_url,
    "http://localhost:3000"
  ]
}

resource "keycloak_openid_client" "apisix_gateway" {
  realm_id                     = keycloak_realm.dena.id
  client_id                    = "apisix-gateway"
  name                         = "APISIX Gateway"
  enabled                      = true
  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = false
  direct_access_grants_enabled = true
  service_accounts_enabled     = true
  full_scope_allowed           = true
}

resource "keycloak_role" "reader" {
  realm_id    = keycloak_realm.dena.id
  name        = "dena-reader"
  description = "Consulta de expedientes mediante la API DENA."
}

resource "keycloak_role" "writer" {
  realm_id    = keycloak_realm.dena.id
  name        = "dena-writer"
  description = "Envio de solicitudes de interoperabilidad DENA."
}

resource "keycloak_role" "admin" {
  realm_id        = keycloak_realm.dena.id
  name            = "dena-admin"
  description     = "Administracion funcional de la API DENA."
  composite_roles = [keycloak_role.reader.id, keycloak_role.writer.id]
}

resource "keycloak_user" "testuser" {
  realm_id       = keycloak_realm.dena.id
  username       = "testuser"
  enabled        = true
  email          = "testuser@dena.local"
  email_verified = true
  first_name     = "Test"
  last_name      = "User"

  initial_password {
    value     = var.testuser_password
    temporary = false
  }
}

resource "keycloak_user_roles" "testuser" {
  realm_id = keycloak_realm.dena.id
  user_id  = keycloak_user.testuser.id
  role_ids = [keycloak_role.reader.id, keycloak_role.writer.id]
}
