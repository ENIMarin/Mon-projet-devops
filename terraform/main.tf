terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. On lit le groupe de ressources existant
data "azurerm_resource_group" "rg" {
  name = "rg-MAudoire2025_cours-projet"
}

# 2. Création du cluster Kubernetes (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "devops-projet-aks"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "devops-projet"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2ms" 
  }

  identity {
    type = "SystemAssigned"
  }

  # LA SOLUTION : On copie exactement tous les tags (y compris le bon "user") du groupe de ressources
  tags = data.azurerm_resource_group.rg.tags
}