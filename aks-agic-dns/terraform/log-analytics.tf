resource "azurerm_log_analytics_workspace" "aksdemo" {
  name                = var.log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 2
}
