provider "keycloak" {
  client_id = "admin-cli"
  username  = var.keycloak_admin_username
  password  = var.keycloak_admin_password
  url       = var.keycloak_url
  realm     = "master"
}

provider "grafana" {
  url  = var.grafana_url
  auth = "${var.grafana_admin_username}:${var.grafana_admin_password}"
}
