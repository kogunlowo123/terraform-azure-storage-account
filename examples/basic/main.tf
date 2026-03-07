provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-storage-basic"
  location = "East US"
}

module "storage_account" {
  source = "../../"

  name                     = "stbasicexample001"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  containers = {
    "data" = {
      container_access_type = "private"
    }
    "logs" = {
      container_access_type = "private"
    }
  }

  tags = {
    Environment = "dev"
  }
}

output "storage_account_id" {
  value = module.storage_account.id
}

output "primary_blob_endpoint" {
  value = module.storage_account.primary_blob_endpoint
}
