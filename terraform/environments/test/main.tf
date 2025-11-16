provider "azurerm" {
  features {}
}
terraform {
  backend "azurerm" {}
}
module "resource_group" {
  source         = "../../modules/resource_group"
  resource_group = var.resource_group
  location       = var.location
}
module "network" {
  source               = "../../modules/network"
  address_space        = var.address_space
  location             = var.location
  virtual_network_name = var.virtual_network_name
  application_type     = var.application_type
  resource_type        = "NET"
  resource_group       = module.resource_group.resource_group_name
  address_prefix_test  = var.address_prefix_test
}

module "nsg-test" {
  source              = "../../modules/networksecuritygroup"
  location            = var.location
  application_type    = var.application_type
  resource_type       = "NSG"
  resource_group      = module.resource_group.resource_group_name
  subnet_id           = module.network.subnet_id_test
  address_prefix_test = var.address_prefix_test
}
module "appservice" {
  source           = "../../modules/appservice"
  location         = var.location
  application_type = var.application_type
  resource_type    = "AppService"
  resource_group   = module.resource_group.resource_group_name
}
module "publicip" {
  source           = "../../modules/publicip"
  location         = var.location
  application_type = var.application_type
  resource_type    = "publicip"
  resource_group   = module.resource_group.resource_group_name
}

data "azurerm_image" "packer_image" {
  name                = "quality-test-server" # your Packer managed image name
  resource_group_name = "Azuredevops"         # where Packer stored the image
}

module "vm" {
  source          = "../../modules/vm"
  location        = var.location
  resource_group  = module.resource_group.resource_group_name
  public_key_path = var.public_key_path
  public_ip       = module.publicip.public_ip_address_id
  subnet_id       = module.network.subnet_id_test
  admin_username  = var.admin_username
  packer_image_id = data.azurerm_image.packer_image.id
}