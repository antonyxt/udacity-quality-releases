terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

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

resource "azurerm_linux_virtual_machine" "test_agent" {
  name                            = "linux-test-agent"
  location                        = var.location
  resource_group_name             = var.resource_group
  size                            = "Standard_B2s"
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.main.id]
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data = base64encode(templatefile("${path.module}/agent_install.sh", {
  }))
  source_image_id = var.packer_image_id

  tags = {
    selenium = "true"
  }
}


#############################################
# Log analytics for selinium logs
#############################################

data "azurerm_resource_group" "main" {
  name = "Azuredevops"
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "at-test-agent-law"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_data_collection_endpoint" "selenium_dce" {
  name                = "at-test-agent-dce"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azapi_resource" "data_collection_logs_table" {
  name      = "SeleniumLogs_CL"
  parent_id = azurerm_log_analytics_workspace.law.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"

  body = jsonencode({
    properties = {
      schema = {
        name = "SeleniumLogs_CL"
        columns = [
          {
            name        = "TimeGenerated"
            type        = "datetime"
            description = "Log timestamp"
          },
          {
            name        = "RawData"
            type        = "string"
            description = "Entire raw log line"
          }
        ]
      }
      retentionInDays      = 30
      totalRetentionInDays = 30
    }
  })
  lifecycle {
    ignore_changes = [
      body,
    ]
  }
}

resource "azurerm_monitor_data_collection_rule" "selenium_dcr" {

  name                        = "selenium-custom-log-dcr"
  location                    = var.location
  resource_group_name         = data.azurerm_resource_group.main.name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.selenium_dce.id

  # Explicit dependency

  depends_on = [
    azurerm_monitor_data_collection_endpoint.selenium_dce,
    azapi_resource.data_collection_logs_table
  ]

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "law-destination"
    }
  }

  data_sources {
    log_file {
      name = "selenium-file-source"

      file_patterns = [
        "/var/log/ui-test/*.log"
      ]

      format = "text" # can be json, text, csv

      streams = [
        "Custom-SeleniumLogs_CL"
      ]

      settings {
        text {
          record_start_timestamp_format = "ISO 8601"
        }
      }
    }
  }

  data_flow {
    streams      = ["Custom-SeleniumLogs_CL"]
    destinations = ["law-destination"]
  }
}

resource "time_sleep" "wait_for_vm_identity" {
  depends_on = [
    azurerm_linux_virtual_machine.test_agent
  ]
  create_duration = "60s"
}

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.test_agent.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  depends_on = [
    azurerm_monitor_data_collection_rule.selenium_dcr,
    time_sleep.wait_for_vm_identity
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_vm" {
  name                    = "selenium-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.test_agent.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.selenium_dcr.id

  depends_on = [
    azurerm_virtual_machine_extension.ama
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dce_vm" {
  name                        = "configurationAccessEndpoint"
  target_resource_id          = azurerm_linux_virtual_machine.test_agent.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.selenium_dce.id

  depends_on = [
    azurerm_virtual_machine_extension.ama
  ]
}

#############################################
# Action Group
#############################################

resource "azurerm_monitor_action_group" "selenium_action_group" {
  name                = "selenium-action-group-udacity-at"
  resource_group_name = data.azurerm_resource_group.main.name
  short_name          = "uiAutomation"

  email_receiver {
    name                    = "sendToAdmin"
    email_address           = "antonyxt@gmail.com"
    use_common_alert_schema = true
  }
}

#############################################
# Alert Rule for "Successfully logged in"
#############################################

resource "azurerm_monitor_scheduled_query_rules_alert" "selenium_login_success_alert" {
  name                = "selenium-success-login-alert"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  description = "Alert when 'Successfully logged in' appears in SeleniumLogs_CL"
  enabled     = true
  severity    = 3
  frequency   = 5 # run the query every 5 minutes
  time_window = 5 # query last 5 minutes

  data_source_id = azurerm_log_analytics_workspace.law.id

  query = <<-KQL
    SeleniumLogs_CL
    | where TimeGenerated > ago(5m)
    | where RawData contains "Login Successfull"
    | summarize Count = count()
    | where Count > 0
  KQL

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  # ✅ Correct block required by this resource type
  action {
    action_group = [
      azurerm_monitor_action_group.selenium_action_group.id
    ]
  }
}