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
`aks.tf`:Simple AKS definition in terraform, the important in the definition which is an important part of the setup is
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

`app-gateway.tf`: Most of the configuration on App Gateway when connecting AKS with AGIC is a placeholder, that is because
the app gateway ingress controller (AGIC) will modify and maintain `listeners`, `backend settings`, `backend pools`
> Recommend using an own tf file for App Gateway configuration, this way the backend pool addresses wont be changed on stack deployment. Otherwise on terraform deploy, the backend pool addresses configured by AGIC will be wiped out

