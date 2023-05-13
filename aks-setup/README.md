## Azure AKS to App Gateway to Azure Front Door Setup

### Description
The following Article will detail the setup from Azure Kubernetes Service (AKS) to Azure Application Gateway (AGIC) to Azure Front Door (AFD).
It will explain the networking aspect of the setup and how to debug different components. The complete setup is done in Terraform.

There are various ways to setup App gateway over external internet access
1. Using App Gateway itself connected to the internet,  certificate mangement needs to be maintained by the origanization.
2. Using Azure Front Door (AFD) to manage the certificate and connect to App Gateway over private IP.
3. Using Azure Front Door (AFD) to manage the certificate and connect to App Gateway over public IP.

The second approach uses Azure Private link to connect AFD to App Gateway, the AFD in this case needs to be of a Premium SKU.

> We will be following the third way in this documentation.

### Prerequisites
- Azure Subscription
- Terraform installed
- kubectl (Debug/Testing)

### Setup
`aks.tf`:Simple AKS definition in terraform, the important part in the aks definition setup is the network profile.
```hcl
network_profile {
    network_plugin = "azure"
    network_policy = "azure"
}
```
The network profile selected is Azure CNI, there are two types of networking in AKS:
- Kubenet: This is the default networking in AKS, it is a simple networking solution that does not require any additional configuration. It is a basic, flat network that provides connectivity between pods and other network resources. It does not provide advanced networking features such as network policy.
- Azure CNI: This is an advanced networking solution that provides more granular control, and uses the Azure Container Networking Interface (CNI) plug-in to integrate with the Azure Virtual Network. It provides each pod with its own IP address and subnet, and supports advanced networking features such as network policy.

**Note:**
You need to plan based on number of apps the size of the virtual network. By default, Azure CNI will configure 30 pods per node. If you have more than 30 pods per node, you need to increase the size of the virtual network subnet. For example, if you have 100 pods per node, you need to configure a /22 subnet.

> AKS clusters may not use 169.254.0.0/16, 172.30.0.0/16, 172.31.0.0/16, or 192.0.2.0/24 for the Kubernetes service address range, pod address range, or cluster virtual network address range.

It is important to decide which networking solution to use before deploying the cluster, as this choice will affect the way the cluster further connections to App Gateway. A kubenet requires more configurations and addons to be enabled in an AKS cluster to be able to connect to App Gateway. Azure CNI is the recommended networking solution for AKS clusters.

All the required documentation for Azure CNI or Kubenet setup can be found here
- [Setup for kubenet or Azure CNI](https://azure.github.io/application-gateway-kubernetes-ingress/how-tos/networking/)
- [Azure CNI](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
----------------
`app-gateway.tf`: Most of the configuration on App Gateway when connecting AKS with AGIC is a placeholder, that is because
the app gateway ingress controller (AGIC) will modify and maintain `listeners`, `backend settings`, `backend pools`
> Recommend using an own tf file for App Gateway configuration, this way the backend pool addresses wont be changed on stack deployment. Otherwise on terraform deploy, the backend pool addresses configured by AGIC will be wiped out
----------------
`role-assignments.tf`: Role assignments are one of the most imporatant part of the setup, role assignments are required by AGIC to amend records  in app gateway and to read subnet addresses in a resource group

```hcl
resource "azurerm_role_assignment" "aks_ingress_to_app_gateway_contributor_access" {
  principal_id                     = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_application_gateway.app_gateway.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks, azurerm_application_gateway.app_gateway]
}

resource "azurerm_role_assignment" "aks_ingress_to_resource_group_reader_access" {
  principal_id                     = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  role_definition_name             = "Reader"
  scope                            = azurerm_resource_group.rg.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks, azurerm_application_gateway.app_gateway]
}
```
The above role assignments particularly assign AGIC in AKS to modilfy and read App Gateway and Resource Group respectively.

----------------
`frontdoor.tf`: The front door setup is pretty straight forward, things to note in the setup is the public ip address which is connected to App Gateay reflects in the origin for frontdoor.
App Gateway terraform outputs does not provide this information otherwise it would have been wise to use the app gateway output as the origin here.

**Note:**
If you check the UI for frontdoor origin it will come up as custom even if it you specifically select it as app gateway from the UI. This is just how Azure FD interprets it.

> It is important not to set a host header in the front door setup. This is because if the host header is set, front door will not pass the origin custom domain to app gateway. Hence AGIC yaml needs to use path based routing. If the host header is not set the custom domain address will be passed to App Gateway enabling custom domain routing through AGIC.

----------------

### Debugging tips
> This example does not contain connection settings to a log workspace but this can be easily achieved through Terraform.
- **App Gateway:** The best way to debug app gateway is to use the logs in the app gateway itself. The logs can be found in the app gateway under `Log workspace`. The logs can be filtered based on the `backend pool` or `backend http settings` or `listener`. The logs are very detailed and provide a lot of information on the request and response.
- **AGIC:** The AGIC logs can be tailed using kubectl commands. The other way is to connect a log workspace to AKS and use it to get logs. When a setup includes AGIC the kubectl logs can be followed and provide a much better experience

**Note:** When AGIC is deployed you can observe ingress-controller pod in the kubesystem namespace, also if you follow the logs it will provide you the lates configuration deployed.
```kubectl
kubectl logs ingress-appgw-deployment-* -n kube-system
```
----------------

### AGIC example with custom domains
Following is an example of AGIC yaml. PathType is a preference based on the app configuration. More detailed explanation for help can be found here [PathType](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-gateway-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
    - host: "helloworld.example.com"
      http:
        paths:
          - path: /
            backend:
              service:
                name: <helloworld-clusterip-service-name>
                port:
                  number: <helloworld-container-port>
            pathType: Prefix
    - host: "goodbyeworld.example.com"
      http:
        paths:
          - path: /
            backend:
              service:
                name: <goodbyeworld-clusterip-service-name>
                port:
                  number: <goodbyeworld-container-port>
            pathType: Prefix
```
> When it is a path based routing scenario, the host is not needed while the path value will change based on application paths.

There are different annotations provided by azure which help you in complex cases.
- [Azure annotations](https://azure.github.io/application-gateway-kubernetes-ingress/annotations/)

### Remarks
The documentation and example provides a way to deploy AKS -> App Gateway -> Front Door.