#------------------------------------------------------------------------------
# Redis cache
#------------------------------------------------------------------------------
resource "azurerm_redis_cache" "tfe" {
  name                          = "${var.friendly_name_prefix}-tfe-redis"
  resource_group_name           = local.resource_group_name
  location                      = var.location
  capacity                      = var.redis_capacity
  family                        = var.redis_family
  sku_name                      = var.redis_sku_name
  enable_non_ssl_port           = var.redis_enable_non_ssl_port
  minimum_tls_version           = var.redis_min_tls_version
  public_network_access_enabled = false
  subnet_id                     = var.create_redis_private_endpoint ? null : var.redis_subnet_id
  redis_version                 = var.redis_version
  zones                         = var.availability_zones

  redis_configuration {
    enable_authentication = var.redis_enable_authentication
    rdb_backup_enabled    = false
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-redis" },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Private DNS zone and private endpoint
#
# See the Azure docs for up to date private DNS zone values:
# https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#databases
#
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "redis" {
  count = var.create_redis_private_endpoint ? 1 : 0

  name                = var.is_govcloud_region ? "privatelink.redis.cache.usgovcloudapi.net" : "privatelink.redis.cache.windows.net"
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
  count = var.create_redis_private_endpoint ? 1 : 0

  name                = "${var.friendly_name_prefix}-tfe-redis-private-endpoint"
  resource_group_name = local.resource_group_name
  location            = var.location
  subnet_id           = var.redis_subnet_id

  private_service_connection {
    name                           = "${var.friendly_name_prefix}-tfe-redis-private-connection"
    private_connection_resource_id = azurerm_redis_cache.tfe.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-redis-private-endpoint" },
    var.common_tags
  )
}

resource "azurerm_private_dns_a_record" "redis" {
  count = var.create_redis_private_endpoint ? 1 : 0

  name                = azurerm_redis_cache.tfe.name
  resource_group_name = local.resource_group_name
  zone_name           = azurerm_private_dns_zone.redis[0].name
  ttl                 = 300
  records             = [azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}