# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Helm overrides values
#------------------------------------------------------------------------------
locals {
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
    tfe_redis_host     = try("${azurerm_redis_cache.tfe.hostname}:6380", "")
    tfe_redis_use_auth = try(azurerm_redis_cache.tfe.redis_configuration[0].enable_authentication, "")
    tfe_redis_use_tls  = true
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

