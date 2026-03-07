###############################################################################
# Storage Account
###############################################################################

resource "azurerm_storage_account" "this" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_tier                     = var.account_tier
  account_replication_type         = var.account_replication_type
  account_kind                     = var.account_kind
  access_tier                      = var.access_tier
  min_tls_version                  = var.min_tls_version
  enable_https_traffic_only        = var.enable_https_traffic_only
  shared_access_key_enabled        = var.shared_access_key_enabled
  public_network_access_enabled    = var.public_network_access_enabled
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  is_hns_enabled                   = var.is_hns_enabled
  nfsv3_enabled                    = var.nfsv3_enabled
  large_file_share_enabled         = var.large_file_share_enabled
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    content {
      versioning_enabled       = blob_properties.value.versioning_enabled
      change_feed_enabled      = blob_properties.value.change_feed_enabled
      last_access_time_enabled = blob_properties.value.last_access_time_enabled
      default_service_version  = blob_properties.value.default_service_version

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy != null ? [blob_properties.value.delete_retention_policy] : []
        content {
          days = delete_retention_policy.value.days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy != null ? [blob_properties.value.container_delete_retention_policy] : []
        content {
          days = container_delete_retention_policy.value.days
        }
      }

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = var.static_website != null ? [var.static_website] : []
    content {
      index_document     = static_website.value.index_document
      error_404_document = static_website.value.error_404_document
    }
  }

  dynamic "immutability_policy" {
    for_each = var.immutability_policy != null ? [var.immutability_policy] : []
    content {
      allow_protected_append_writes = immutability_policy.value.allow_protected_append_writes
      state                         = immutability_policy.value.state
      period_since_creation_in_days = immutability_policy.value.period_since_creation_in_days
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids

      dynamic "private_link_access" {
        for_each = network_rules.value.private_link_access
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  tags = local.merged_tags
}

###############################################################################
# Blob Containers
###############################################################################

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = each.value.container_access_type
  metadata              = each.value.metadata
}

###############################################################################
# File Shares
###############################################################################

resource "azurerm_storage_share" "this" {
  for_each = var.file_shares

  name                 = each.key
  storage_account_name = azurerm_storage_account.this.name
  quota                = each.value.quota
  access_tier          = each.value.access_tier
  enabled_protocol     = each.value.enabled_protocol
  metadata             = each.value.metadata

  dynamic "acl" {
    for_each = each.value.acl
    content {
      id = acl.value.id

      dynamic "access_policy" {
        for_each = acl.value.access_policy != null ? [acl.value.access_policy] : []
        content {
          permissions = access_policy.value.permissions
          start       = access_policy.value.start
          expiry      = access_policy.value.expiry
        }
      }
    }
  }
}

###############################################################################
# Queues
###############################################################################

resource "azurerm_storage_queue" "this" {
  for_each = var.queues

  name                 = each.key
  storage_account_name = azurerm_storage_account.this.name
  metadata             = each.value.metadata
}

###############################################################################
# Tables
###############################################################################

resource "azurerm_storage_table" "this" {
  for_each = var.tables

  name                 = each.key
  storage_account_name = azurerm_storage_account.this.name

  dynamic "acl" {
    for_each = each.value.acl
    content {
      id = acl.value.id

      dynamic "access_policy" {
        for_each = acl.value.access_policy != null ? [acl.value.access_policy] : []
        content {
          permissions = access_policy.value.permissions
          start       = access_policy.value.start
          expiry      = access_policy.value.expiry
        }
      }
    }
  }
}

###############################################################################
# Lifecycle Management Policy
###############################################################################

resource "azurerm_storage_management_policy" "this" {
  count = length(var.management_policies) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.management_policies
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        prefix_match = rule.value.filters.prefix_match
        blob_types   = rule.value.filters.blob_types

        dynamic "match_blob_index_tag" {
          for_each = rule.value.filters.match_blob_index_tag
          content {
            name      = match_blob_index_tag.value.name
            operation = match_blob_index_tag.value.operation
            value     = match_blob_index_tag.value.value
          }
        }
      }

      actions {
        dynamic "base_blob" {
          for_each = rule.value.actions.base_blob != null ? [rule.value.actions.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = base_blob.value.tier_to_cool_after_days_since_modification_greater_than
            tier_to_archive_after_days_since_modification_greater_than = base_blob.value.tier_to_archive_after_days_since_modification_greater_than
            delete_after_days_since_modification_greater_than          = base_blob.value.delete_after_days_since_modification_greater_than
          }
        }

        dynamic "snapshot" {
          for_each = rule.value.actions.snapshot != null ? [rule.value.actions.snapshot] : []
          content {
            change_tier_to_cool_after_days_since_creation    = snapshot.value.change_tier_to_cool_after_days_since_creation
            change_tier_to_archive_after_days_since_creation = snapshot.value.change_tier_to_archive_after_days_since_creation
            delete_after_days_since_creation_greater_than    = snapshot.value.delete_after_days_since_creation_greater_than
          }
        }

        dynamic "version" {
          for_each = rule.value.actions.version != null ? [rule.value.actions.version] : []
          content {
            change_tier_to_cool_after_days_since_creation    = version.value.change_tier_to_cool_after_days_since_creation
            change_tier_to_archive_after_days_since_creation = version.value.change_tier_to_archive_after_days_since_creation
            delete_after_days_since_creation                 = version.value.delete_after_days_since_creation
          }
        }
      }
    }
  }
}

###############################################################################
# Private Endpoints
###############################################################################

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = "${var.name}-pe-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "${var.name}-psc-${each.key}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = each.value.is_manual_connection
    request_message                = each.value.is_manual_connection ? each.value.request_message : null
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "${var.name}-dnsgroup-${each.key}"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  }

  tags = local.merged_tags
}

###############################################################################
# Diagnostic Settings
###############################################################################

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.key
  target_resource_id             = lookup(local.diagnostic_target_map, each.value.target_resource_type, local.diagnostic_target_map["blob"])
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  storage_account_id             = each.value.storage_account_id
  eventhub_name                  = each.value.eventhub_name
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id

  dynamic "enabled_log" {
    for_each = each.value.enabled_log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}
