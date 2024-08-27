# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "azurerm_resource_group" "tfe" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location

  tags = merge(
    { "Name" = var.resource_group_name },
    var.common_tags
  )
}

// Allow users to bring their own resource group or let this module create a new one.
locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.tfe[0].name : var.resource_group_name
}

