variable "keycloak_url" {
  description = "URL local del port-forward de Keycloak."
  type        = string
  default     = "http://127.0.0.1:18080"
}

variable "keycloak_admin_username" {
  description = "Usuario administrador del realm master."
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Password del administrador de Keycloak."
  type        = string
  sensitive   = true
}

variable "testuser_password" {
  description = "Password estable del usuario de pruebas del laboratorio."
  type        = string
  sensitive   = true
}

variable "gateway_base_url" {
  description = "URL publica del gateway usada en redirects OIDC."
  type        = string
  default     = "http://192.168.56.15:30080"
}
