resource "azurerm_role_assignment" "aks_to_aks_subnet" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity.0.principal_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_subnet.aks_subnet.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_subnet.aks_subnet]
}

resource "azurerm_role_assignment" "aks_principal_to_app_gateway_contributor_access" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity.0.principal_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_application_gateway.app_gateway.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "aks_ingress_to_app_gateway_contributor_access" {
  principal_id                     = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_application_gateway.app_gateway.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks, azurerm_application_gateway.app_gateway]
}

resource "azurerm_role_assignment" "aks_ingress_to_resource_group_reader_access" {
  principal_id                     = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  role_definition_name             = "Reader"
  scope                            = azurerm_resource_group.rg.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks, azurerm_application_gateway.app_gateway]
}