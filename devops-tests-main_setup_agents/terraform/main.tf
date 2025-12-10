
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "main" {
  name = "Azuredevops"
}


# Get your Packer Image (same as LB config)
data "azurerm_image" "packer_image" {
  name                = "linux-agent-image"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Public IP
resource "azurerm_public_ip" "vm_ip" {
  name                = "singlevm-public-ip"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NSG
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "singlevm-nsg"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network
resource "azurerm_virtual_network" "vnet" {
  name                = "singlevm-vnet"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.90.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "singlevm-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.90.1.0/24"]
}

# NIC
resource "azurerm_network_interface" "nic" {
  name                = "singlevm-nic"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# ✅ VM Using Packer Image
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "linux-build-agent"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.main.name
  size                = "Standard_B2s"

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  # ✅ Use your packer image
  source_image_id = data.azurerm_image.packer_image.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data = base64encode(templatefile("${path.module}/agent_install.sh", {
    ADO_URL    = var.azdo_url
    PAT_TOKEN  = var.azdo_pat
    POOL_NAME  = var.azdo_pool
    ADMIN_USER = var.admin_username
    AGENT_FILE = "vsts-agent-linux-x64-4.264.2.tar.gz"
    AGENT_URL  = "https://download.agent.dev.azure.com/agent/4.264.2/vsts-agent-linux-x64-4.264.2.tar.gz"
    VM_NAME    = "self-host-agent"
  }))
}

output "public_ip" {
  value = azurerm_public_ip.vm_ip.ip_address
}
