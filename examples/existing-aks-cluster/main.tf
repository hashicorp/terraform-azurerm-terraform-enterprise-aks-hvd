# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "tfe" {
  source = "../.."

  # --- Common --- #
  resource_group_name  = var.resource_group_name
  location             = var.location
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # --- TFE config settings --- #
  tfe_fqdn                   = var.tfe_fqdn
  create_helm_overrides_file = var.create_helm_overrides_file

  # --- Networking --- #
  vnet_id         = var.vnet_id
  aks_subnet_id   = var.aks_subnet_id
  db_subnet_id    = var.db_subnet_id
  redis_subnet_id = var.redis_subnet_id

  # --- Database --- #
  tfe_database_password_keyvault_id          = var.tfe_database_password_keyvault_id
  tfe_database_password_keyvault_secret_name = var.tfe_database_password_keyvault_secret_name

  # --- Object storage --- #
  storage_account_ip_allow = var.storage_account_ip_allow
}