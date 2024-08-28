# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# TFE user-assigned managed identity (MSI)
#------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "tfe" {
  count = var.aks_workload_identity_enabled ? 1 : 0

  name                = "${var.friendly_name_prefix}-tfe-aks-msi"
  resource_group_name = local.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "tfe_blob_storage" {
  count = var.aks_workload_identity_enabled && var.tfe_object_storage_azure_use_msi ? 1 : 0

  scope                = azurerm_storage_account.tfe[0].id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.tfe[0].principal_id
}

resource "azurerm_federated_identity_credential" "tfe_kube_service_account" {
  count = var.aks_workload_identity_enabled ? 1 : 0

  name                = "tfe-kube-service-account"
  resource_group_name = local.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.tfe[0].oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.tfe[0].id
  subject             = "system:serviceaccount:${var.tfe_kube_namespace}:${var.tfe_kube_service_account}"
}
