#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "create_resource_group" {
  type        = bool
  description = "Boolean to create a new resource group for this TFE deployment."
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "Name of resource group for this TFE deployment. Must be an existing resource group if `create_resource_group` is `false`."
}

variable "location" {
  type        = string
  description = "Azure region for this TFE deployment."

  validation {
    condition     = contains(["asiapacific", "asia", "australiacentral", "australiacentral2", "australiaeast", "australiasoutheast", "brazil", "brazilsouth", "brazilsoutheast", "brazilus", "canada", "canadacentral", "canadaeast", "centralindia", "centralus", "centraluseuap", "centralusstage", "eastasia", "eastasiastage", "eastus", "eastus2", "eastus2euap", "eastus2stage", "eastusstage", "eastusstg", "europe", "france", "francecentral", "francesouth", "germany", "germanynorth", "germanywestcentral", "global", "india", "israel", "israelcentral", "italy", "italynorth", "japan", "japaneast", "japanwest", "jioindiacentral", "jioindiawest", "korea", "koreacentral", "koreasouth", "mexicocentral", "newzealand", "northcentralus", "northcentralusstage", "northeurope", "norway", "norwayeast", "norwaywest", "poland", "polandcentral", "qatar", "qatarcentral", "singapore", "southafrica", "southafricanorth", "southafricawest", "southcentralus", "southcentralusstage", "southeastasia", "southeastasiastage", "southindia", "spaincentral", "sweden", "swedencentral", "switzerland", "switzerlandnorth", "switzerlandwest", "uae", "uaecentral", "uaenorth", "uk", "uksouth", "ukwest", "unitedstates", "unitedstateseuap", "westcentralus", "westeurope", "westindia", "westus", "westus2", "westus2stage", "westus3", "westusstage"], var.location)
    error_message = "Value specified is not a valid Azure region."
  }
}

variable "friendly_name_prefix" {
  type        = string
  description = "Friendly name prefix used for uniquely naming all Azure resources for this deployment. Most commonly set to either an environment (e.g. 'sandbox', 'prod'), a team name, or a project name."

  validation {
    condition     = can(regex("^[[:alnum:]]+$", var.friendly_name_prefix)) && length(var.friendly_name_prefix) < 13
    error_message = "Value can only contain alphanumeric characters and must be less than 13 characters."
  }

  validation {
    condition     = !strcontains(lower(var.friendly_name_prefix), "tfe")
    error_message = "Value must not contain the substring 'tfe' to avoid redundancy in resource naming."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for taggable Azure resources."
  default     = {}
}

variable "availability_zones" {
  type        = set(string)
  description = "List of Azure availability zones to spread TFE resources across."
  default     = ["1", "2", "3"]

  validation {
    condition     = alltrue([for az in var.availability_zones : contains(["1", "2", "3"], az)])
    error_message = "Availability zone must be one of, or a combination of '1', '2', '3'."
  }
}

variable "is_secondary_region" {
  type        = bool
  description = "Boolean indicating whether this TFE deployment is for 'primary' region or 'secondary' region."
  default     = false
}

variable "is_govcloud_region" {
  type        = bool
  description = "Boolean indicating if this TFE deployment is in an Azure Government Cloud region."
  default     = false
}

variable "tfe_primary_resource_group_name" {
  type        = string
  description = "Name of existing resource group of TFE deployment in primary region. Only set when `is_secondary_region` is `true`. "
  default     = null

  validation {
    condition     = var.is_secondary_region ? var.tfe_primary_resource_group_name != null : true
    error_message = "Value must be set when `is_secondary_region` is `true`."
  }

  validation {
    condition     = !var.is_secondary_region ? var.tfe_primary_resource_group_name == null : true
    error_message = "Value must be `null` when `is_secondary_region` is `false`."
  }
}

#------------------------------------------------------------------------------
# TFE configuration settings
#------------------------------------------------------------------------------
variable "tfe_fqdn" {
  type        = string
  description = "Fully qualified domain name of TFE instance. This name should eventually resolve to the TFE load balancer DNS name or IP address and will be what clients use to access TFE."
}

variable "tfe_http_port" {
  type        = number
  description = "HTTP port number that the TFE application will listen on within the TFE pods. It is recommended to leave this as the default value."
  default     = 8080
}

variable "tfe_https_port" {
  type        = number
  description = "HTTPS port number that the TFE application will listen on within the TFE pods. It is recommended to leave this as the default value."
  default     = 8443
}

variable "tfe_metrics_http_port" {
  type        = number
  description = "HTTP port number that the TFE metrics endpoint will listen on within the TFE pods. It is recommended to leave this as the default value."
  default     = 9090
}

variable "tfe_metrics_https_port" {
  type        = number
  description = "HTTPS port number that the TFE metrics endpoint will listen on within the TFE pods. It is recommended to leave this as the default value."
  default     = 9091
}

variable "create_helm_overrides_file" {
  type        = bool
  description = "Boolean to generate a YAML file from template with Helm overrides values for TFE deployment."
  default     = true
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
variable "vnet_id" {
  type        = string
  description = "VNet ID where TFE resources will reside."
}

variable "tfe_lb_subnet_id" {
  type        = string
  description = "Subnet ID for TFE load balancer. This can be the same as the AKS subnet ID if desired. The TFE load balancer is created/managed by Helm/Kubernetes."
  default     = null
}

variable "aks_subnet_id" {
  type        = string
  description = "Subnet ID for AKS cluster."
  default     = null
}

variable "db_subnet_id" {
  type        = string
  description = "Subnet ID for PostgreSQL flexible server database."
}

variable "redis_subnet_id" {
  type        = string
  description = "Subnet ID for Azure cache for Redis."
}

variable "secondary_aks_subnet_id" {
  type        = string
  description = "AKS subnet ID of existing TFE AKS cluster in secondary region. Used to allow AKS TFE nodes in secondary region access to TFE storage account in primary region."
  default     = null

  validation {
    condition     = var.is_secondary_region ? var.secondary_aks_subnet_id == null : true
    error_message = "Value must be `null` when `is_secondary_region` is `true`, as the TFE storage account only exists in the primary region."
  }
}

#------------------------------------------------------------------------------
# DNS
#------------------------------------------------------------------------------
variable "create_tfe_public_dns_record" {
  type        = bool
  description = "Boolean to create a DNS record for TFE in a public Azure DNS zone. A `public_dns_zone_name` must also be provided when `true`."
  default     = false
}

variable "public_dns_zone_name" {
  type        = string
  description = "Name of existing public Azure DNS zone to create DNS record in. Required when `create_tfe_public_dns_record` is `true`."
  default     = null

  validation {
    condition     = var.create_tfe_public_dns_record ? var.public_dns_zone_name != null : true
    error_message = "A value is required when `create_tfe_public_dns_record` is `true`."
  }
}

variable "public_dns_zone_rg_name" {
  type        = string
  description = "Name of Resource Group where `public_dns_zone_name` resides. Required when `public_dns_zone_name` is not `null`."
  default     = null

  validation {
    condition     = var.public_dns_zone_name != null ? var.public_dns_zone_rg_name != null : true
    error_message = "A value is required when `public_dns_zone_name` is not `null`."
  }
}

variable "create_tfe_private_dns_record" {
  type        = bool
  description = "Boolean to create a DNS record for TFE in a private Azure DNS zone. A `private_dns_zone_name` must also be provided when `true`."
  default     = false
}

variable "private_dns_zone_name" {
  type        = string
  description = "Name of existing private Azure DNS zone to create DNS record in. Required when `create_tfe_private_dns_record` is `true`."
  default     = null

  validation {
    condition     = var.create_tfe_private_dns_record ? var.private_dns_zone_name != null : true
    error_message = "A value is required when `create_tfe_private_dns_record` is `true`."
  }
}

variable "private_dns_zone_rg_name" {
  type        = string
  description = "Name of Resource Group where `private_dns_zone_name` resides. Required when `create_tfe_private_dns_record` is `true`."
  default     = null

  validation {
    condition     = var.private_dns_zone_name != null ? var.private_dns_zone_rg_name != null : true
    error_message = "A value is required when `private_dns_zone_name` is not `null`."
  }
}

variable "tfe_dns_record_target" {
  type        = string
  description = "Target of the TFE DNS record. This should be the IP address that the TFE FQDN resolves to."
  default     = null
}

#------------------------------------------------------------------------------
# AKS
#------------------------------------------------------------------------------
variable "create_aks_cluster" {
  type        = bool
  description = "Boolean to create a new AKS cluster for this TFE deployment."
  default     = false
}

variable "aks_kubernetes_version" {
  type        = string
  description = "Kubernetes version for AKS cluster."
  default     = "1.29.6"
}

variable "tfe_kube_namespace" {
  type        = string
  description = "Kubernetes namespace for TFE deployment."
  default     = "tfe"
}

variable "tfe_kube_service_account" {
  type        = string
  description = "Kubernetes service account for TFE deployment."
  default     = "tfe"
}

variable "aks_default_node_pool_name" {
  type        = string
  description = "Name of default node pool."
  default     = "default"
}

variable "aks_default_node_pool_node_count" {
  type        = number
  description = "Number of nodes to run in the AKS default node pool."
  default     = 2
}

variable "aks_default_node_pool_vm_size" {
  type        = string
  description = "Size of the virtual machines within the AKS default node pool."
  default     = "Standard_D8ds_v5"
}

variable "aks_default_node_pool_max_surge" {
  type        = string
  description = "The maximum number of nodes that can be added during an upgrade."
  default     = "10%"
}

variable "aks_api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "List of IP ranges that are allowed to access the AKS API server (control plane)."
  default     = []
}

variable "aks_service_cidr" {
  type        = string
  description = "IP range for Kubernetes services that can be used by AKS cluster."
  default     = "10.1.0.0/16"
}

variable "aks_dns_service_ip" {
  type        = string
  description = "The IP address assigned to the AKS internal DNS service."
  default     = "10.1.0.10"
}

variable "aks_workload_identity_enabled" {
  type        = bool
  description = "Boolean to enable Workload Identity for the AKS cluster."
  default     = true
}

variable "aks_oidc_issuer_enabled" {
  type        = bool
  description = "Boolean to enable OIDC issuer for the AKS cluster."
  default     = true
}

variable "aks_role_based_access_control_enabled" {
  type        = bool
  description = "Boolean to enable Role-Based Access Control (RBAC) for the AKS cluster."
  default     = true
}

variable "create_aks_tfe_node_pool" {
  type        = bool
  description = "Boolean to create a new node pool for TFE in the AKS cluster."
  default     = false
}

variable "aks_tfe_node_pool_name" {
  type        = string
  description = "Name of TFE node pool. Only valid when `create_aks_tfe_node_pool` is `true`."
  default     = "tfeaksnodes"
}

variable "aks_tfe_node_pool_node_count" {
  type        = number
  description = "Number of nodes in the AKS TFE node pool. Only valid when `create_aks_tfe_node_pool` is `true`."
  default     = 2
}

variable "aks_tfe_node_pool_vm_size" {
  type        = string
  description = "Size of virtual machines in the AKS TFE node pool. Only valid when `create_aks_tfe_node_pool` is `true`."
  default     = "Standard_D8ds_v5"
}

#------------------------------------------------------------------------------
# PostgreSQL
#------------------------------------------------------------------------------
variable "postgres_version" {
  type        = number
  description = "PostgreSQL database version."
  default     = 15
}

variable "postgres_sku" {
  type        = string
  description = "PostgreSQL database SKU."
  default     = "GP_Standard_D4ds_v4"
}

variable "postgres_storage_mb" {
  type        = number
  description = "Storage capacity of PostgreSQL Flexible Server (unit is megabytes)."
  default     = 65536
}

variable "postgres_backup_retention_days" {
  type        = number
  description = "Number of days to retain backups of PostgreSQL Flexible Server."
  default     = 35
}

variable "postgres_create_mode" {
  type        = string
  description = "Determines if the PostgreSQL Flexible Server is being created as a new server or as a replica."
  default     = "Default"

  validation {
    condition     = anytrue([var.postgres_create_mode == "Default", var.postgres_create_mode == "Replica"])
    error_message = "Value must be `Default` or `Replica`."
  }
}

variable "tfe_database_name" {
  type        = string
  description = "PostgreSQL database name for TFE."
  default     = "tfe"
}

variable "tfe_database_user" {
  type        = string
  description = "Name of PostgreSQL TFE database user to create."
  default     = "tfe"
}

variable "tfe_database_parameters" {
  type        = string
  description = "Additional parameters to pass into the TFE database settings for the PostgreSQL connection URI."
  default     = "sslmode=require"
}

variable "tfe_database_password_keyvault_id" {
  type        = string
  description = "Resource ID of the Key Vault that contains the TFE database password."
}

variable "tfe_database_password_keyvault_secret_name" {
  type        = string
  description = "Name of the secret in the Key Vault that contains the TFE database password."
}

variable "create_postgres_private_endpoint" {
  type        = bool
  description = "Boolean to create a private endpoint and private DNS zone for PostgreSQL Flexible Server."
  default     = true
}

variable "postgres_enable_high_availability" {
  type        = bool
  description = "Boolean to enable `ZoneRedundant` high availability with PostgreSQL database."
  default     = false
}

variable "postgres_geo_redundant_backup_enabled" {
  type        = bool
  description = "Boolean to enable PostreSQL geo-redundant backup configuration in paired Azure region."
  default     = true
}

variable "postgres_primary_availability_zone" {
  type        = number
  description = "Number for the availability zone for the db to reside in"
  default     = 1
}

variable "postgres_secondary_availability_zone" {
  type        = number
  description = "Number for the availability zone for the db to reside in for the secondary node"
  default     = 2
}

variable "postgres_maintenance_window" {
  type        = map(number)
  description = "Map of maintenance window settings for PostgreSQL flexible server."
  default = {
    day_of_week  = 0
    start_hour   = 0
    start_minute = 0
  }
}

#------------------------------------------------------------------------------
# Storage account (blob storage)
#------------------------------------------------------------------------------
variable "storage_account_public_network_access_enabled" {
  type        = bool
  description = "Boolean to enable public network access to Azure Blob Storage Account. Needs to be `true` for initial creation. Set to `false` after initial creation."
  default     = true
}

variable "storage_account_ip_allow" {
  type        = list(string)
  description = "List of CIDRs allowed to access TFE Storage Account."
  default     = []
}

variable "storage_account_replication_type" {
  type        = string
  description = "Which type of replication to use for TFE Storage Account."
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Value must be one of 'LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', or 'RAGZRS'."
  }
}

variable "create_blob_storage_private_endpoint" {
  type        = bool
  description = "Boolean to create a private endpoint and private DNS zone for TFE Storage Account."
  default     = true
}

variable "tfe_object_storage_azure_use_msi" {
  type        = bool
  description = "Boolean to use TFE user-assigned managed identity (MSI) to access TFE blob storage. If `true`, `aks_workload_identity_enabled` must also be `true`."
  default     = false

  validation {
    condition     = var.tfe_object_storage_azure_use_msi ? var.aks_workload_identity_enabled : true
    error_message = "When `true`, `aks_workload_identity_enabled` must also be `true`."
  }
}

variable "tfe_primary_storage_account_name" {
  type        = string
  description = "Name of existing TFE storage account in primary region. Only set when `is_secondary_region` is `true`. "
  default     = null

  validation {
    condition     = var.is_secondary_region ? var.tfe_primary_storage_account_name != null : true
    error_message = "Value is required when `is_secondary_region` is `true`."
  }

  validation {
    condition     = !var.is_secondary_region ? var.tfe_primary_storage_account_name == null : true
    error_message = "Value must be `null` when `is_secondary_region` is `false`."
  }
}

variable "tfe_primary_storage_container_name" {
  type        = string
  description = "Name of existing TFE storage container (within TFE storage account) in primary region. Only set when `is_secondary_region` is `true`."
  default     = null

  validation {
    condition     = var.is_secondary_region ? var.tfe_primary_storage_container_name != null : true
    error_message = "Value is required when `is_secondary_region` is `true`."
  }

  validation {
    condition     = !var.is_secondary_region ? var.tfe_primary_storage_container_name == null : true
    error_message = "Value must be `null` when `is_secondary_region` is `false`."
  }
}

#------------------------------------------------------------------------------
# Redis cache
#------------------------------------------------------------------------------
variable "redis_family" {
  type        = string
  description = "The SKU family/pricing group to use. Valid values are C (for Basic/Standard SKU family) and P (for Premium)."
  default     = "P"

  validation {
    condition     = contains(["C", "P"], var.redis_family)
    error_message = "Supported values are `C` or `P`."
  }
}

variable "redis_capacity" {
  type        = number
  description = "The size of the Redis cache to deploy. Valid values for a SKU family of C (Basic/Standard) are 0, 1, 2, 3, 4, 5, 6, and for P (Premium) family are 1, 2, 3, 4."
  default     = 1

  validation {
    condition     = contains([0, 1, 2, 3, 4, 5, 6], var.redis_capacity)
    error_message = "Valid values for a SKU family of C (Basic/Standard) are 0, 1, 2, 3, 4, 5, 6, and for P (Premium) family are 1, 2, 3, 4."
  }
}

variable "redis_sku_name" {
  type        = string
  description = "Which SKU of Redis to use. Options are 'Basic', 'Standard', or 'Premium'."
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.redis_sku_name)
    error_message = "Supported values are `Basic`, `Standard`, or `Premium`."
  }
}

variable "redis_version" {
  type        = number
  description = "Redis cache version. Only the major version is needed."
  default     = 6
}

variable "redis_enable_authentication" {
  type        = bool
  description = "Boolean to enable authentication to the Redis cache."
  default     = true
}

variable "redis_enable_non_ssl_port" {
  type        = bool
  description = "Boolean to enable port non-SSL port 6379 for Redis cache."
  default     = false
}

variable "redis_min_tls_version" {
  type        = string
  description = "Minimum TLS version to use with Redis cache."
  default     = "1.2"
}

variable "create_redis_private_endpoint" {
  type        = bool
  description = "Boolean to create a private DNS zone and private endpoint for Redis cache."
  default     = true
}