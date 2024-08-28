# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Storage account
#------------------------------------------------------------------------------
resource "azurerm_storage_account" "tfe" {
  count = var.is_secondary_region ? 0 : 1

  name                            = "${var.friendly_name_prefix}tfeblob"
  resource_group_name             = local.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  access_tier                     = "Hot"
  account_replication_type        = var.storage_account_replication_type
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = var.storage_account_public_network_access_enabled
  allow_nested_items_to_be_public = false

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}tfeblob" },
    var.common_tags
  )
}

resource "azurerm_storage_container" "tfe" {
  count = var.is_secondary_region ? 0 : 1

  name                  = "tfeblob"
  storage_account_name  = azurerm_storage_account.tfe[0].name
  container_access_type = "private"
}

resource "azurerm_storage_account_network_rules" "tfe" {
  count = var.is_secondary_region ? 0 : 1

  storage_account_id         = azurerm_storage_account.tfe[0].id
  default_action             = "Deny"
  ip_rules                   = var.storage_account_ip_allow
  virtual_network_subnet_ids = compact([var.aks_subnet_id, var.secondary_aks_subnet_id])
  bypass                     = ["AzureServices"]
}

#------------------------------------------------------------------------------
# Private DNS zone and private endpoint
#
# See the Azure docs for up to date private DNS zone values:
# https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#storage
#
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "blob_storage" {
  count = var.create_blob_storage_private_endpoint ? 1 : 0

  name                = var.is_govcloud_region ? "privatelink.blob.core.usgovcloudapi.net" : "privatelink.blob.core.windows.net"
  resource_group_name = local.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_storage" {
  count = var.create_blob_storage_private_endpoint ? 1 : 0

  name                  = "${var.friendly_name_prefix}-blob-priv-dns-vnet-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob_storage[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.common_tags
}

resource "azurerm_private_endpoint" "blob_storage" {
  count = var.create_blob_storage_private_endpoint ? 1 : 0

  name                = "${var.friendly_name_prefix}-tfe-blob-storage-priv-endpoint"
  resource_group_name = local.resource_group_name
  location            = var.location
  subnet_id           = var.aks_subnet_id

  private_service_connection {
    name                           = "tfe-blob-storage-priv-endpoint-connection"
    private_connection_resource_id = azurerm_storage_account.tfe[0].id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  depends_on = [
    azurerm_storage_account.tfe,
    azurerm_storage_account_network_rules.tfe
  ]

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-blob-storage-priv-endpoint" },
    var.common_tags
  )
}

resource "azurerm_private_dns_a_record" "blob_storage" {
  count = var.create_blob_storage_private_endpoint ? 1 : 0

  name                = azurerm_storage_account.tfe[0].name
  resource_group_name = local.resource_group_name
  zone_name           = azurerm_private_dns_zone.blob_storage[0].name
  ttl                 = 10
  records             = [azurerm_private_endpoint.blob_storage[0].private_service_connection.0.private_ip_address]
  tags                = var.common_tags

  depends_on = [
    azurerm_private_endpoint.blob_storage
  ]
}