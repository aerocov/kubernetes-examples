resource "azurerm_dns_zone" "aks_dns_zone" {
  name                = "example.com"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = var.deployment_environment
    domain     = var.domain
  }
}


resource "azurerm_cdn_frontdoor_profile" "aks_frontdoor" {
  name                = "aks-frontdoor"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = {
    environment = var.deployment_environment
    domain     = var.domain
  }
}