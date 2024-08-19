# Terraform Enterprise HVD on Azure AKS

Terraform module aligned with HashiCorp Validated Designs (HVD) to deploy Terraform Enterprise on Azure Kubernetes Service (AKS). This module supports bringing your own AKS cluster, or optionally creating a new AKS cluster dedicated to running TFE. This module does not use the Kubernetes or Helm Terraform providers, but rather includes [Post Steps](#post-steps) for the application layer portion of the deployment leveraging the `kubectl` and `helm` CLIs.

## Prerequisites

### General

- TFE license file (_e.g._ `terraform.hclic`)
- Terraform CLI (version `>= 1.9`) installed on clients/workstations that will be used to deploy TFE
- General understanding of how to use Terraform (Community Edition)
- General understanding of how to use Azure cloud
- General understaning of how to use Kubernetes and Helm
- `az` CLI installed on workstation
- `kubectl` CLI and `helm` CLI installed on workstation
- `git` CLI and Visual Studio Code code editor are strongly recommended
- Azure subscription that TFE will be deployed in
- Azure blob storage account for [AzureRM remote state backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html) that will be used to manage the Terraform state of this TFE deployment (out-of-band from the TFE application) via Terraform CLI (Community Edition)

### Networking

- Azure virtual network (VNet) ID that TFE will be deployed in
- TFE load balancer subnet ID (this can be the same as the AKS subnet ID if you prefer)
- Static IP address for TFE load balancer (load balancer is created/managed by Helm/Kubernetes)
- AKS subnet ID for AKS cluster where TFE pods will be running. The AKS/TFE pods subnet should be configured as follows:
  - Service endpoints configured for `Microsoft.Sql` and `Microsoft.Storage` in the event that you disable the creation of private endpoints by this module (default behavior is to create private endpoints, but having the service endpoints enabled as a fallback option is a good practice and will not negatively impact anything)
- If your AKS cluster is private, then your clients/workstations must be able to access the AKS cluster control plane via `kubectl` and `helm` CLIs
- Database subnet ID for PostgreSQL flexible server. The database subnet should be configured as follows:
  - Allow the creation of private endpoints (`private_endpoint_network_policies_enabled` = `false`)
  - Service delegation configured for PostgreSQL flexible servers (`Microsoft.DBforPostgreSQL/flexibleServers`) for join action (`Microsoft.Network/virtualNetworks/subnets/join/action`)
  - Service endpoint configured for `Microsoft.Storage`
- Redis subnet ID for Azure cache for Redis. The Redis subnet should be configured to allow the creation of private endpoints (`private_endpoint_network_policies_enabled` = `false`)

#### Network security group (NSG)/firewall rules

- Allow `TCP/443` ingress to TFE load balancer subnet from CIDR ranges of TFE users/clients, VCS, and other systems that needs to reach TFE
- (Optional) Allow `TCP/9091` (HTTPS) and/or `TCP/9090` (HTTP) ingress to AKS/TFE pods subnet from CIDR ranges of your monitoring/observability tool (for scraping TFE metrics endpoints)
- Allow `TCP/8443` (HTTPS) and `TCP/8080` (HTTP) ingress to AKS/TFE pods subnet from TFE load balancer subnet (for TFE application traffic)
- Allow `TCP/5432` ingress to database subnet from AKS/TFE pods subnet (for PostgreSQL traffic)
- Allow `TCP/6380` ingress to Redis cache subnet from AKS/TFE pods subnet (for Redis TLS traffic)
- Allow `TCP/8201` between nodes on AKS/TFE pods subnet (for TFE embedded Vault internal cluster traffic)
- Allow `TCP/443` egress to Terraform endpoints listed [here](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/requirements/network#egress) from AKS/TFE pods subnet

### TLS certificates

- TLS certificate (_e.g._ `cert.pem`) and private key (_e.g._ `privkey.pem`) that matches your chosen fully qualified domain name (FQDN) for TFE
  - TLS certificate and private key must be in PEM format
  - Private key must **not** be password protected
- TLS certificate authority (CA) bundle (_e.g._ `ca_bundle.pem`) corresponding with the CA that issues your TFE TLS certificates
  - CA bundle must be in PEM format
  - You may include additional certificate chains corresponding to external systems that TFE will make outbound connections to (_e.g._ your self-hosted VCS, if its certificate was issued by a different CA than your TFE certificate)

>📝 Note: The TLS certificate and private key will be created as Kubernetes secrets during the [Post Steps](#post-steps).

### Key Vault secret

The following _bootstrap_ secret needs to exist in an Azure Key Vault:

- TFE database password (to be applied to PostgreSQL flexible server) - both the Key Vault ID and secret name are required

### Compute (optional)

If you plan to create a new AKS cluster using this module, then you may skip this section. Otherwise:

- AKS cluster
  - `Network Contributor` role scoped to TFE pods subnet and (if applicable) TFE load balancer subnet

---

## Usage

1. Create/configure/validate the applicable [prerequisites](#prerequisites).

2. Nested within the [examples](./examples/) directory are subdirectories that contain ready-made Terraform configurations of example scenarios for how to call and deploy this module. To get started, choose an example scenario. If you are starting without an existing AKS cluster, then you should select the [new-aks](examples/new-aks) example scenario.

3. Copy all of the Terraform files from your example scenario of choice into a new destination directory to create your root Terraform configuration that will manage your TFE deployment. If you are not sure where to create this new directory, it is common for users to create an `environments/` directory at the root of this repo (once you have cloned it down locally), and then a subdirectory for each TFE instance deployment, like so:

    ```
    .
    └── environments
        ├── production
        │   ├── backend.tf
        │   ├── main.tf
        │   ├── outputs.tf
        │   ├── terraform.tfvars
        │   └── variables.tf
        └── sandbox
            ├── backend.tf
            ├── main.tf
            ├── outputs.tf
            ├── terraform.tfvars
            └── variables.tf
    ```
    >📝 Note: In this example, the user will have two separate TFE deployments; one for their `sandbox` environment, and one for their `production` environment. This is recommended, but not required.

4. (Optional) Uncomment and update the [azurerm blob remote state backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm) configuration provided in the `backend.tf` file with your own custom values. While this step is highly recommended, it is technically not required to use a remote backend config for your TFE deployment (if you are in a sandbox environment, for example).

5. Populate your own custom values into the `terraform.tfvars.example` file that was provided (in particular, values enclosed in the <> characters). Then, remove the `.example` file extension such that the file is now named `terraform.tfvars`.

6. Navigate to the directory of your newly created Terraform configuration for your TFE deployment, and run `terraform init`, `terraform plan`, and `terraform apply`.

**The TFE infrastructure resources have now been created. Next comes the application layer portion of the deployment (which we refer to as the Post Steps), which will involve interacting with your AKS cluster via `kubectl` and installing the TFE application via `helm`.**

## Post Steps

7. Authenticate to your AKS cluster:
   ```sh
   az login
   az account set --subscription <Subscription Name or ID>
   az aks get-credentials --resource-group <Resource Group> --name <AKS Cluster Name>
   ```

8. Create the Kubernetes namespace for TFE:
   
   ```
   kubectl create namespace tfe
   ```
   
   >📝 Note: You can name it something different than `tfe` if you prefer. If you do name it differently, be sure to update your value of the `tfe_kube_namespace` input variable accordingly.

9. Create the required secrets for your TFE deployment within your new Kubernetes namespace for TFE. There are several ways to do this, whether it be from the CLI via `kubectl`, or another method involving a third-party secrets helper/tool. See the [kubernetes-secrets](./docs/kubernetes-secrets.md) docs for details on the required secrets and how to create them.

10. This Terraform module will automatically generate a Helm overrides file within your Terraform working directory named `./helm/module_generated_helm_overrides.yaml`. This Helm overrides file contains values interpolated from some of the infrastructure resources that were created by Terraform in step 6. Within the Helm overrides file, update or validate the values for the remaining settings that are enclosed in the `<>` characters. You may also add any additional configuration settings into your Helm overrides file at this time (see the [helm-overrides](./docs/helm-overrides.md) doc for more details).

11. Now that you have customized your `module_generated_helm_overrides.yaml` file, rename it to something more applicable to your deployment, such as `prod_tfe_overrides.yaml` (or whatever you prefer). Then, within your `terraform.tfvars` file, set the value of `create_helm_overrides_file` to `false`, as we no longer want the Terraform module to manage this file or generate a new one on a subsequent Terraform run.

12. Add the HashiCorp Helm registry:
    
    ```sh
    helm repo add hashicorp https://helm.releases.hashicorp.com
    ```

   >📝 Note: If you have already added the `hashicorp` Helm repository, you should run `helm repo update hashicorp` to ensure that you have the latest version.

13. Install the TFE application via `helm`:
    
    ```sh
    helm install terraform-enterprise hashicorp/terraform-enterprise --namespace <TFE_NAMESPACE> --values <TFE_OVERRIDES_FILE>
    ```

14. Verify the TFE pod(s) are successfully starting:
    
    View the events within the namespace:
    ```sh
    kubectl get events --namespace <TFE_NAMESPACE>
    ```

    View the pod(s) within the namespace:
    ```sh
    kubectl get pods --namespace <TFE_NAMESPACE>
    ```

    View the logs from the pod:
    ```sh
    kubectl logs <TFE_POD_NAME> --namespace <TFE_NAMESPACE> -f
    ```

15. Create a DNS record for your TFE FQDN. The DNS record should resolve to your TFE load balancer, depending on how the load balancer was configured during your TFE deployment:
    
    - If you are using a Kubernetes service of type `LoadBalancer` (what the module-generated Helm overrides defaults to), the DNS record should resolve to the static IP address of your TFE load balancer:
      
      ```sh
      kubectl get services --namespace <TFE_NAMESPACE>
      ```
    
    - If you are using a custom Kubernetes ingress (meaning you customized your Helm overrides in step 10), the DNS record should resolve to the IP address of your ingress controller load balancer.
      ```sh
      kubectl get ingress <INGRESS_NAME> --namespace <INGRESS_NAMESPACE>
      ```

16. Verify the TFE application is ready:
      
    ```sh
    curl https://<TFE_FQDN>/_health_check
    ```

17. Follow the remaining steps [here](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/kubernetes/install#4-create-initial-admin-user) to finish the installation setup, which involves creating the **initial admin user**.

---

## Docs

Below are links to various docs related to the customization and management of your TFE deployment:

 - [Deployment customizations](./docs/deployment-customizations.md)
 - [Helm overrides](./docs/helm-overrides.md)
 - [TFE version upgrades](./docs/tfe-version-upgrades.md)
 - [TFE TLS certificate rotation](./docs/tfe-cert-rotation.md)
 - [TFE configuration settings](./docs/tfe-config-settings.md)
 - [TFE Kubernetes secrets](./docs/kubernetes-secrets.md)

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.116 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.116 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_dns_a_record.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_federated_identity_credential.tfe_kube_service_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_kubernetes_cluster.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_postgresql_flexible_server.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_private_dns_a_record.blob_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.blob_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.blob_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.blob_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_redis_cache.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache) | resource |
| [azurerm_resource_group.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.aks_network_contributor_aks_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.aks_network_contributor_tfe_lb_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.tfe_blob_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account_network_rules.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_container.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_user_assigned_identity.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [local_file.helm_overrides_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [azurerm_dns_zone.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/dns_zone) | data source |
| [azurerm_key_vault_secret.tfe_database_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_private_dns_zone.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_dns_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_subnet_id"></a> [db\_subnet\_id](#input\_db\_subnet\_id) | Subnet ID for PostgreSQL flexible server database. | `string` | n/a | yes |
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix used for uniquely naming all Azure resources for this deployment. Most commonly set to either an environment (e.g. 'sandbox', 'prod'), a team name, or a project name. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for this TFE deployment. | `string` | n/a | yes |
| <a name="input_redis_subnet_id"></a> [redis\_subnet\_id](#input\_redis\_subnet\_id) | Subnet ID for Azure cache for Redis. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of resource group for this TFE deployment. Must be an existing resource group if `create_resource_group` is `false`. | `string` | n/a | yes |
| <a name="input_tfe_database_password_keyvault_id"></a> [tfe\_database\_password\_keyvault\_id](#input\_tfe\_database\_password\_keyvault\_id) | Resource ID of the Key Vault that contains the TFE database password. | `string` | n/a | yes |
| <a name="input_tfe_database_password_keyvault_secret_name"></a> [tfe\_database\_password\_keyvault\_secret\_name](#input\_tfe\_database\_password\_keyvault\_secret\_name) | Name of the secret in the Key Vault that contains the TFE database password. | `string` | n/a | yes |
| <a name="input_tfe_fqdn"></a> [tfe\_fqdn](#input\_tfe\_fqdn) | Fully qualified domain name of TFE instance. This name should eventually resolve to the TFE load balancer DNS name or IP address and will be what clients use to access TFE. | `string` | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | VNet ID where TFE resources will reside. | `string` | n/a | yes |
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
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of Azure availability zones to spread TFE resources across. | `set(string)` | <pre>[<br>  "1",<br>  "2",<br>  "3"<br>]</pre> | no |
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
| <a name="input_is_govcloud_region"></a> [is\_govcloud\_region](#input\_is\_govcloud\_region) | Boolean indicating if this TFE deployment is in an Azure Government Cloud region. | `bool` | `false` | no |
| <a name="input_is_secondary_region"></a> [is\_secondary\_region](#input\_is\_secondary\_region) | Boolean indicating whether this TFE deployment is for 'primary' region or 'secondary' region. | `bool` | `false` | no |
| <a name="input_postgres_backup_retention_days"></a> [postgres\_backup\_retention\_days](#input\_postgres\_backup\_retention\_days) | Number of days to retain backups of PostgreSQL Flexible Server. | `number` | `35` | no |
| <a name="input_postgres_create_mode"></a> [postgres\_create\_mode](#input\_postgres\_create\_mode) | Determines if the PostgreSQL Flexible Server is being created as a new server or as a replica. | `string` | `"Default"` | no |
| <a name="input_postgres_enable_high_availability"></a> [postgres\_enable\_high\_availability](#input\_postgres\_enable\_high\_availability) | Boolean to enable `ZoneRedundant` high availability with PostgreSQL database. | `bool` | `false` | no |
| <a name="input_postgres_geo_redundant_backup_enabled"></a> [postgres\_geo\_redundant\_backup\_enabled](#input\_postgres\_geo\_redundant\_backup\_enabled) | Boolean to enable PostreSQL geo-redundant backup configuration in paired Azure region. | `bool` | `true` | no |
| <a name="input_postgres_maintenance_window"></a> [postgres\_maintenance\_window](#input\_postgres\_maintenance\_window) | Map of maintenance window settings for PostgreSQL flexible server. | `map(number)` | <pre>{<br>  "day_of_week": 0,<br>  "start_hour": 0,<br>  "start_minute": 0<br>}</pre> | no |
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
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis cache version. Only the major version is needed. | `number` | `6` | no |
| <a name="input_secondary_aks_subnet_id"></a> [secondary\_aks\_subnet\_id](#input\_secondary\_aks\_subnet\_id) | AKS subnet ID of existing TFE AKS cluster in secondary region. Used to allow AKS TFE nodes in secondary region access to TFE storage account in primary region. | `string` | `null` | no |
| <a name="input_storage_account_ip_allow"></a> [storage\_account\_ip\_allow](#input\_storage\_account\_ip\_allow) | List of CIDRs allowed to access TFE Storage Account. | `list(string)` | `[]` | no |
| <a name="input_storage_account_public_network_access_enabled"></a> [storage\_account\_public\_network\_access\_enabled](#input\_storage\_account\_public\_network\_access\_enabled) | Boolean to enable public network access to Azure Blob Storage Account. Needs to be `true` for initial creation. Set to `false` after initial creation. | `bool` | `true` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | Which type of replication to use for TFE Storage Account. | `string` | `"ZRS"` | no |
| <a name="input_tfe_database_name"></a> [tfe\_database\_name](#input\_tfe\_database\_name) | PostgreSQL database name for TFE. | `string` | `"tfe"` | no |
| <a name="input_tfe_database_parameters"></a> [tfe\_database\_parameters](#input\_tfe\_database\_parameters) | Additional parameters to pass into the TFE database settings for the PostgreSQL connection URI. | `string` | `"sslmode=require"` | no |
| <a name="input_tfe_database_user"></a> [tfe\_database\_user](#input\_tfe\_database\_user) | Name of PostgreSQL TFE database user to create. | `string` | `"tfe"` | no |
| <a name="input_tfe_dns_record_target"></a> [tfe\_dns\_record\_target](#input\_tfe\_dns\_record\_target) | Target of the TFE DNS record. This should be the IP address that the TFE FQDN resolves to. | `string` | `null` | no |
| <a name="input_tfe_http_port"></a> [tfe\_http\_port](#input\_tfe\_http\_port) | HTTP port number that the TFE application will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `8080` | no |
| <a name="input_tfe_https_port"></a> [tfe\_https\_port](#input\_tfe\_https\_port) | HTTPS port number that the TFE application will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `8443` | no |
| <a name="input_tfe_kube_namespace"></a> [tfe\_kube\_namespace](#input\_tfe\_kube\_namespace) | Kubernetes namespace for TFE deployment. | `string` | `"tfe"` | no |
| <a name="input_tfe_kube_service_account"></a> [tfe\_kube\_service\_account](#input\_tfe\_kube\_service\_account) | Kubernetes service account for TFE deployment. | `string` | `"tfe"` | no |
| <a name="input_tfe_lb_subnet_id"></a> [tfe\_lb\_subnet\_id](#input\_tfe\_lb\_subnet\_id) | Subnet ID for TFE load balancer. This can be the same as the AKS subnet ID if desired. The TFE load balancer is created/managed by Helm/Kubernetes. | `string` | `null` | no |
| <a name="input_tfe_metrics_http_port"></a> [tfe\_metrics\_http\_port](#input\_tfe\_metrics\_http\_port) | HTTP port number that the TFE metrics endpoint will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `9090` | no |
| <a name="input_tfe_metrics_https_port"></a> [tfe\_metrics\_https\_port](#input\_tfe\_metrics\_https\_port) | HTTPS port number that the TFE metrics endpoint will listen on within the TFE pods. It is recommended to leave this as the default value. | `number` | `9091` | no |
| <a name="input_tfe_object_storage_azure_use_msi"></a> [tfe\_object\_storage\_azure\_use\_msi](#input\_tfe\_object\_storage\_azure\_use\_msi) | Boolean to use TFE user-assigned managed identity (MSI) to access TFE blob storage. If `true`, `aks_workload_identity_enabled` must also be `true`. | `bool` | `false` | no |
| <a name="input_tfe_primary_resource_group_name"></a> [tfe\_primary\_resource\_group\_name](#input\_tfe\_primary\_resource\_group\_name) | Name of existing resource group of TFE deployment in primary region. Only set when `is_secondary_region` is `true`. | `string` | `null` | no |
| <a name="input_tfe_primary_storage_account_name"></a> [tfe\_primary\_storage\_account\_name](#input\_tfe\_primary\_storage\_account\_name) | Name of existing TFE storage account in primary region. Only set when `is_secondary_region` is `true`. | `string` | `null` | no |
| <a name="input_tfe_primary_storage_container_name"></a> [tfe\_primary\_storage\_container\_name](#input\_tfe\_primary\_storage\_container\_name) | Name of existing TFE storage container (within TFE storage account) in primary region. Only set when `is_secondary_region` is `true`. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aks_cluster_name"></a> [aks\_cluster\_name](#output\_aks\_cluster\_name) | Name of the AKS cluster. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group. |
| <a name="output_tfe_database_host"></a> [tfe\_database\_host](#output\_tfe\_database\_host) | Fully qualified domain name (FQDN) and port of the PostgreSQL flexible server. |
| <a name="output_tfe_database_name"></a> [tfe\_database\_name](#output\_tfe\_database\_name) | Name of the PostgreSQL flexible server TFE database. |
| <a name="output_tfe_database_password"></a> [tfe\_database\_password](#output\_tfe\_database\_password) | Password of the PostgreSQL flexible server TFE database. |
| <a name="output_tfe_database_password_base64"></a> [tfe\_database\_password\_base64](#output\_tfe\_database\_password\_base64) | Base64-encoded password of the PostgreSQL flexible server TFE database. |
| <a name="output_tfe_database_user"></a> [tfe\_database\_user](#output\_tfe\_database\_user) | Username of the PostgreSQL flexible server TFE database. |
| <a name="output_tfe_object_storage_azure_account_key"></a> [tfe\_object\_storage\_azure\_account\_key](#output\_tfe\_object\_storage\_azure\_account\_key) | Primary access key of the storage account for TFE object storage. |
| <a name="output_tfe_object_storage_azure_account_key_base64"></a> [tfe\_object\_storage\_azure\_account\_key\_base64](#output\_tfe\_object\_storage\_azure\_account\_key\_base64) | Base64-encoded primary access key of the storage account for TFE object storage. |
| <a name="output_tfe_object_storage_azure_account_name"></a> [tfe\_object\_storage\_azure\_account\_name](#output\_tfe\_object\_storage\_azure\_account\_name) | Name of the storage account for TFE object storage. |
| <a name="output_tfe_object_storage_azure_client_id"></a> [tfe\_object\_storage\_azure\_client\_id](#output\_tfe\_object\_storage\_azure\_client\_id) | Client ID of the managed identity (MSI) used by TFE to access the storage account. |
| <a name="output_tfe_object_storage_azure_container"></a> [tfe\_object\_storage\_azure\_container](#output\_tfe\_object\_storage\_azure\_container) | Name of the storage account container for TFE object storage. |
| <a name="output_tfe_object_storage_azure_use_msi"></a> [tfe\_object\_storage\_azure\_use\_msi](#output\_tfe\_object\_storage\_azure\_use\_msi) | Boolean indicating whether TFE is using a managed identity (MSI) to access the storage account. |
| <a name="output_tfe_private_dns_record_fqdn"></a> [tfe\_private\_dns\_record\_fqdn](#output\_tfe\_private\_dns\_record\_fqdn) | Private DNS record for TFE. |
| <a name="output_tfe_public_dns_record_fqdn"></a> [tfe\_public\_dns\_record\_fqdn](#output\_tfe\_public\_dns\_record\_fqdn) | Public DNS record for TFE. |
| <a name="output_tfe_redis_host"></a> [tfe\_redis\_host](#output\_tfe\_redis\_host) | Hostname of the Redis cache. |
| <a name="output_tfe_redis_password"></a> [tfe\_redis\_password](#output\_tfe\_redis\_password) | Primary access key of the Redis cache. |
| <a name="output_tfe_redis_password_base64"></a> [tfe\_redis\_password\_base64](#output\_tfe\_redis\_password\_base64) | Base64-encoded primary access key of the Redis cache. |
| <a name="output_tfe_redis_use_auth"></a> [tfe\_redis\_use\_auth](#output\_tfe\_redis\_use\_auth) | Boolean indicating whether TFE is using authentication to access the Redis cache. |
<!-- END_TF_DOCS -->
