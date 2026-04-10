# TFE Version Upgrades

TFE follows a monthly release cadence. See the [Terraform Enterprise Releases](https://developer.hashicorp.com/terraform/enterprise/releases) page for full details on the releases. In this module, the deployed TFE version is driven by the Terraform input `tfe_image_tag`, which also controls version-aware Helm readiness behavior and Redis backend selection.

## Version-aware behaviors

- calver releases and semver releases earlier than `1.0.1` stay on the legacy Azure Cache for Redis deployment
- commit-hash tags and semver releases `>= 1.0.1` switch to Azure Managed Redis with separate primary and Sidekiq Redis endpoints
- calver releases and semver releases earlier than `1.2.1` use `/_health_check`
- commit-hash tags and semver releases `>= 1.2.1` use `/api/v1/health/readiness` for readiness checks and the Azure load balancer probe path

If your upgrade crosses the `1.0.1` boundary, or if you move from a calver release to a commit-hash build, plan for the Redis backend change and create or update the `TFE_REDIS_SIDEKIQ_PASSWORD` Kubernetes secret from the Terraform outputs before running `helm upgrade`.

## Procedure

1. Determine your desired version of TFE from the [Terraform Enterprise Releases](https://developer.hashicorp.com/terraform/enterprise/releases) page. Use the **Kubernetes** release version and confirm whether any required intermediate releases must be applied first.

2. During a maintenance window, connect to your TFE pod(s) and gracefully drain the node(s), preventing them from executing new Terraform runs until the pod(s) are rescheduled or restarted.

   Access the TFE command line (`tfectl`) within your TFE pod(s):

   ```sh
   kubectl exec --namespace <TFE_NAMESPACE> -it <TFE_POD_NAME> -- bash
   ```

   Gracefully stop work on all nodes:

   ```sh
   tfectl node drain --all
   ```

   For more details, see:
   - [Access the TFE command line](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/admin/admin-cli/cli-access)
   - [Gracefully stop work on a node](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/admin/admin-cli/admin-cli#gracefully-stop-work-on-a-node)

3. Generate a backup of your PostgreSQL database.

4. Update `tfe_image_tag` in your Terraform configuration to the target version and run `terraform apply` so the module can regenerate the Helm overrides with the correct `image.tag`, readiness path, and Redis settings.

   ```hcl
   tfe_image_tag = "1.2.1"
   ```

5. If the upgrade switches to Azure Managed Redis, create or update the `TFE_REDIS_SIDEKIQ_PASSWORD` Kubernetes secret value using the `tfe_redis_sidekiq_password` Terraform output before continuing.

6. Review the regenerated Helm overrides file and keep any local customizations that you manage outside the module-generated version.

7. Run `helm upgrade` on your TFE release.

   ```sh
   helm upgrade terraform-enterprise hashicorp/terraform-enterprise --namespace <TFE_NAMESPACE> --values /path/to/tfe_helm_overrides.yaml
   ```

8. Delete the existing TFE pod(s), allowing Kubernetes to reschedule new ones.
