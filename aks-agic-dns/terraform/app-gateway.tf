locals {
  backend_address_pool_name      = "${azurerm_virtual_network.aksdemo.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.aksdemo.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.aksdemo.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.aksdemo.name}-be-htst"
  http_listener_name             = "${azurerm_virtual_network.aksdemo.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.aksdemo.name}-rqrt"
}

resource "azurerm_public_ip" "appgw" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "aks" {
  name                = var.appgw_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${var.appgw_name}-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  depends_on = [azurerm_virtual_network.aksdemo, azurerm_public_ip.appgw]
}


resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = var.appgw_diagnostic_settings_name
  target_resource_id         = azurerm_application_gateway.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aksdemo.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }
}