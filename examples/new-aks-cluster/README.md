# New AKS Cluster Example
In this example, we are creating a new AKS cluster for TFE along with all of the core TFE infrastructure resources.

NOTE: Not all machine sizes that AKS will attempt to deploy will be available in the region you set. It is possible that omitting aks_default_node_pool_vm_size in order to accept the default AKS would deploy, would result in the deployment failing because Azure cannot automatically assign a meaningful default in the specified region. We recommend specifying an explicit default in order to avoid this, with 8 cores and 32Gb RAM as a minimum for a production deployment.

```hcl
module "tfe" {
  source = "path/to/module"

  # --- Common --- #
  resource_group_name  = var.resource_group_name
  location             = var.location
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # --- Networking --- #
  vnet_id         = var.vnet_id
  aks_subnet_id   = var.aks_subnet_id
  db_subnet_id    = var.db_subnet_id
  redis_subnet_id = var.redis_subnet_id

  # --- AKS --- #
  aks_default_node_pool_vm_size = var.aks_default_node_pool_vm_size

  # --- Database --- #
  tfe_database_password_kv_id      = var.tfe_database_password_kv_id
  tfe_database_password_kv_name    = var.tfe_database_password_kv_name
  create_postgres_private_endpoint = var.create_postgres_private_endpoint

  # --- Object Storage --- #
  create_blob_storage_private_endpoint          = var.create_blob_storage_private_endpoint
  storage_account_ip_allow                    = var.storage_account_ip_allow
  storage_account_public_network_access_enabled = var.storage_account_public_network_access_enabled

  # --- Redis --- #
  create_redis_private_endpoint = var.create_redis_private_endpoint
}
```


---
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.95.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tfe"></a> [tfe](#module\_tfe) | ../.. | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_subnet_id"></a> [db\_subnet\_id](#input\_db\_subnet\_id) | Subnet ID for PostgreSQL database and Redis cache. | `string` | n/a | yes |
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix for uniquely naming Azure resources. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for this TFE deployment. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of Resource Group to create for this TFE deployment. | `string` | n/a | yes |
| <a name="input_tfe_database_password_keyvault_id"></a> [tfe\_database\_password\_keyvault\_id](#input\_tfe\_database\_password\_keyvault\_id) | Resource ID of the Key Vault that contains the TFE database password. | `string` | n/a | yes |
| <a name="input_tfe_database_password_keyvault_secret_name"></a> [tfe\_database\_password\_keyvault\_secret\_name](#input\_tfe\_database\_password\_keyvault\_secret\_name) | Name of the secret in the Key Vault that contains the TFE database password. | `string` | n/a | yes |
| <a name="input_tfe_fqdn"></a> [tfe\_fqdn](#input\_tfe\_fqdn) | Fully qualified domain name of TFE instance. This name should resolve to the load balancer IP address and will be what clients use to access TFE. | `string` | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | VNet ID where TFE resources will reside. | `string` | n/a | yes |
| <a name="input_aks_api_server_authorized_ip_ranges"></a> [aks\_api\_server\_authorized\_ip\_ranges](#input\_aks\_api\_server\_authorized\_ip\_ranges) | List of IP ranges that are allowed to access the AKS API server (control plane). | `list(string)` | `[]` | no |
| <a name="input_aks_dns_service_ip"></a> [aks\_dns\_service\_ip](#input\_aks\_dns\_service\_ip) | The IP address assigned to the AKS internal DNS service. | `string` | `"10.1.0.10"` | no |
| <a name="input_aks_kubernetes_version"></a> [aks\_kubernetes\_version](#input\_aks\_kubernetes\_version) | Kubernetes version for AKS cluster. | `string` | `"1.29.0"` | no |
| <a name="input_aks_node_pool_node_count"></a> [aks\_node\_pool\_node\_count](#input\_aks\_node\_pool\_node\_count) | The number of nodes in the node pool. | `number` | `2` | no |
| <a name="input_aks_node_pool_vm_size"></a> [aks\_node\_pool\_vm\_size](#input\_aks\_node\_pool\_vm\_size) | The size of the Virtual Machine. | `string` | `"Standard_D4_v2"` | no |
| <a name="input_aks_service_cidr"></a> [aks\_service\_cidr](#input\_aks\_service\_cidr) | IP range for Kubernetes services that can be used by AKS cluster. | `string` | `"10.1.0.0/16"` | no |
| <a name="input_aks_subnet_id"></a> [aks\_subnet\_id](#input\_aks\_subnet\_id) | Subnet ID for AKS cluster. | `string` | `null` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of Azure Availability Zones to spread TFE resources across. | `set(string)` | <pre>[<br>  "1",<br>  "2",<br>  "3"<br>]</pre> | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for taggable Azure resources. | `map(string)` | `{}` | no |
| <a name="input_create_aks_cluster"></a> [create\_aks\_cluster](#input\_create\_aks\_cluster) | Boolean to create a new AKS cluster for this TFE deployment. | `bool` | `true` | no |
| <a name="input_create_blob_storage_private_endpoint"></a> [create\_blob\_storage\_private\_endpoint](#input\_create\_blob\_storage\_private\_endpoint) | Boolean to create a private endpoint and private DNS zone for TFE Storage Account. | `bool` | `true` | no |
| <a name="input_create_helm_overrides_output_file"></a> [create\_helm\_overrides\_output\_file](#input\_create\_helm\_overrides\_output\_file) | Boolean to generate a YAML file from template with Helm overrides values for TFE deployment. | `bool` | `false` | no |
| <a name="input_create_postgres_private_endpoint"></a> [create\_postgres\_private\_endpoint](#input\_create\_postgres\_private\_endpoint) | Boolean to create a private endpoint and private DNS zone for PostgreSQL Flexible Server. | `bool` | `true` | no |
| <a name="input_create_redis_private_endpoint"></a> [create\_redis\_private\_endpoint](#input\_create\_redis\_private\_endpoint) | Boolean to create a private DNS zone and private endpoint for Redis cache. | `bool` | `true` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Boolean to create a new Resource Group for this TFE deployment. | `bool` | `true` | no |
| <a name="input_create_tfe_dns_record"></a> [create\_tfe\_dns\_record](#input\_create\_tfe\_dns\_record) | Boolean to create a DNS record for TFE. When `true`, `dns_zone_name` is also required. | `bool` | `false` | no |
| <a name="input_dns_zone_is_private"></a> [dns\_zone\_is\_private](#input\_dns\_zone\_is\_private) | Determines if Azure DNS zone provided via `dns_zone_name` is public or private. | `bool` | `false` | no |
| <a name="input_is_govcloud_region"></a> [is\_govcloud\_region](#input\_is\_govcloud\_region) | Boolean indicating whether this TFE deployment is in an Azure Government Cloud region. | `bool` | `false` | no |
| <a name="input_is_secondary_region"></a> [is\_secondary\_region](#input\_is\_secondary\_region) | Boolean indicating whether this TFE deployment is for 'primary' region or 'secondary' region. | `bool` | `false` | no |
| <a name="input_postgres_administrator_login"></a> [postgres\_administrator\_login](#input\_postgres\_administrator\_login) | Username for administrator login of PostreSQL database. | `string` | `"tfe"` | no |
| <a name="input_postgres_backup_retention_days"></a> [postgres\_backup\_retention\_days](#input\_postgres\_backup\_retention\_days) | Number of days to retain backups of PostgreSQL Flexible Server. | `number` | `35` | no |
| <a name="input_postgres_create_mode"></a> [postgres\_create\_mode](#input\_postgres\_create\_mode) | Determines if the PostgreSQL Flexible Server is being created as a new server or as a replica. | `string` | `"Default"` | no |
| <a name="input_postgres_enable_high_availability"></a> [postgres\_enable\_high\_availability](#input\_postgres\_enable\_high\_availability) | Boolean to enable `ZoneRedundant` high availability with PostgreSQL database. | `bool` | `false` | no |
| <a name="input_postgres_geo_redundant_backup_enabled"></a> [postgres\_geo\_redundant\_backup\_enabled](#input\_postgres\_geo\_redundant\_backup\_enabled) | Boolean to enable PostreSQL geo-redundant backup configuration in paired Azure region. | `bool` | `true` | no |
| <a name="input_postgres_primary_availability_zone"></a> [postgres\_primary\_availability\_zone](#input\_postgres\_primary\_availability\_zone) | Number for the availability zone for the db to reside in | `number` | `1` | no |
| <a name="input_postgres_secondary_availability_zone"></a> [postgres\_secondary\_availability\_zone](#input\_postgres\_secondary\_availability\_zone) | Number for the availability zone for the db to reside in for the secondary node | `number` | `2` | no |
| <a name="input_postgres_sku"></a> [postgres\_sku](#input\_postgres\_sku) | PostgreSQL database SKU. | `string` | `"GP_Standard_D2ds_v4"` | no |
| <a name="input_postgres_storage_mb"></a> [postgres\_storage\_mb](#input\_postgres\_storage\_mb) | Storage capacity of PostgreSQL Flexible Server (unit is megabytes). | `number` | `65536` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | PostgreSQL database version. | `number` | `15` | no |
| <a name="input_redis_capacity"></a> [redis\_capacity](#input\_redis\_capacity) | The size of the Redis cache to deploy. Valid values for a SKU family of C (Basic/Standard) are 0, 1, 2, 3, 4, 5, 6, and for P (Premium) family are 1, 2, 3, 4. | `number` | `1` | no |
| <a name="input_redis_enable_authentication"></a> [redis\_enable\_authentication](#input\_redis\_enable\_authentication) | Boolean to enable authentication to the Redis cache. | `bool` | `true` | no |
| <a name="input_redis_enable_non_ssl_port"></a> [redis\_enable\_non\_ssl\_port](#input\_redis\_enable\_non\_ssl\_port) | Boolean to enable port non-SSL port 6379 for Redis cache. Must be `true` when `redis_enable_authentication` is `false`. | `bool` | `false` | no |
| <a name="input_redis_family"></a> [redis\_family](#input\_redis\_family) | The SKU family/pricing group to use. Valid values are C (for Basic/Standard SKU family) and P (for Premium). | `string` | `"P"` | no |
| <a name="input_redis_min_tls_version"></a> [redis\_min\_tls\_version](#input\_redis\_min\_tls\_version) | The Minimum TLS version to use when SSL authentication is used. | `string` | `"1.2"` | no |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | The port to access redis on. If ssl only access is enabled, the default port is 6380. The non-ssl defualt port is 6379. | `string` | `"6380"` | no |
| <a name="input_redis_sku_name"></a> [redis\_sku\_name](#input\_redis\_sku\_name) | Which SKU of Redis to use. Options are 'Basic', 'Standard', or 'Premium'. | `string` | `"Premium"` | no |
| <a name="input_redis_subnet_id"></a> [redis\_subnet\_id](#input\_redis\_subnet\_id) | Subnet ID for Redis cache. | `string` | `null` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis cache version. Only the major version is needed. | `number` | `6` | no |
| <a name="input_secondary_aks_subnet_id"></a> [secondary\_aks\_subnet\_id](#input\_secondary\_aks\_subnet\_id) | Used for storage account replication for secondary region deployments only. AKS subnet ID for TFE AKS cluster in secondary region. | `string` | `null` | no |
| <a name="input_storage_account_ip_allow"></a> [storage\_account\_cidr\_allow](#input\_storage\_account\_cidr\_allow) | List of CIDRs allowed to access TFE Storage Account. | `list(string)` | `[]` | no |
| <a name="input_storage_account_public_network_access_enabled"></a> [storage\_account\_public\_network\_access\_enabled](#input\_storage\_account\_public\_network\_access\_enabled) | Boolean to enable public network access to Azure Blob Storage Account. Needs to be `true` for initial creation. Set to `false` after initial creation. | `bool` | `true` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | Which type of replication to use for TFE Storage Account. | `string` | `"LRS"` | no |
| <a name="input_tfe_database_name"></a> [tfe\_database\_name](#input\_tfe\_database\_name) | PostgreSQL database name for TFE. | `string` | `"tfe"` | no |
| <a name="input_tfe_image_name"></a> [tfe\_image\_name](#input\_tfe\_image\_name) | Name of the TFE container image. Only set this if you are hosting the TFE container image in your own custom repository. | `string` | `"hashicorp/terraform-enterprise"` | no |
| <a name="input_tfe_image_repository"></a> [tfe\_image\_repository](#input\_tfe\_image\_repository) | Repository for the TFE image. Only set this if you are hosting the TFE container image in your own custom repository. | `string` | `"images.releases.hashicorp.com"` | no |
| <a name="input_tfe_image_tag"></a> [tfe\_image\_tag](#input\_tfe\_image\_tag) | Tag for the TFE image. This represents the version of TFE to deploy. | `string` | `"v202402-1"` | no |
| <a name="input_tfe_kube_namespace"></a> [tfe\_kube\_namespace](#input\_tfe\_kube\_namespace) | Kubernetes namespace for TFE deployment. | `string` | `"tfe"` | no |
| <a name="input_tfe_kube_service_account"></a> [tfe\_kube\_service\_account](#input\_tfe\_kube\_service\_account) | Kubernetes service account for TFE deployment. | `string` | `"tfe"` | no |
| <a name="input_tfe_object_storage_azure_use_msi"></a> [tfe\_object\_storage\_azure\_use\_msi](#input\_tfe\_object\_storage\_azure\_use\_msi) | Boolean to use a Managed Service Identity (MSI) for TFE blob storage authentication. Requires additional configuration in your AKS cluster related to AAD Pod Identity. | `bool` | `false` | no |
| <a name="input_tfe_primary_resource_group_name"></a> [tfe\_primary\_resource\_group\_name](#input\_tfe\_primary\_resource\_group\_name) | Used for secondary region deployments only. Resource group name of TFE deployment in primary region. | `string` | `null` | no |
| <a name="input_tfe_primary_storage_account_name"></a> [tfe\_primary\_storage\_account\_name](#input\_tfe\_primary\_storage\_account\_name) | Used for secondary region deployments only. Storage account name of the TFE deployment in primary region. | `string` | `null` | no |
| <a name="input_tfe_primary_storage_container_name"></a> [tfe\_primary\_storage\_container\_name](#input\_tfe\_primary\_storage\_container\_name) | Used for storage account replication for secondary region deployments only. Storage container name of the TFE deployment in primary region. | `string` | `null` | no |
| <a name="input_tfe_private_dns_zone_name"></a> [tfe\_private\_dns\_zone\_name](#input\_tfe\_private\_dns\_zone\_name) | Name of existing Azure DNS zone to create DNS record in. Only valid if `create_dns_record` is `true`. | `string` | `null` | no |
| <a name="input_tfe_private_dns_zone_rg"></a> [tfe\_private\_dns\_zone\_rg](#input\_tfe\_private\_dns\_zone\_rg) | Name of Resource Group where `private_dns_zone_name` resides. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tfe_database_host"></a> [tfe\_database\_host](#output\_tfe\_database\_host) | ------------------------------------------------------------------------------ Database ------------------------------------------------------------------------------ |
| <a name="output_tfe_database_name"></a> [tfe\_database\_name](#output\_tfe\_database\_name) | n/a |
| <a name="output_tfe_database_password"></a> [tfe\_database\_password](#output\_tfe\_database\_password) | n/a |
| <a name="output_tfe_database_password_base64"></a> [tfe\_database\_password\_base64](#output\_tfe\_database\_password\_base64) | n/a |
| <a name="output_tfe_database_user"></a> [tfe\_database\_user](#output\_tfe\_database\_user) | n/a |
| <a name="output_tfe_object_storage_azure_account_key"></a> [tfe\_object\_storage\_azure\_account\_key](#output\_tfe\_object\_storage\_azure\_account\_key) | n/a |
| <a name="output_tfe_object_storage_azure_account_key_base64"></a> [tfe\_object\_storage\_azure\_account\_key\_base64](#output\_tfe\_object\_storage\_azure\_account\_key\_base64) | n/a |
| <a name="output_tfe_object_storage_azure_account_name"></a> [tfe\_object\_storage\_azure\_account\_name](#output\_tfe\_object\_storage\_azure\_account\_name) | ------------------------------------------------------------------------------ Blob Storage ------------------------------------------------------------------------------ |
| <a name="output_tfe_object_storage_azure_container"></a> [tfe\_object\_storage\_azure\_container](#output\_tfe\_object\_storage\_azure\_container) | n/a |
| <a name="output_tfe_object_storage_azure_use_msi"></a> [tfe\_object\_storage\_azure\_use\_msi](#output\_tfe\_object\_storage\_azure\_use\_msi) | n/a |
| <a name="output_tfe_redis_host"></a> [tfe\_redis\_host](#output\_tfe\_redis\_host) | ------------------------------------------------------------------------------ Redis Cache ------------------------------------------------------------------------------ |
| <a name="output_tfe_redis_password"></a> [tfe\_redis\_password](#output\_tfe\_redis\_password) | n/a |
| <a name="output_tfe_redis_password_base64"></a> [tfe\_redis\_password\_base64](#output\_tfe\_redis\_password\_base64) | n/a |
<!-- END_TF_DOCS -->