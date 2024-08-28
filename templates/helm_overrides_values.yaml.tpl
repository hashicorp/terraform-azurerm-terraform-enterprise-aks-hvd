replicaCount: 1
tls:
  certificateSecret: <tfe-certs>
  caCertData: |
    <base64-encoded-tfe-custom-ca-bundle>

image:
 repository: images.releases.hashicorp.com
 name: hashicorp/terraform-enterprise
 tag: <v202407-1>

%{ if tfe_object_storage_azure_use_msi ~}
serviceAccount:
  annotations:
    # AKS Azure AD workload identity
    azure.workload.identity/client-id: ${tfe_user_assigned_identity_client_id}
    azure.workload.identity/use: "true"
%{ endif ~}

tfe:
  privateHttpPort: ${tfe_http_port}
  privateHttpsPort: ${tfe_https_port}
  metrics:
    enable: <true>
    httpPort: ${tfe_metrics_http_port}
    httpsPort: ${tfe_metrics_https_port}

service:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    service.beta.kubernetes.io/azure-load-balancer-ipv4: "<lb-static-ip>" # Available private IP address from TFE load balancer subnet
%{ if tfe_lb_subnet_name != "" ~}
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "${tfe_lb_subnet_name}"
%{ endif ~}
  type: LoadBalancer
  port: 443

env:
  secretRefs:
    - name: <tfe-secrets>

  variables:
    # TFE config settings
    TFE_HOSTNAME: ${tfe_hostname}

    # Database settings
    TFE_DATABASE_HOST: ${tfe_database_host}
    TFE_DATABASE_NAME: ${tfe_database_name}
    TFE_DATABASE_USER: ${tfe_database_user}
    TFE_DATABASE_PARAMETERS: ${tfe_database_parameters}

    # Object storage settings
    TFE_OBJECT_STORAGE_TYPE: azure
    TFE_OBJECT_STORAGE_AZURE_ACCOUNT_NAME: ${tfe_object_storage_azure_account_name}
    TFE_OBJECT_STORAGE_AZURE_CONTAINER: ${tfe_object_storage_azure_container}
%{ if tfe_object_storage_azure_endpoint != "" ~}
    TFE_OBJECT_STORAGE_AZURE_ENDPOINT: ${tfe_object_storage_azure_endpoint}
%{ endif ~}
    TFE_OBJECT_STORAGE_AZURE_USE_MSI: ${tfe_object_storage_azure_use_msi}
%{ if tfe_object_storage_azure_use_msi ~}
    TFE_OBJECT_STORAGE_AZURE_CLIENT_ID: ${tfe_object_storage_azure_client_id}
%{ endif ~}

    # Redis settings
    TFE_REDIS_HOST: ${tfe_redis_host}
    TFE_REDIS_USE_AUTH: ${tfe_redis_use_auth}
    TFE_REDIS_USE_TLS: ${tfe_redis_use_tls}
    