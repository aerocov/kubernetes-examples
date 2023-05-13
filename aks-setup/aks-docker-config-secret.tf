resource "kubernetes_secret" "acr_config_secret" {
  metadata {
    name = "docker-cfg"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${azurerm_container_registry.acr.login_server}" = {
          "username" = azurerm_container_registry.acr.admin_username
          "password" = azurerm_container_registry.acr.admin_password
          "auth"     = base64encode("${azurerm_container_registry.acr.admin_username}:${azurerm_container_registry.acr.admin_password}")
        }
      }
    })
  }
}