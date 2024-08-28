# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# DNS zone lookup
#------------------------------------------------------------------------------
data "azurerm_dns_zone" "tfe" {
  count = var.create_tfe_public_dns_record && var.public_dns_zone_name != null ? 1 : 0

  name                = var.public_dns_zone_name
  resource_group_name = var.public_dns_zone_rg_name
}

data "azurerm_private_dns_zone" "tfe" {
  count = var.create_tfe_private_dns_record && var.private_dns_zone_name != null ? 1 : 0

  name                = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg_name
}

#------------------------------------------------------------------------------
# DNS A Record
#------------------------------------------------------------------------------
locals {
  tfe_hostname_public  = var.create_tfe_public_dns_record && var.public_dns_zone_name != null ? trimsuffix(substr(var.tfe_fqdn, 0, length(var.tfe_fqdn) - length(var.public_dns_zone_name) - 1), ".") : var.tfe_fqdn
  tfe_hostname_private = var.create_tfe_private_dns_record && var.private_dns_zone_name != null ? trim(split(var.private_dns_zone_name, var.tfe_fqdn)[0], ".") : var.tfe_fqdn
}

resource "azurerm_dns_a_record" "tfe" {
  count = var.create_tfe_public_dns_record && var.public_dns_zone_name != null ? 1 : 0

  name                = local.tfe_hostname_public
  resource_group_name = var.public_dns_zone_rg_name
  zone_name           = data.azurerm_dns_zone.tfe[0].name
  ttl                 = 300
  records             = [var.tfe_dns_record_target]
  tags                = var.common_tags
}

resource "azurerm_private_dns_a_record" "tfe" {
  count = var.create_tfe_private_dns_record && var.private_dns_zone_name != null ? 1 : 0

  name                = local.tfe_hostname_private
  resource_group_name = var.private_dns_zone_rg_name
  zone_name           = data.azurerm_private_dns_zone.tfe[0].name
  ttl                 = 300
  records             = [var.tfe_dns_record_target]
  tags                = var.common_tags
}

// This should be a networking prereq
# resource "azurerm_private_dns_zone_virtual_network_link" "tfe" {
#   count = var.create_tfe_private_dns_record && var.private_dns_zone_name != null ? 1 : 0

#   name                  = "${var.friendly_name_prefix}-tfe-priv-dns-zone-vnet-link"
#   resource_group_name   = var.private_dns_zone_rg_name
#   private_dns_zone_name = data.azurerm_private_dns_zone.tfe[0].name
#   virtual_network_id    = var.vnet_id
#   tags                  = var.common_tags
# }