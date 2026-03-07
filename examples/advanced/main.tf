provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-storage-advanced"
  location = "East US"
}

module "storage_account" {
  source = "../../"

  name                     = "stadvancedexample01"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"

  blob_properties = {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy = {
      days = 30
    }

    container_delete_retention_policy = {
      days = 14
    }

    cors_rule = [
      {
        allowed_headers    = ["*"]
        allowed_methods    = ["GET", "HEAD", "OPTIONS"]
        allowed_origins    = ["https://example.com"]
        exposed_headers    = ["x-ms-meta-*"]
        max_age_in_seconds = 3600
      }
    ]
  }

  containers = {
    "uploads" = {
      container_access_type = "private"
    }
    "backups" = {
      container_access_type = "private"
    }
    "archives" = {
      container_access_type = "private"
    }
  }

  file_shares = {
    "shared-data" = {
      quota       = 100
      access_tier = "Hot"
    }
  }

  queues = {
    "processing" = {
      metadata = {
        purpose = "background-processing"
      }
    }
  }

  tables = {
    "metrics" = {}
    "events"  = {}
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
          delete_after_days_since_modification_greater_than          = 365
        }
        snapshot = {
          delete_after_days_since_creation_greater_than = 90
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
          delete_after_days_since_modification_greater_than = 180
        }
      }
    }
  ]

  tags = {
    Environment = "staging"
    Project     = "example"
  }
}

output "primary_blob_endpoint" {
  value = module.storage_account.primary_blob_endpoint
}

output "container_ids" {
  value = module.storage_account.container_ids
}
