# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Redis
#------------------------------------------------------------------------------
resource "azurerm_redis_cache" "tfe" {
  count = local.tfe_redis_uses_managed_redis ? 0 : 1

  name                          = "${var.friendly_name_prefix}-tfe-redis"
  resource_group_name           = local.resource_group_name
  location                      = var.location
  capacity                      = var.redis_capacity
  family                        = var.redis_family
  sku_name                      = var.redis_sku_name
  non_ssl_port_enabled          = var.redis_enable_non_ssl_port
  minimum_tls_version           = var.redis_min_tls_version
  public_network_access_enabled = false
  subnet_id                     = var.create_redis_private_endpoint ? null : var.redis_subnet_id
  redis_version                 = var.redis_version
  zones                         = var.availability_zones

  redis_configuration {
    authentication_enabled = var.redis_enable_authentication
    rdb_backup_enabled     = false
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-redis" },
    var.common_tags
  )
}

resource "azurerm_managed_redis" "tfe" {
  count = local.tfe_redis_uses_managed_redis ? 1 : 0

  name                      = "${var.friendly_name_prefix}-tfe-redis"
  resource_group_name       = local.resource_group_name
  location                  = var.location
  sku_name                  = var.redis_managed_sku_name
  high_availability_enabled = var.redis_managed_high_availability_enabled
  public_network_access     = "Disabled"

  default_database {
    access_keys_authentication_enabled = var.redis_enable_authentication
    client_protocol                    = "Encrypted"
    clustering_policy                  = "EnterpriseCluster"
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-redis" },
    var.common_tags
  )
}

resource "azurerm_managed_redis" "tfe_sidekiq" {
  count = local.tfe_redis_uses_managed_redis ? 1 : 0

  name                      = "${var.friendly_name_prefix}-tfe-redis-sidekiq"
  resource_group_name       = local.resource_group_name
  location                  = var.location
  sku_name                  = var.redis_managed_sku_name
  high_availability_enabled = var.redis_managed_high_availability_enabled
  public_network_access     = "Disabled"

  default_database {
    access_keys_authentication_enabled = var.redis_enable_authentication
    client_protocol                    = "Encrypted"
    clustering_policy                  = "EnterpriseCluster"
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-redis-sidekiq" },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Private DNS zone and private endpoint
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "redis" {
  count = var.create_redis_private_endpoint ? 1 : 0

  name                = local.redis_private_dns_zone_name
  resource_group_name = local.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count = var.create_redis_private_endpoint ? 1 : 0

  name                  = "${var.friendly_name_prefix}-redis-priv-dns-vnet-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.common_tags
}

resource "azurerm_private_endpoint" "redis" {
  for_each = local.redis_private_endpoint_targets

  name                = "${var.friendly_name_prefix}-tfe-redis-${each.key}-private-endpoint"
  resource_group_name = local.resource_group_name
  location            = var.location
  subnet_id           = var.redis_subnet_id

  private_service_connection {
    name                           = "${var.friendly_name_prefix}-tfe-redis-${each.key}-private-connection"
    private_connection_resource_id = each.value.resource_id
    is_manual_connection           = false
    subresource_names              = [each.value.subresource_name]
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-redis-${each.key}-private-endpoint" },
    var.common_tags
  )
}

resource "azurerm_private_dns_a_record" "redis" {
  for_each = local.redis_private_endpoint_targets

  name                = each.value.dns_record_name
  resource_group_name = local.resource_group_name
  zone_name           = azurerm_private_dns_zone.redis[0].name
  ttl                 = 300
  records             = [azurerm_private_endpoint.redis[each.key].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}
