# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Helm overrides values
#------------------------------------------------------------------------------
locals {
  is_calver_tfe_image_tag      = can(regex("^v[0-9]{6}-[0-9]+$", var.tfe_image_tag))
  normalized_tfe_image_tag     = trimprefix(var.tfe_image_tag, "v")
  is_semver_tfe_image_tag      = can(regex("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$", local.normalized_tfe_image_tag))
  is_commit_hash_tfe_image_tag = can(regex("^[0-9A-Fa-f]{7,40}$", var.tfe_image_tag))
  tfe_image_tag_parts          = local.is_semver_tfe_image_tag ? split(".", local.normalized_tfe_image_tag) : []
  tfe_image_tag_major          = local.is_semver_tfe_image_tag ? tonumber(local.tfe_image_tag_parts[0]) : 0
  tfe_image_tag_minor          = local.is_semver_tfe_image_tag ? tonumber(local.tfe_image_tag_parts[1]) : 0
  tfe_image_tag_patch          = local.is_semver_tfe_image_tag && length(local.tfe_image_tag_parts) > 2 ? tonumber(local.tfe_image_tag_parts[2]) : 0

  tfe_redis_uses_managed_redis = !var.is_govcloud_region && (
    local.is_commit_hash_tfe_image_tag || (
      local.is_semver_tfe_image_tag && (
        local.tfe_image_tag_major > 1 || (
          local.tfe_image_tag_major == 1 && (
            local.tfe_image_tag_minor > 0 ||
            (local.tfe_image_tag_minor == 0 && local.tfe_image_tag_patch >= 1)
          )
        )
      )
    )
  )

  tfe_readiness_uses_api = local.is_commit_hash_tfe_image_tag || (
    local.is_semver_tfe_image_tag && (
      local.tfe_image_tag_major > 1 || (
        local.tfe_image_tag_major == 1 && (
          local.tfe_image_tag_minor > 2 ||
          (local.tfe_image_tag_minor == 2 && local.tfe_image_tag_patch >= 1)
        )
      )
    )
  )

  tfe_health_check_path       = local.tfe_readiness_uses_api ? "/api/v1/health/readiness" : "/_health_check"
  redis_private_dns_zone_name = local.tfe_redis_uses_managed_redis ? "privatelink.redis.azure.net" : (var.is_govcloud_region ? "privatelink.redis.cache.usgovcloudapi.net" : "privatelink.redis.cache.windows.net")

  redis_private_endpoint_targets = var.create_redis_private_endpoint ? (
    local.tfe_redis_uses_managed_redis ? {
      main = {
        resource_id      = azurerm_managed_redis.tfe[0].id
        dns_record_name  = join(".", slice(split(".", azurerm_managed_redis.tfe[0].hostname), 0, length(split(".", azurerm_managed_redis.tfe[0].hostname)) - 3))
        subresource_name = "redisEnterprise"
      }
      sidekiq = {
        resource_id      = azurerm_managed_redis.tfe_sidekiq[0].id
        dns_record_name  = join(".", slice(split(".", azurerm_managed_redis.tfe_sidekiq[0].hostname), 0, length(split(".", azurerm_managed_redis.tfe_sidekiq[0].hostname)) - 3))
        subresource_name = "redisEnterprise"
      }
      } : {
      main = {
        resource_id      = azurerm_redis_cache.tfe[0].id
        dns_record_name  = azurerm_redis_cache.tfe[0].name
        subresource_name = "redisCache"
      }
    }
  ) : {}

  redis_main_default_database    = local.tfe_redis_uses_managed_redis ? try(azurerm_managed_redis.tfe[0].default_database[0], null) : null
  redis_sidekiq_default_database = local.tfe_redis_uses_managed_redis ? try(azurerm_managed_redis.tfe_sidekiq[0].default_database[0], null) : null

  redis_main_hostname = local.tfe_redis_uses_managed_redis ? azurerm_managed_redis.tfe[0].hostname : try(azurerm_redis_cache.tfe[0].hostname, "")
  redis_main_port     = local.tfe_redis_uses_managed_redis ? coalesce(try(local.redis_main_default_database.port, null), 10000) : 6380
  redis_main_use_auth = local.tfe_redis_uses_managed_redis ? coalesce(try(local.redis_main_default_database.access_keys_authentication_enabled, null), true) : try(azurerm_redis_cache.tfe[0].redis_configuration[0].authentication_enabled, false)
  redis_main_user     = local.tfe_redis_uses_managed_redis ? "default" : ""

  redis_sidekiq_hostname = local.tfe_redis_uses_managed_redis ? azurerm_managed_redis.tfe_sidekiq[0].hostname : ""
  redis_sidekiq_port     = local.tfe_redis_uses_managed_redis ? coalesce(try(local.redis_sidekiq_default_database.port, null), 10000) : 0
  redis_sidekiq_use_auth = local.tfe_redis_uses_managed_redis ? coalesce(try(local.redis_sidekiq_default_database.access_keys_authentication_enabled, null), true) : false
  redis_sidekiq_user     = local.tfe_redis_uses_managed_redis ? "default" : ""

  helm_overrides_values = {

    # Service account annotation for AKS Azure AD workload identity
    tfe_user_assigned_identity_client_id = var.tfe_object_storage_azure_use_msi ? azurerm_user_assigned_identity.tfe[0].client_id : ""

    # Service (load balancer) annotations
    tfe_lb_subnet_name = var.tfe_lb_subnet_id != null ? reverse(split("/", var.tfe_lb_subnet_id))[0] : ""

    # TFE configuration settings
    tfe_hostname           = var.tfe_fqdn
    tfe_http_port          = var.tfe_http_port
    tfe_https_port         = var.tfe_https_port
    tfe_metrics_http_port  = var.tfe_metrics_http_port
    tfe_metrics_https_port = var.tfe_metrics_https_port
    tfe_image_tag          = var.tfe_image_tag
    tfe_health_check_path  = local.tfe_health_check_path

    # Database settings
    tfe_database_host       = "${azurerm_postgresql_flexible_server.tfe.fqdn}:5432"
    tfe_database_name       = var.tfe_database_name
    tfe_database_user       = var.tfe_database_user
    tfe_database_parameters = var.tfe_database_parameters

    # Object storage settings
    tfe_object_storage_azure_account_name = try("${azurerm_storage_account.tfe[0].name}", "")
    tfe_object_storage_azure_container    = try("${azurerm_storage_container.tfe[0].name}", "")
    tfe_object_storage_azure_endpoint     = var.is_govcloud_region ? split(".blob.", azurerm_storage_account.tfe[0].primary_blob_host)[1] : ""
    tfe_object_storage_azure_use_msi      = var.tfe_object_storage_azure_use_msi
    tfe_object_storage_azure_client_id    = var.tfe_object_storage_azure_use_msi ? azurerm_user_assigned_identity.tfe[0].client_id : ""

    # Redis settings
    tfe_redis_host                  = "${local.redis_main_hostname}:${local.redis_main_port}"
    tfe_redis_user                  = local.redis_main_user
    tfe_redis_use_auth              = local.redis_main_use_auth
    tfe_redis_use_tls               = true
    tfe_render_redis_sidekiq_values = local.tfe_redis_uses_managed_redis
    tfe_redis_sidekiq_host          = local.tfe_redis_uses_managed_redis ? "${local.redis_sidekiq_hostname}:${local.redis_sidekiq_port}" : ""
    tfe_redis_sidekiq_user          = local.tfe_redis_uses_managed_redis ? local.redis_sidekiq_user : ""
    tfe_redis_sidekiq_use_auth      = local.tfe_redis_uses_managed_redis ? local.redis_sidekiq_use_auth : false
    tfe_redis_sidekiq_use_tls       = local.tfe_redis_uses_managed_redis
  }
}

#------------------------------------------------------------------------------
# Module-generated Helm overrides file
#------------------------------------------------------------------------------
resource "local_file" "helm_overrides_values" {
  count = var.create_helm_overrides_file ? 1 : 0

  content  = templatefile("${path.module}/templates/helm_overrides_values.yaml.tpl", local.helm_overrides_values)
  filename = "${path.cwd}/helm/module_generated_helm_overrides.yaml"

  lifecycle {
    ignore_changes = [content, filename]
  }
}
