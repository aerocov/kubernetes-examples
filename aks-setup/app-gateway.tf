resource "azurerm_public_ip" "app_gateway_public_ip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg.location
  name                = "aks-app-gateway-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  tags = {
    environment = var.deployment_environment
    domain      = var.domain
  }
}

resource "azurerm_virtual_network" "virtual_network" {
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.rg.location
  name                = "aks-virtual-network"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.30.0.0/24"]
}

resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "app-gateway-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.30.1.0/24"]
}

resource "azurerm_application_gateway" "app_gateway" {
  location            = azurerm_resource_group.rg.location
  name                = "aks-app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  backend_address_pool {
    name = "aks-backend-pool"
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "aks-backend-http-settings"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
  }
  frontend_ip_configuration {
    name                 = "aks-front-end-ip"
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }
  frontend_port {
    name = "aks-frontend-port"
    port = 80
  }
  gateway_ip_configuration {
    name      = "aks-gateway-ip"
    subnet_id = azurerm_subnet.app_gateway_subnet.id
  }
  http_listener {
    frontend_ip_configuration_name = "aks-front-end-ip"
    frontend_port_name             = "aks-frontend-port"
    name                           = "aks-http-listener"
    protocol                       = "Http"
  }
  request_routing_rule {
    http_listener_name         = "aks-http-listener"
    name                       = "aks-request-routing-rule"
    priority                   = 10
    rule_type                  = "Basic"
    backend_address_pool_name  = "aks-backend-pool"
    backend_http_settings_name = "aks-backend-http-settings"
  }
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  tags = {
    environment = var.deployment_environment
    domain      = var.domain
  }
}