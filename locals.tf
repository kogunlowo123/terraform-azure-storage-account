locals {
  # Default tags
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "terraform-azure-storage-account"
  }

  merged_tags = merge(local.default_tags, var.tags)

  # Diagnostic target resource IDs
  diagnostic_target_map = {
    blob  = "${azurerm_storage_account.this.id}/blobServices/default"
    file  = "${azurerm_storage_account.this.id}/fileServices/default"
    queue = "${azurerm_storage_account.this.id}/queueServices/default"
    table = "${azurerm_storage_account.this.id}/tableServices/default"
  }
}
