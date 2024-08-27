# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Key Vault secret for PostgreSQL database password lookup
#------------------------------------------------------------------------------

data "azurerm_key_vault_secret" "tfe_database_password" {
  name         = var.tfe_database_password_keyvault_secret_name
  key_vault_id = var.tfe_database_password_keyvault_id
}

#------------------------------------------------------------------------------
# PostgreSQL flexible server
#------------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "tfe" {
  name                          = "${var.friendly_name_prefix}-tfe-postgres-db"
  resource_group_name           = var.is_secondary_region ? var.tfe_primary_resource_group_name : local.resource_group_name
  location                      = var.location
  version                       = var.postgres_version
  sku_name                      = var.postgres_sku
  storage_mb                    = var.postgres_storage_mb
  delegated_subnet_id           = var.db_subnet_id
  private_dns_zone_id           = var.create_postgres_private_endpoint ? azurerm_private_dns_zone.postgres[0].id : null
  zone                          = var.postgres_primary_availability_zone
  public_network_access_enabled = false
  administrator_login           = var.tfe_database_user
  administrator_password        = data.azurerm_key_vault_secret.tfe_database_password.value
  backup_retention_days         = var.postgres_backup_retention_days
  geo_redundant_backup_enabled  = var.postgres_geo_redundant_backup_enabled
  create_mode                   = var.postgres_create_mode

  dynamic "high_availability" {
    for_each = var.postgres_enable_high_availability ? [1] : []

    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = var.postgres_secondary_availability_zone
    }
  }

  maintenance_window {
    day_of_week  = var.postgres_maintenance_window["day_of_week"]
    start_hour   = var.postgres_maintenance_window["start_hour"]
    start_minute = var.postgres_maintenance_window["start_minute"]
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-postgres-db" },
    var.common_tags
  )

  // We ignore the `create_mode` change, as the AzureRM provider
  // and SDK do not support GeoRestore at this time.
  lifecycle {
    ignore_changes = [
      create_mode,
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "tfe" {
  name      = var.tfe_database_name
  server_id = azurerm_postgresql_flexible_server.tfe.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_configuration" "tfe" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.tfe.id
  value     = "CITEXT,HSTORE,UUID-OSSP"
}

#------------------------------------------------------------------------------
# Private DNS zone and private endpoint
#
# See the Azure docs for up to date private DNS zone values:
# https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#databases
#
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "postgres" {
  count = var.create_postgres_private_endpoint ? 1 : 0

  name                = var.is_govcloud_region ? "privatelink.postgres.database.usgovcloudapi.net" : "privatelink.postgres.database.azure.com"
  resource_group_name = local.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count = var.create_postgres_private_endpoint ? 1 : 0

  name                  = "${var.friendly_name_prefix}-pg-priv-dns-zone-vnet-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.common_tags
}