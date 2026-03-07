provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-storage-complete"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-storage-complete"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "services" {
  name                 = "snet-services"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "file-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-storage-complete"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "id-storage-complete"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

module "storage_account" {
  source = "../../"

  name                              = "stcompleteexample01"
  resource_group_name               = azurerm_resource_group.example.name
  location                          = azurerm_resource_group.example.location
  account_tier                      = "Standard"
  account_replication_type          = "RAGZRS"
  account_kind                      = "StorageV2"
  access_tier                       = "Hot"
  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = true
  shared_access_key_enabled         = true
  public_network_access_enabled     = false
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = true
  identity_type                     = "SystemAssigned, UserAssigned"
  identity_ids                      = [azurerm_user_assigned_identity.example.id]

  blob_properties = {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy = {
      days = 90
    }

    container_delete_retention_policy = {
      days = 30
    }

    cors_rule = [
      {
        allowed_headers    = ["*"]
        allowed_methods    = ["GET", "HEAD", "OPTIONS", "PUT"]
        allowed_origins    = ["https://app.example.com"]
        exposed_headers    = ["x-ms-meta-*", "x-ms-request-id"]
        max_age_in_seconds = 7200
      }
    ]
  }

  containers = {
    "data" = {
      container_access_type = "private"
    }
    "backups" = {
      container_access_type = "private"
    }
    "archives" = {
      container_access_type = "private"
    }
    "uploads" = {
      container_access_type = "private"
      metadata = {
        purpose = "user-uploads"
      }
    }
  }

  file_shares = {
    "shared-config" = {
      quota       = 50
      access_tier = "Hot"
    }
    "shared-data" = {
      quota       = 500
      access_tier = "TransactionOptimized"
    }
  }

  queues = {
    "processing" = {
      metadata = { purpose = "async-processing" }
    }
    "notifications" = {
      metadata = { purpose = "event-notifications" }
    }
  }

  tables = {
    "metrics"  = {}
    "events"   = {}
    "sessions" = {}
  }

  management_policies = [
    {
      name    = "archive-old-data"
      enabled = true
      filters = {
        prefix_match = ["archives/"]
        blob_types   = ["blockBlob"]
      }
      actions = {
        base_blob = {
          tier_to_cool_after_days_since_modification_greater_than    = 30
          tier_to_archive_after_days_since_modification_greater_than = 90
          delete_after_days_since_modification_greater_than          = 730
        }
        snapshot = {
          change_tier_to_cool_after_days_since_creation    = 30
          change_tier_to_archive_after_days_since_creation = 90
          delete_after_days_since_creation_greater_than    = 365
        }
        version = {
          change_tier_to_cool_after_days_since_creation    = 30
          change_tier_to_archive_after_days_since_creation = 90
          delete_after_days_since_creation                 = 365
        }
      }
    },
    {
      name    = "cleanup-backups"
      enabled = true
      filters = {
        prefix_match = ["backups/"]
        blob_types   = ["blockBlob"]
      }
      actions = {
        base_blob = {
          tier_to_cool_after_days_since_modification_greater_than = 60
          delete_after_days_since_modification_greater_than        = 365
        }
      }
    }
  ]

  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [azurerm_subnet.services.id]
  }

  private_endpoints = {
    "blob" = {
      subnet_id            = azurerm_subnet.endpoints.id
      subresource_names    = ["blob"]
      private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
    }
    "file" = {
      subnet_id            = azurerm_subnet.endpoints.id
      subresource_names    = ["file"]
      private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
    }
  }

  diagnostic_settings = {
    "blob-diagnostics" = {
      target_resource_type       = "blob"
      log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
      enabled_log_categories     = ["StorageRead", "StorageWrite", "StorageDelete"]
      metric_categories          = ["Transaction", "Capacity"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "example"
    CostCenter  = "IT-001"
  }
}

output "storage_account_id" {
  value = module.storage_account.id
}

output "primary_blob_endpoint" {
  value = module.storage_account.primary_blob_endpoint
}

output "private_endpoint_ips" {
  value = module.storage_account.private_endpoint_ip_addresses
}
