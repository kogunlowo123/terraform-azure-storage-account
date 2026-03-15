module "test" {
  source = "../"

  name                     = "ststoragetest0001"
  resource_group_name      = "rg-storage-test"
  location                 = "eastus2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"

  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties = {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy = {
      days = 7
    }

    container_delete_retention_policy = {
      days = 7
    }
  }

  containers = {
    data = {
      container_access_type = "private"
    }
    logs = {
      container_access_type = "private"
    }
  }

  management_policies = [
    {
      name    = "cleanup-old-blobs"
      enabled = true
      filters = {
        prefix_match = ["logs/"]
        blob_types   = ["blockBlob"]
      }
      actions = {
        base_blob = {
          tier_to_cool_after_days_since_modification_greater_than    = 30
          tier_to_archive_after_days_since_modification_greater_than = 90
          delete_after_days_since_modification_greater_than          = 365
        }
      }
    }
  ]

  tags = {
    environment = "test"
    managed_by  = "terraform"
  }
}
