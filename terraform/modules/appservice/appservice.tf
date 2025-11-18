resource "azurerm_service_plan" "test" {
  name                = "${var.application_type}-${var.resource_type}"
  location            = var.location
  resource_group_name = var.resource_group
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "test" {
  name                = "${var.application_type}-${var.resource_type}"
  location            = var.location
  resource_group_name = var.resource_group
  service_plan_id     = azurerm_service_plan.test.id

  site_config {
    application_stack {
      python_version = "3.12" # or node_version, dotnet_version, etc.
    }
    always_on = false
  }
}