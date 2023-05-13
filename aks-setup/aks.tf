resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.app_gateway.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.deployment_environment
    domain      = var.domain
  }
}