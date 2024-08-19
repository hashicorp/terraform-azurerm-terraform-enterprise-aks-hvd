#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
output "tfe_database_host" {
  value = module.tfe.tfe_database_host
}

output "tfe_database_name" {
  value = module.tfe.tfe_database_name
}

output "tfe_database_user" {
  value = module.tfe.tfe_database_user
}

output "tfe_database_password" {
  value     = module.tfe.tfe_database_password
  sensitive = true
}

output "tfe_database_password_base64" {
  value     = module.tfe.tfe_database_password_base64
  sensitive = true
}

#------------------------------------------------------------------------------
# Blob Storage
#------------------------------------------------------------------------------
output "tfe_object_storage_azure_account_name" {
  value = module.tfe.tfe_object_storage_azure_account_name
}

output "tfe_object_storage_azure_container" {
  value = module.tfe.tfe_object_storage_azure_container
}

output "tfe_object_storage_azure_account_key" {
  value     = module.tfe.tfe_object_storage_azure_account_key
  sensitive = true
}

output "tfe_object_storage_azure_account_key_base64" {
  value     = module.tfe.tfe_object_storage_azure_account_key_base64
  sensitive = true
}

output "tfe_object_storage_azure_use_msi" {
  value = module.tfe.tfe_object_storage_azure_use_msi
}

#------------------------------------------------------------------------------
# Redis Cache
#------------------------------------------------------------------------------
output "tfe_redis_host" {
  value = module.tfe.tfe_redis_host
}

output "tfe_redis_password" {
  value     = module.tfe.tfe_redis_password
  sensitive = true
}

output "tfe_redis_password_base64" {
  value     = module.tfe.tfe_redis_password_base64
  sensitive = true
}