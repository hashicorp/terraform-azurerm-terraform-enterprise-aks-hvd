// This is a placeholder file for the remote backend configuration.
// When deploying this module in production, you should use the AzureRM Blob Storage remote backend.
// https://developer.hashicorp.com/terraform/language/settings/backends/azurerm

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "StorageAccount-ResourceGroup"
#     storage_account_name = "abcd1234"
#     container_name       = "tfstate"
#     key                  = "prod.terraform.tfstate"
#   }
# }