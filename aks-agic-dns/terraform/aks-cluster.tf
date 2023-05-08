resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.app_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.app_name

  default_node_pool {
    name           = "agentpool"
    node_count     = 2
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }


  # CNI (instead of kubenet)
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
    outbound_type  = "loadBalancer"
  }

  # AGIC
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.aks.id
  }


  depends_on = [azurerm_virtual_network.aksdemo, azurerm_application_gateway.aks]
}

# aks > subnet
resource "azurerm_role_assignment" "aks_subnet" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  depends_on           = [azurerm_virtual_network.aksdemo]
}

# aks > appgw
resource "azurerm_role_assignment" "aks_appgw" {
  scope                = azurerm_application_gateway.aks.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  depends_on           = [azurerm_application_gateway.aks]
}

# agic > appgw
resource "azurerm_role_assignment" "agic_appgw" {
  scope                            = azurerm_application_gateway.aks.id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on                       = [azurerm_application_gateway.aks]
  skip_service_principal_aad_check = true
}

# agic > appgw resource group
resource "azurerm_role_assignment" "agic_appgw_rg" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on           = [azurerm_application_gateway.aks]
}
