# Existing AKS Cluster Example
In this example, we are bringing our own AKS cluster and instructing the module not to create one for us. All of the other core TFE resources will be created.

```hcl
module "tfe" {
  source = "path/to/module"

  # --- Common --- #
  resource_group_name  = var.resource_group_name
  location             = var.location
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # --- TFE config settings --- #
  tfe_fqdn      = var.tfe_fqdn
  tfe_image_tag = var.tfe_image_tag

  # --- Networking --- #
  vnet_id         = var.vnet_id
  aks_subnet_id   = var.aks_subnet_id
  db_subnet_id    = var.db_subnet_id
  redis_subnet_id = var.redis_subnet_id
  
  # --- AKS --- #
  create_aks_cluster = var.create_aks_cluster
  
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
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.67 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tfe"></a> [tfe](#module\_tfe) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_api_server_authorized_ip_ranges"></a> [aks\_api\_server\_authorized\_ip\_ranges](#input\_aks\_api\_server\_authorized\_ip\_ranges) | List of IP ranges that are allowed to access the AKS API server (control plane). | `list(string)` | `[]` | no |
| <a name="input_aks_default_node_pool_max_surge"></a> [aks\_default\_node\_pool\_max\_surge](#input\_aks\_default\_node\_pool\_max\_surge) | The maximum number of nodes that can be added during an upgrade. | `string` | `"10%"` | no |
| <a name="input_aks_default_node_pool_name"></a> [aks\_default\_node\_pool\_name](#input\_aks\_default\_node\_pool\_name) | Name of default node pool. | `string` | `"default"` | no |
| <a name="input_aks_default_node_pool_node_count"></a> [aks\_default\_node\_pool\_node\_count](#input\_aks\_default\_node\_pool\_node\_count) | Number of nodes to run in the AKS default node pool. | `number` | `2` | no |
| <a name="input_aks_default_node_pool_vm_size"></a> [aks\_default\_node\_pool\_vm\_size](#input\_aks\_default\_node\_pool\_vm\_size) | Size of the virtual machines within the AKS default node pool. | `string` | `"Standard_D8ds_v5"` | no |
| <a name="input_aks_dns_service_ip"></a> [aks\_dns\_service\_ip](#input\_aks\_dns\_service\_ip) | The IP address assigned to the AKS internal DNS service. | `string` | `"10.1.0.10"` | no |
| <a name="input_aks_kubernetes_version"></a> [aks\_kubernetes\_version](#input\_aks\_kubernetes\_version) | Kubernetes version for AKS cluster. | `string` | `"1.29.6"` | no |
| <a name="input_aks_oidc_issuer_enabled"></a> [aks\_oidc\_issuer\_enabled](#input\_aks\_oidc\_issuer\_enabled) | Boolean to enable OIDC issuer for the AKS cluster. | `bool` | `true` | no |
| <a name="input_aks_role_based_access_control_enabled"></a> [aks\_role\_based\_access\_control\_enabled](#input\_aks\_role\_based\_access\_control\_enabled) | Boolean to enable Role-Based Access Control (RBAC) for the AKS cluster. | `bool` | `true` | no |
| <a name="input_aks_service_cidr"></a> [aks\_service\_cidr](#input\_aks\_service\_cidr) | IP range for Kubernetes services that can be used by AKS cluster. | `string` | `"10.1.0.0/16"` | no |
| <a name="input_aks_subnet_id"></a> [aks\_subnet\_id](#input\_aks\_subnet\_id) | Subnet ID for AKS cluster. | `string` | `null` | no |
| <a name="input_aks_tfe_node_pool_name"></a> [aks\_tfe\_node\_pool\_name](#input\_aks\_tfe\_node\_pool\_name) | Name of TFE node pool. Only valid when `create_aks_tfe_node_pool` is `true`. | `string` | `"tfeaksnodes"` | no |
| <a name="input_aks_tfe_node_pool_node_count"></a> [aks\_tfe\_node\_pool\_node\_count](#input\_aks\_tfe\_node\_pool\_node\_count) | Number of nodes in the AKS TFE node pool. Only valid when `create_aks_tfe_node_pool` is `true`. | `number` | `2` | no |
| <a name="input_aks_tfe_node_pool_vm_size"></a> [aks\_tfe\_node\_pool\_vm\_size](#input\_aks\_tfe\_node\_pool\_vm\_size) | Size of virtual machines in the AKS TFE node pool. Only valid when `create_aks_tfe_node_pool` is `true`. | `string` | `"Standard_D8ds_v5"` | no |
| <a name="input_aks_workload_identity_enabled"></a> [aks\_workload\_identity\_enabled](#input\_aks\_workload\_identity\_enabled) | Boolean to enable Workload Identity for the AKS cluster. | `bool` | `true` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of Azure availability zones to spread TFE resources across. | `set(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for taggable Azure resources. | `map(string)` | `{}` | no |
| <a name="input_create_aks_cluster"></a> [create\_aks\_cluster](#input\_create\_aks\_cluster) | Boolean to create a new AKS cluster for this TFE deployment. | `bool` | `false` | no |
| <a name="input_create_aks_tfe_node_pool"></a> [create\_aks\_tfe\_node\_pool](#input\_create\_aks\_tfe\_node\_pool) | Boolean to create a new node pool for TFE in the AKS cluster. | `bool` | `false` | no |
| <a name="input_create_blob_storage_private_endpoint"></a> [create\_blob\_storage\_private\_endpoint](#input\_create\_blob\_storage\_private\_endpoint) | Boolean to create a private endpoint and private DNS zone for TFE Storage Account. | `bool` | `true` | no |
| <a name="input_create_helm_overrides_file"></a> [create\_helm\_overrides\_file](#input\_create\_helm\_overrides\_file) | Boolean to generate a YAML file from template with Helm overrides values for TFE deployment. | `bool` | `true` | no |
| <a name="input_create_postgres_private_endpoint"></a> [create\_postgres\_private\_endpoint](#input\_create\_postgres\_private\_endpoint) | Boolean to create a private endpoint and private DNS zone for PostgreSQL Flexible Server. | `bool` | `true` | no |
| <a name="input_create_redis_private_endpoint"></a> [create\_redis\_private\_endpoint](#input\_create\_redis\_private\_endpoint) | Boolean to create a private DNS zone and private endpoint for Redis cache. | `bool` | `true` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Boolean to create a new resource group for this TFE deployment. | `bool` | `true` | no |
| <a name="input_create_tfe_private_dns_record"></a> [create\_tfe\_private\_dns\_record](#input\_create\_tfe\_private\_dns\_record) | Boolean to create a DNS record for TFE in a private Azure DNS zone. A `private_dns_zone_name` must also be provided when `true`. | `bool` | `false` | no |
| <a name="input_create_tfe_public_dns_record"></a> [create\_tfe\_public\_dns\_record](#input\_create\_tfe\_public\_dns\_record) | Boolean to create a DNS record for TFE in a public Azure DNS zone. A `public_dns_zone_name` must also be provided when `true`. | `bool` | `false` | no |
| <a name="input_db_subnet_id"></a> [db\_subnet\_id](#input\_db\_subnet\_id) | Subnet ID for PostgreSQL flexible server database. | `string` | n/a | yes |
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix used for uniquely naming all Azure resources for this deployment. Most commonly set to either an environment (e.g. 'sandbox', 'prod'), a team name, or a project name. | `string` | n/a | yes |
| <a name="input_is_govcloud_region"></a> [is\_govcloud\_region](#input\_is\_govcloud\_region) | Boolean indicating if this TFE deployment is in an Azure Government Cloud region. | `bool` | `false` | no |
| <a name="input_is_secondary_region"></a> [is\_secondary\_region](#input\_is\_secondary\_region) | Boolean indicating whether this TFE deployment is for 'primary' region or 'secondary' region. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for this TFE deployment. | `string` | n/a | yes |
| <a name="input_postgres_backup_retention_days"></a> [postgres\_backup\_retention\_days](#input\_postgres\_backup\_retention\_days) | Number of days to retain backups of PostgreSQL Flexible Server. | `number` | `35` | no |
| <a name="input_postgres_create_mode"></a> [postgres\_create\_mode](#input\_postgres\_create\_mode) | Determines if the PostgreSQL Flexible Server is being created as a new server or as a replica. | `string` | `"Default"` | no |
| <a name="input_postgres_enable_high_availability"></a> [postgres\_enable\_high\_availability](#input\_postgres\_enable\_high\_availability) | Boolean to enable `ZoneRedundant` high availability with PostgreSQL database. | `bool` | `false` | no |
| <a name="input_postgres_geo_redundant_backup_enabled"></a> [postgres\_geo\_redundant\_backup\_enabled](#input\_postgres\_geo\_redundant\_backup\_enabled) | Boolean to enable PostreSQL geo-redundant backup configuration in paired Azure region. | `bool` | `true` | no |
| <a name="input_postgres_maintenance_window"></a> [postgres\_maintenance\_window](#input\_postgres\_maintenance\_window) | Map of maintenance window settings for PostgreSQL flexible server. | `map(number)` | <pre>{<br/>  "day_of_week": 0,<br/>  "start_hour": 0,<br/>  "start_minute": 0<br/>}</pre> | no |
| <a name="input_postgres_primary_availability_zone"></a> [postgres\_primary\_availability\_zone](#input\_postgres\_primary\_availability\_zone) | Number for the availability zone for the db to reside in | `number` | `1` | no |
| <a name="input_postgres_secondary_availability_zone"></a> [postgres\_secondary\_availability\_zone](#input\_postgres\_secondary\_availability\_zone) | Number for the availability zone for the db to reside in for the secondary node | `number` | `2` | no |
| <a name="input_postgres_sku"></a> [postgres\_sku](#input\_postgres\_sku) | PostgreSQL database SKU. | `string` | `"GP_Standard_D4ds_v4"` | no |
| <a name="input_postgres_storage_mb"></a> [postgres\_storage\_mb](#input\_postgres\_storage\_mb) | Storage capacity of PostgreSQL Flexible Server (unit is megabytes). | `number` | `65536` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | PostgreSQL database version. | `number` | `15` | no |
| <a name="input_private_dns_zone_name"></a> [private\_dns\_zone\_name](#input\_private\_dns\_zone\_name) | Name of existing private Azure DNS zone to create DNS record in. Required when `create_tfe_private_dns_record` is `true`. | `string` | `null` | no |
| <a name="input_private_dns_zone_rg_name"></a> [private\_dns\_zone\_rg\_name](#input\_private\_dns\_zone\_rg\_name) | Name of Resource Group where `private_dns_zone_name` resides. Required when `create_tfe_private_dns_record` is `true`. | `string` | `null` | no |
| <a name="input_public_dns_zone_name"></a> [public\_dns\_zone\_name](#input\_public\_dns\_zone\_name) | Name of existing public Azure DNS zone to create DNS record in. Required when `create_tfe_public_dns_record` is `true`. | `string` | `null` | no |
| <a name="input_public_dns_zone_rg_name"></a> [public\_dns\_zone\_rg\_name](#input\_public\_dns\_zone\_rg\_name) | Name of Resource Group where `public_dns_zone_name` resides. Required when `public_dns_zone_name` is not `null`. | `string` | `null` | no |
| <a name="input_redis_capacity"></a> [redis\_capacity](#input\_redis\_capacity) | The size of the Redis cache to deploy. Valid values for a SKU family of C (Basic/Standard) are 0, 1, 2, 3, 4, 5, 6, and for P (Premium) family are 1, 2, 3, 4. | `number` | `1` | no |
| <a name="input_redis_enable_authentication"></a> [redis\_enable\_authentication](#input\_redis\_enable\_authentication) | Boolean to enable authentication to the Redis cache. | `bool` | `true` | no |
| <a name="input_redis_enable_non_ssl_port"></a> [redis\_enable\_non\_ssl\_port](#input\_redis\_enable\_non\_ssl\_port) | Boolean to enable port non-SSL port 6379 for Redis cache. | `bool` | `false` | no |
| <a name="input_redis_family"></a> [redis\_family](#input\_redis\_family) | The SKU family/pricing group to use. Valid values are C (for Basic/Standard SKU family) and P (for Premium). | `string` | `"P"` | no |
| <a name="input_redis_min_tls_version"></a> [redis\_min\_tls\_version](#input\_redis\_min\_tls\_version) | Minimum TLS version to use with Redis cache. | `string` | `"1.2"` | no |
| <a name="input_redis_sku_name"></a> [redis\_sku\_name](#input\_redis\_sku\_name) | Which SKU of Redis to use. Options are 'Basic', 'Standard', or 'Premium'. | `string` | `"Premium"` | no |
| <a name="input_redis_subnet_id"></a> [redis\_subnet\_id](#input\_redis\_subnet\_id) | Subnet ID for Azure cache for Redis. | `string` | n/a | yes |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis cache version. Only the major version is needed. | `number` | `6` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of resource group for this TFE deployment. Must be an existing resource group if `create_resource_group` is `false`. | `string` | n/a | yes |
| <a name="input_secondary_aks_subnet_id"></a> [secondary\_aks\_subnet\_id](#input\_secondary\_aks\_subnet\_id) | AKS subnet ID of existing TFE AKS cluster in secondary region. Used to allow AKS TFE nodes in secondary region access to TFE storage account in primary region. | `string` | `null` | no |
| <a name="input_storage_account_ip_allow"></a> [storage\_account\_ip\_allow](#input\_storage\_account\_ip\_allow) | List of CIDRs allowed to access TFE Storage Account. | `list(string)` | `[]` | no |
| <a name="input_storage_account_public_network_access_enabled"></a> [storage\_account\_public\_network\_access\_enabled](#input\_storage\_account\_public\_network\_access\_enabled) | Boolean to enable public network access to Azure Blob Storage Account. Needs to be `true` for initial creation. Set to `false` after initial creation. | `bool` | `true` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | Which type of replication to use for TFE Storage Account. | `string` | `"ZRS"` | no |
| <a name="input_tfe_database_name"></a> [tfe\_database\_name](#input\_tfe\_database\_name) | PostgreSQL database name for TFE. | `string` | `"tfe"` | no |
| <a name="input_tfe_database_parameters"></a> [tfe\_database\_parameters](#input\_tfe\_database\_parameters) | Additional parameters to pass into the TFE database settings for the PostgreSQL connection URI. | `string` | `"sslmode=require"` | no |
| <a name="input_tfe_database_password_keyvault_id"></a> [tfe\_database\_password\_keyvault\_id](#input\_tfe\_database\_password\_keyvault\_id) | Resource ID of the Key Vault that contains the TFE database password. | `string` | n/a | yes |
| <a name="input_tfe_database_password_keyvault_secret_name"></a> [tfe\_database\_password\_keyvault\_secret\_name](#input\_tfe\_database\_password\_keyvault\_secret\_name) | Name of the secret in the Key Vault that contains the TFE database password. | `string` | n/a | yes |
| <a name="input_tfe_database_user"></a> [tfe\_database\_user](#input\_tfe\_database\_user) | Name of PostgreSQL TFE database user to create. | `string` | `"tfe"` | no |
| <a name="input_tfe_dns_record_target"></a> [tfe\_dns\_record\_target](#input\_tfe\_dns\_record\_target) | Target of the TFE DNS record. This should be the IP address that the TFE FQDN resolves to. | `string` | `null` | no |
| <a name="input_tfe_fqdn"></a> [tfe\_fqdn](#input\_tfe\_fqdn) | Fully qualified domain name of TFE instance. This name should eventually resolve to the TFE load balancer DNS name or IP address and will be what clients use to access TFE. | `string` | n/a | yes |
| <a name="input_tfe_http_port"></a> [tfe\_http\_port](#input\_tfe\_http\_port) | HTTP port number that the TFE application will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `8080` | no |
| <a name="input_tfe_https_port"></a> [tfe\_https\_port](#input\_tfe\_https\_port) | HTTPS port number that the TFE application will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `8443` | no |
| <a name="input_tfe_image_tag"></a> [tfe\_image\_tag](#input\_tfe\_image\_tag) | Tag for the TFE image. This represents the version of TFE to deploy. | `string` | `"v202402-1"` | no |
| <a name="input_tfe_kube_namespace"></a> [tfe\_kube\_namespace](#input\_tfe\_kube\_namespace) | Kubernetes namespace for TFE deployment. | `string` | `"tfe"` | no |
| <a name="input_tfe_kube_service_account"></a> [tfe\_kube\_service\_account](#input\_tfe\_kube\_service\_account) | Kubernetes service account for TFE deployment. | `string` | `"tfe"` | no |
| <a name="input_tfe_lb_subnet_id"></a> [tfe\_lb\_subnet\_id](#input\_tfe\_lb\_subnet\_id) | Subnet ID for TFE load balancer. This can be the same as the AKS subnet ID if desired. The TFE load balancer is created/managed by Helm/Kubernetes. | `string` | `null` | no |
| <a name="input_tfe_metrics_http_port"></a> [tfe\_metrics\_http\_port](#input\_tfe\_metrics\_http\_port) | HTTP port number that the TFE metrics endpoint will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `9090` | no |
| <a name="input_tfe_metrics_https_port"></a> [tfe\_metrics\_https\_port](#input\_tfe\_metrics\_https\_port) | HTTPS port number that the TFE metrics endpoint will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `9091` | no |
| <a name="input_tfe_object_storage_azure_use_msi"></a> [tfe\_object\_storage\_azure\_use\_msi](#input\_tfe\_object\_storage\_azure\_use\_msi) | Boolean to use TFE user-assigned managed identity (MSI) to access TFE blob storage. If `true`, `aks_workload_identity_enabled` must also be `true`. | `bool` | `false` | no |
| <a name="input_tfe_primary_resource_group_name"></a> [tfe\_primary\_resource\_group\_name](#input\_tfe\_primary\_resource\_group\_name) | Name of existing resource group of TFE deployment in primary region. Only set when `is_secondary_region` is `true`. | `string` | `null` | no |
| <a name="input_tfe_primary_storage_account_name"></a> [tfe\_primary\_storage\_account\_name](#input\_tfe\_primary\_storage\_account\_name) | Name of existing TFE storage account in primary region. Only set when `is_secondary_region` is `true`. | `string` | `null` | no |
| <a name="input_tfe_primary_storage_container_name"></a> [tfe\_primary\_storage\_container\_name](#input\_tfe\_primary\_storage\_container\_name) | Name of existing TFE storage container (within TFE storage account) in primary region. Only set when `is_secondary_region` is `true`. | `string` | `null` | no |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | VNet ID where TFE resources will reside. | `string` | n/a | yes |

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
| <a name="output_tfe_redis_sidekiq_host"></a> [tfe\_redis\_sidekiq\_host](#output\_tfe\_redis\_sidekiq\_host) | n/a |
| <a name="output_tfe_redis_sidekiq_password"></a> [tfe\_redis\_sidekiq\_password](#output\_tfe\_redis\_sidekiq\_password) | n/a |
| <a name="output_tfe_redis_sidekiq_password_base64"></a> [tfe\_redis\_sidekiq\_password\_base64](#output\_tfe\_redis\_sidekiq\_password\_base64) | n/a |
| <a name="output_tfe_redis_sidekiq_use_auth"></a> [tfe\_redis\_sidekiq\_use\_auth](#output\_tfe\_redis\_sidekiq\_use\_auth) | n/a |
<!-- END_TF_DOCS -->
