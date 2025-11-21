provider "azurerm" {
  features {}
}
terraform {
  backend "azurerm" {
    resource_group_name  = "Azuredevops"
    storage_account_name = "tfstateatacnudacity"
    container_name       = "tfstate"
    key                  = "at.quality.terraform.tfstate"
  }
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13.0"
    }
  }
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
  name                = "linux-agent-image" # your Packer managed image name
  resource_group_name = "Azuredevops"         # where Packer stored the image
}

module "vm" {
  source          = "../../modules/vm"
  location        = var.location
  resource_group  = module.resource_group.resource_group_name
  public_key      = var.public_key
  public_ip       = module.publicip.public_ip_address_id
  subnet_id       = module.network.subnet_id_test
  admin_username  = var.admin_username
  packer_image_id = data.azurerm_image.packer_image.id
}

resource "azurerm_monitor_action_group" "http_404_action_group" {
  name                = "http-404-alerts"
  resource_group_name = module.resource_group.resource_group_name
  short_name          = "http-404"

  email_receiver {
    name          = "email-notifications"
    email_address = "antonyxt@gmail.com"
  }
}


resource "azurerm_monitor_metric_alert" "alert_http_404" {
  name                = "alert-http-404"
  resource_group_name = module.resource_group.resource_group_name
  scopes              = [module.appservice.app_id] 
  description         = "Alert for HTTP 404"

  severity = 3
  enabled  = true

  frequency 		   = "PT1M"   # check every 1 minute
  window_size          = "PT5M"   # evaluate last 5 minute

  action {
    action_group_id = azurerm_monitor_action_group.http_404_action_group.id
  }

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http404"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1   # triggers when > 1 error occurs
    # skip_metric_validation = true  # enable if Terraform fails metric verification
  }
}