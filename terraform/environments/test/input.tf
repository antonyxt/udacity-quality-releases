# Azure GUIDS
variable "subscription_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "tenant_id" {
  type = string
}

# Resource Group/Location
variable "location" {
  type    = string
  default = "eastus"
}
variable "resource_group" {
  type    = string
  default = "Azuredevops"
}
variable "application_type" {
  type    = string
  default = "udacity-at-acn-test-app"
}

# Network
variable "virtual_network_name" {}
variable "address_prefix_test" {}
variable "address_space" {}
variable "admin_username" {}
variable "public_key" {}
variable "pat_token" {}
variable "azdo_org_url" {}
variable "project_name" {}
variable "env_name" {}
variable "svc_connection" {}
variable "env_vm_tags" {}
