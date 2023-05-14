# Kubernetes Examples

This repository contains end to end examples of kubernetes cluster applications.

| Name                           | Description                                                                                                                                                                                                        | Features                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------- |
| [aks-agic-dns](./aks-agic-dns) | A Terraform config that deploys an AKS cluster with Azure Application Gateway Ingress Controller (AGIC), and a Helm Chart that deploys two NodeJS Services exposed publicly through a single APPGW Ingress and communicate with each other using DNS names | AKS, AGIC, Services, Deployment, Ingress, Helm, DNS, Terraform |
| [aks-agi-frontdoor](./aks-agic-frontdoor/) | A Terraform config that deploys an AKS cluster with AGIC and Azure Frontdoor | AKS, AGIC, Azure Frontdoor, Terraform |
