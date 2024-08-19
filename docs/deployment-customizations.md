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