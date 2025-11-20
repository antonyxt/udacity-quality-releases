resource "azurerm_network_interface" "main" {
  name                = "nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "linux-test-agent1"
  location                        = var.location
  resource_group_name             = var.resource_group
  size                            = "Standard_DS2_v2"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data = base64encode(
    file("${path.module}/dependency_install.sh")
  )
  source_image_id = var.packer_image_id

  tags = {
    selenium = "true"
  }
}
