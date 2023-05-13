variable "aks_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "resource_group_name" {
  type = string
}

variable "deployment_environment" {
  type = string
}

variable "domain" {
  type = string
}