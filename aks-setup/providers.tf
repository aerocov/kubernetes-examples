terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.39.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

data "azurerm_client_config" "current" {}


