resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.resource_group_name

  tags = {
    environment = var.deployment_environment
    domain      = var.domain
  }
}