# Deployment Customizations

This doc contains various deployment customizations as it relates to creating your TFE infrastructure, and their corresponding module input variables that you may additionally set to meet your own requirements where the module default values do not suffice. That said, all of the module input variables on this page are optional.

## AKS

If you want to configure this module to create an AKS cluster dedicated to running TFE:

```hcl
create_aks_cluster = true
```

If you are bringing your own AKS cluster (module default):

```hcl
create_aks_cluster = false
```

## TFE version

Set `tfe_image_tag` to control the TFE application version that Terraform and the generated Helm overrides target:

Calver release (default format):

```hcl
tfe_image_tag = "v202502-1"
```

Semver release:

```hcl
tfe_image_tag = "1.2.1"
```

Git commit hash:

```hcl
tfe_image_tag = "sha-abc1234"
```

You can supply a calver release tag, a semver release tag, or a Git commit hash here.

For commit-hash tags and semver releases `>= 1.0.1`, this input also switches the module to Azure Managed Redis with dedicated primary and Sidekiq Redis services. For commit-hash tags and semver releases `>= 1.2.1`, it also switches the generated health probe path to `/api/v1/health/readiness`.
