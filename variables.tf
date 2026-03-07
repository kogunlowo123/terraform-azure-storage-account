variable "name" {
  description = "The name of the storage account. Must be globally unique, 3-24 characters, lowercase letters and numbers only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure region for the storage account."
  type        = string
}

variable "account_tier" {
  description = "The tier of the storage account. Valid values are Standard and Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "The replication type. Valid values are LRS, GRS, RAGRS, ZRS, GZRS, and RAGZRS."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "account_kind" {
  description = "The kind of storage account. Valid values are BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Account kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "access_tier" {
  description = "The access tier for BlobStorage, FileStorage, and StorageV2. Valid values are Hot and Cool."
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be Hot or Cool."
  }
}

variable "min_tls_version" {
  description = "The minimum supported TLS version."
  type        = string
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Minimum TLS version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "enable_https_traffic_only" {
  description = "Whether HTTPS traffic only is enabled."
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Whether shared access key is enabled."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled."
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Whether nested items can be public."
  type        = bool
  default     = false
}

variable "is_hns_enabled" {
  description = "Whether hierarchical namespace (Data Lake Storage Gen2) is enabled."
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Whether NFSv3 protocol is enabled."
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Whether large file shares are enabled."
  type        = bool
  default     = false
}

variable "cross_tenant_replication_enabled" {
  description = "Whether cross-tenant replication is enabled."
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Whether infrastructure encryption is enabled."
  type        = bool
  default     = false
}

variable "identity_type" {
  description = "The type of managed identity."
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "A list of user-assigned managed identity IDs."
  type        = list(string)
  default     = []
}

variable "blob_properties" {
  description = "Blob service properties configuration."
  type = object({
    versioning_enabled       = optional(bool, false)
    change_feed_enabled      = optional(bool, false)
    last_access_time_enabled = optional(bool, false)
    default_service_version  = optional(string, null)

    delete_retention_policy = optional(object({
      days = optional(number, 7)
    }), null)

    container_delete_retention_policy = optional(object({
      days = optional(number, 7)
    }), null)

    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), [])
  })
  default = null
}

variable "static_website" {
  description = "Static website configuration."
  type = object({
    index_document     = optional(string, "index.html")
    error_404_document = optional(string, "404.html")
  })
  default = null
}

variable "containers" {
  description = "Map of blob containers to create."
  type = map(object({
    container_access_type = optional(string, "private")
    metadata              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.containers : contains(["blob", "container", "private"], v.container_access_type)
    ])
    error_message = "Container access type must be one of: blob, container, private."
  }
}

variable "file_shares" {
  description = "Map of file shares to create."
  type = map(object({
    quota            = optional(number, 50)
    access_tier      = optional(string, "TransactionOptimized")
    enabled_protocol = optional(string, "SMB")
    metadata         = optional(map(string), {})
    acl = optional(list(object({
      id = string
      access_policy = optional(object({
        permissions = string
        start       = optional(string, null)
        expiry      = optional(string, null)
      }), null)
    })), [])
  }))
  default = {}
}

variable "queues" {
  description = "Map of storage queues to create."
  type = map(object({
    metadata = optional(map(string), {})
  }))
  default = {}
}

variable "tables" {
  description = "Map of storage tables to create."
  type = map(object({
    acl = optional(list(object({
      id = string
      access_policy = optional(object({
        permissions = string
        start       = string
        expiry      = string
      }), null)
    })), [])
  }))
  default = {}
}

variable "management_policies" {
  description = "Lifecycle management policy rules."
  type = list(object({
    name    = string
    enabled = optional(bool, true)
    filters = object({
      prefix_match = optional(list(string), [])
      blob_types   = optional(list(string), ["blockBlob"])
      match_blob_index_tag = optional(list(object({
        name      = string
        operation = optional(string, "==")
        value     = string
      })), [])
    })
    actions = object({
      base_blob = optional(object({
        tier_to_cool_after_days_since_modification_greater_than    = optional(number, null)
        tier_to_archive_after_days_since_modification_greater_than = optional(number, null)
        delete_after_days_since_modification_greater_than          = optional(number, null)
      }), null)
      snapshot = optional(object({
        change_tier_to_cool_after_days_since_creation    = optional(number, null)
        change_tier_to_archive_after_days_since_creation = optional(number, null)
        delete_after_days_since_creation_greater_than    = optional(number, null)
      }), null)
      version = optional(object({
        change_tier_to_cool_after_days_since_creation    = optional(number, null)
        change_tier_to_archive_after_days_since_creation = optional(number, null)
        delete_after_days_since_creation                 = optional(number, null)
      }), null)
    })
  }))
  default = []
}

variable "immutability_policy" {
  description = "Account-level immutability policy."
  type = object({
    allow_protected_append_writes = bool
    state                         = string
    period_since_creation_in_days = number
  })
  default = null
}

variable "network_rules" {
  description = "Network rules for the storage account."
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string, null)
    })), [])
  })
  default = null
}

variable "private_endpoints" {
  description = "Map of private endpoints to create."
  type = map(object({
    subnet_id            = string
    subresource_names    = list(string)
    private_dns_zone_ids = optional(list(string), [])
    is_manual_connection = optional(bool, false)
    request_message      = optional(string, null)
  }))
  default = {}
}

variable "customer_managed_key" {
  description = "Customer-managed key configuration."
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  default = null
}

variable "diagnostic_settings" {
  description = "Map of diagnostic settings for the storage account."
  type = map(object({
    target_resource_type           = optional(string, "blob")
    log_analytics_workspace_id     = optional(string, null)
    storage_account_id             = optional(string, null)
    eventhub_name                  = optional(string, null)
    eventhub_authorization_rule_id = optional(string, null)
    enabled_log_categories         = optional(list(string), ["StorageRead", "StorageWrite", "StorageDelete"])
    metric_categories              = optional(list(string), ["Transaction", "Capacity"])
  }))
  default = {}
}

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}
