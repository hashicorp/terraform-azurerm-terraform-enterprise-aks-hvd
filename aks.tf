#------------------------------------------------------------------------------
# AKS cluster
#------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "tfe" {
  count = var.create_aks_cluster ? 1 : 0

  name                = "${var.friendly_name_prefix}-tfe-aks"
  resource_group_name = local.resource_group_name
  location            = var.location
  dns_prefix          = "${var.friendly_name_prefix}-tfe-aks"
  kubernetes_version  = var.aks_kubernetes_version

  default_node_pool {
    name           = var.aks_default_node_pool_name
    node_count     = var.aks_default_node_pool_node_count
    vm_size        = var.aks_default_node_pool_vm_size
    os_sku         = "Ubuntu"
    vnet_subnet_id = var.aks_subnet_id
    zones          = var.availability_zones

    upgrade_settings {
      max_surge = var.aks_default_node_pool_max_surge
    }
  }

  network_profile {
    network_plugin    = "azure"
    service_cidr      = var.aks_service_cidr
    dns_service_ip    = var.aks_dns_service_ip
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges
  }

  workload_identity_enabled         = var.aks_workload_identity_enabled
  oidc_issuer_enabled               = var.aks_oidc_issuer_enabled
  role_based_access_control_enabled = var.aks_role_based_access_control_enabled

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-aks" },
    var.common_tags
  )

  depends_on = [
    azurerm_role_assignment.tfe_blob_storage
  ]
}

#------------------------------------------------------------------------------
# TFE AKS node pool
#------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "tfe" {
  count = var.create_aks_cluster && var.create_aks_tfe_node_pool ? 1 : 0

  name                  = var.aks_tfe_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.tfe[0].id
  vm_size               = var.aks_tfe_node_pool_vm_size
  node_count            = var.aks_tfe_node_pool_node_count
  vnet_subnet_id        = var.aks_subnet_id
  zones                 = var.availability_zones
  mode                  = "User"
  os_type               = "Linux"

  tags = merge(
    { "Name" = var.aks_tfe_node_pool_name },
    var.common_tags
  )
}

resource "azurerm_role_assignment" "aks_network_contributor_aks_subnet" {
  count = var.create_aks_cluster ? 1 : 0

  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.tfe[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_network_contributor_tfe_lb_subnet" {
  count = var.create_aks_cluster && var.tfe_lb_subnet_id != null ? 1 : 0

  scope                = var.tfe_lb_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.tfe[0].identity[0].principal_id
}