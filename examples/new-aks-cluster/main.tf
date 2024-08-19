
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
  vnet_id          = var.vnet_id
  tfe_lb_subnet_id = var.tfe_lb_subnet_id
  aks_subnet_id    = var.aks_subnet_id
  db_subnet_id     = var.db_subnet_id
  redis_subnet_id  = var.redis_subnet_id

  # --- DNS --- #
  create_tfe_private_dns_record = var.create_tfe_private_dns_record
  private_dns_zone_name         = var.private_dns_zone_name
  private_dns_zone_rg_name      = var.private_dns_zone_rg_name
  tfe_dns_record_target         = var.tfe_dns_record_target

  # --- AKS --- #
  create_aks_cluster                  = var.create_aks_cluster
  aks_kubernetes_version              = var.aks_kubernetes_version
  aks_api_server_authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges
  aks_default_node_pool_vm_size       = var.aks_default_node_pool_vm_size
  create_aks_tfe_node_pool            = var.create_aks_tfe_node_pool
  aks_tfe_node_pool_vm_size           = var.aks_tfe_node_pool_vm_size

  # --- Database --- #
  tfe_database_password_keyvault_id          = var.tfe_database_password_keyvault_id
  tfe_database_password_keyvault_secret_name = var.tfe_database_password_keyvault_secret_name

  # --- Object storage --- #
  storage_account_ip_allow = var.storage_account_ip_allow
}