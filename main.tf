terraform {
  backend "azurerm" {
    resource_group_name  = "rghackademytf"
    storage_account_name = "hacktamedysa0x008"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"    
  }

  required_providers {
    azurerm = {
      version = "~> 2.19"
    }
  }
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rghackamedy" {
  name     = "rghackademy"
  location = "eastus"
}
