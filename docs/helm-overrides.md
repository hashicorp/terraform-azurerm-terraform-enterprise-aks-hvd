# Helm Overrides

This doc contains various customizations that are supported within your Helm overrides file for your TFE deployment.

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