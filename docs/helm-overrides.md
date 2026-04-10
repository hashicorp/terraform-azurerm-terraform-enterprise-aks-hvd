# Helm Overrides

This doc contains various customizations that are supported within your Helm overrides file for your TFE deployment.

## Version-aware generated values

The module-generated `./helm/module_generated_helm_overrides.yaml` file derives several values from `tfe_image_tag`:

- `image.tag` is rendered directly from `tfe_image_tag`
- the Azure load balancer health probe path stays on `/_health_check` for calver releases and semver releases earlier than `1.2.1`
- the Azure load balancer health probe path switches to `/api/v1/health/readiness` for commit-hash tags and semver releases `>= 1.2.1`
- the Redis settings stay on the legacy single Azure Cache for Redis endpoint for calver releases and semver releases earlier than `1.0.1`
- the Redis settings switch to Azure Managed Redis with separate primary and Sidekiq endpoints for commit-hash tags and semver releases `>= 1.0.1`

When Azure Managed Redis is selected, the generated file also renders:

- `TFE_REDIS_SIDEKIQ_HOST`
- `TFE_REDIS_SIDEKIQ_USE_AUTH`
- `TFE_REDIS_SIDEKIQ_USE_TLS`

You must still create the matching `TFE_REDIS_SIDEKIQ_PASSWORD` Kubernetes secret manually from the Terraform outputs.

The module also provisions the Azure Managed Redis databases with the `EnterpriseCluster` clustering policy for these semver releases and commit-hash tags so TFE can use the Azure Managed Redis topology intended for standard Redis clients and avoid the redirect-driven `OSSCluster` behavior.

The module-generated Helm overrides file derives `image.tag`, the Azure load balancer health probe path, and any Redis Sidekiq settings from `tfe_image_tag`. If you choose to stop using the generated file and manage your own Helm values file instead, keep those settings aligned with the TFE version you are deploying.

## Scaling TFE Pods

To manage the number of pods running within your TFE deployment, set the value of the `replicaCount` key accordingly.

```yaml
replicaCount: 3
```

## Service (type `LoadBalancer`)

By default, the module-generated Helm overrides will create a Kubernetes service of type `LoadBalancer`. This service will automatically provision an internal Azure load balancer on the specified subnet with the specified static IP.

### Internal (default)

```yaml
service:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: "/_health_check" # semver releases earlier than 1.2.1
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "<tfe-lb-subnet-name>"
    service.beta.kubernetes.io/azure-load-balancer-ipv4: <"lb-static-ip">  # Available private IP address from TFE load balancer subnet
  type: LoadBalancer
  port: <443>
```

### External

If you require an `external` load balancer, you can set the annotations as followed:

```yaml
service:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "false"
  type: LoadBalancer
  port: <443>
```

In this case, the service will automatically provision a public IP in Azure and assign it to the external Azure load balancer.

For commit-hash tags and semver releases `>= 1.2.1`, update the health probe annotation to:

```yaml
service:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: "/api/v1/health/readiness"
```

## Redis

For calver releases and semver releases earlier than `1.0.1`, the generated Helm overrides file renders the standard Redis settings:

```yaml
env:
  variables:
    TFE_REDIS_HOST: "<redis-host>:6380"
    TFE_REDIS_USE_AUTH: true
    TFE_REDIS_USE_TLS: true
```

For commit-hash tags and semver releases `>= 1.0.1`, the generated file also renders dedicated Sidekiq Redis settings for Azure Managed Redis:

```yaml
env:
  variables:
    TFE_REDIS_SIDEKIQ_HOST: "<sidekiq-redis-host>:10000"
    TFE_REDIS_SIDEKIQ_USE_AUTH: true
    TFE_REDIS_SIDEKIQ_USE_TLS: true
```
