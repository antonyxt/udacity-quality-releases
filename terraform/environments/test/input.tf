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
variable "public_key_path" {
  type    = string
}
variable "virtual_network_name" {}
variable "address_prefix_test" {}
variable "address_space" {}
variable "admin_username" {}

