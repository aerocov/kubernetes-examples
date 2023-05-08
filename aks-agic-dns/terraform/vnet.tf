resource "azurerm_virtual_network" "aksdemo" {
  name                = var.vnet_name
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks" {
  name                 = "${azurerm_virtual_network.aksdemo.name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aksdemo.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_subnet" "appgw" {
  name                 = "${azurerm_virtual_network.aksdemo.name}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aksdemo.name
  address_prefixes     = ["10.2.2.0/24"]
}
