# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Resource group
#------------------------------------------------------------------------------
output "resource_group_name" {
  value       = local.resource_group_name
  description = "Name of the resource group."
}

#------------------------------------------------------------------------------
# AKS
#------------------------------------------------------------------------------
output "aks_cluster_name" {
  value       = try(azurerm_kubernetes_cluster.tfe[0].name, null)
  description = "Name of the AKS cluster."
}

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
output "tfe_database_host" {
  value       = try("${azurerm_postgresql_flexible_server.tfe.fqdn}:5432", null)
  description = "Fully qualified domain name (FQDN) and port of the PostgreSQL flexible server."
}

output "tfe_database_name" {
  value       = try(azurerm_postgresql_flexible_server_database.tfe.name, null)
  description = "Name of the PostgreSQL flexible server TFE database."
}

output "tfe_database_user" {
  value       = try(azurerm_postgresql_flexible_server.tfe.administrator_login, null)
  description = "Username of the PostgreSQL flexible server TFE database."
}

output "tfe_database_password" {
  value       = try(azurerm_postgresql_flexible_server.tfe.administrator_password, null)
  description = "Password of the PostgreSQL flexible server TFE database."
  sensitive   = true
}

output "tfe_database_password_base64" {
  value       = try(base64encode(azurerm_postgresql_flexible_server.tfe.administrator_password), null)
  description = "Base64-encoded password of the PostgreSQL flexible server TFE database."
  sensitive   = true
}

#------------------------------------------------------------------------------
# Object storage
#------------------------------------------------------------------------------
output "tfe_object_storage_azure_account_name" {
  value       = try(azurerm_storage_account.tfe[0].name, null)
  description = "Name of the storage account for TFE object storage."
}

output "tfe_object_storage_azure_container" {
  value       = try(azurerm_storage_container.tfe[0].name, null)
  description = "Name of the storage account container for TFE object storage."
}

output "tfe_object_storage_azure_account_key" {
  value       = try(azurerm_storage_account.tfe[0].primary_access_key, null)
  description = "Primary access key of the storage account for TFE object storage."
  sensitive   = true
}

output "tfe_object_storage_azure_account_key_base64" {
  value       = try(base64encode(azurerm_storage_account.tfe[0].primary_access_key), null)
  description = "Base64-encoded primary access key of the storage account for TFE object storage."
  sensitive   = true
}

output "tfe_object_storage_azure_use_msi" {
  value       = var.tfe_object_storage_azure_use_msi
  description = "Boolean indicating whether TFE is using a managed identity (MSI) to access the storage account."
}

#------------------------------------------------------------------------------
# Redis
#------------------------------------------------------------------------------
output "tfe_redis_host" {
  value       = local.tfe_redis_uses_managed_redis ? azurerm_managed_redis.tfe[0].hostname : azurerm_redis_cache.tfe[0].hostname
  description = "Hostname of the primary Redis service used by TFE."
}

output "tfe_redis_password" {
  value       = local.tfe_redis_uses_managed_redis ? try(local.redis_main_default_database.primary_access_key, null) : azurerm_redis_cache.tfe[0].primary_access_key
  description = "Primary access key of the primary Redis service used by TFE."
  sensitive   = true
}

output "tfe_redis_password_base64" {
  value       = local.tfe_redis_uses_managed_redis ? (try(local.redis_main_default_database.primary_access_key, null) != null ? base64encode(local.redis_main_default_database.primary_access_key) : null) : base64encode(azurerm_redis_cache.tfe[0].primary_access_key)
  description = "Base64-encoded primary access key of the primary Redis service used by TFE."
  sensitive   = true
}

output "tfe_redis_use_auth" {
  value       = local.tfe_redis_uses_managed_redis ? try(local.redis_main_default_database.access_keys_authentication_enabled, true) : azurerm_redis_cache.tfe[0].redis_configuration[0].authentication_enabled
  description = "Boolean indicating whether TFE is using authentication to access the primary Redis service."
}

output "tfe_redis_sidekiq_host" {
  value       = local.tfe_redis_uses_managed_redis ? azurerm_managed_redis.tfe_sidekiq[0].hostname : null
  description = "Hostname of the Sidekiq Redis service used by TFE when Azure Managed Redis is selected."
}

output "tfe_redis_sidekiq_password" {
  value       = local.tfe_redis_uses_managed_redis ? try(local.redis_sidekiq_default_database.primary_access_key, null) : null
  description = "Primary access key of the Sidekiq Redis service used by TFE when Azure Managed Redis is selected."
  sensitive   = true
}

output "tfe_redis_sidekiq_password_base64" {
  value       = local.tfe_redis_uses_managed_redis ? (try(local.redis_sidekiq_default_database.primary_access_key, null) != null ? base64encode(local.redis_sidekiq_default_database.primary_access_key) : null) : null
  description = "Base64-encoded primary access key of the Sidekiq Redis service used by TFE when Azure Managed Redis is selected."
  sensitive   = true
}

output "tfe_redis_sidekiq_use_auth" {
  value       = local.tfe_redis_uses_managed_redis ? try(local.redis_sidekiq_default_database.access_keys_authentication_enabled, true) : null
  description = "Boolean indicating whether TFE is using authentication to access the Sidekiq Redis service when Azure Managed Redis is selected."
}

#------------------------------------------------------------------------------
# Managed identity (MSI)
#------------------------------------------------------------------------------
output "tfe_object_storage_azure_client_id" {
  value       = try(azurerm_user_assigned_identity.tfe[0].client_id, null)
  description = "Client ID of the managed identity (MSI) used by TFE to access the storage account."
}

#------------------------------------------------------------------------------
# DNS
#------------------------------------------------------------------------------
output "tfe_public_dns_record_fqdn" {
  value       = try(azurerm_dns_a_record.tfe[0].fqdn, null)
  description = "Public DNS record for TFE."
}

output "tfe_private_dns_record_fqdn" {
  value       = try(azurerm_private_dns_a_record.tfe[0].fqdn, null)
  description = "Private DNS record for TFE."
}
