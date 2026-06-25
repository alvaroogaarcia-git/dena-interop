terraform {
  required_version = ">= 1.8.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.25"
    }

    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.0"
    }
  }
}
