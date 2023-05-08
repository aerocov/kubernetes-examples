## Prerequisites

1. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
3. Setup [Terraform for Azure](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/azure-build)
4. Create and assign [role assignment](./auth-custom-role.json) role to the Terraform service principal
5. Install [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
6. Install [Helm](https://helm.sh/docs/intro/install/)

## Deploy cluster

```sh
cd ./terraform

terraform init

terraform validate

terraform apply --var-file=values.tfvars

```

## Deploy Applications

```sh
# add cluster credentials to kube-config
az aks get-credentials --resource-group rg-poc-aksdemo --name aks-poc-aksdemo

# install app
helm install aksdemo app
```
