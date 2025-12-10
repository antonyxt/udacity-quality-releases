variable "azdo_url" {
  type    = string
  default = "https://dev.azure.com/odluser291496"
}
variable "azdo_pat" {
  type    = string
  default = "azdo_pat"
}

variable "subscription_id" {
  type    = string
  default = "4e780871-9657-43bf-b521-9c73706b76b1"
}

variable "common_tags" {
  type = map(string)
  default = {
    environment = "dev"
    owner       = "terraform"
  }
}

variable "resource_location" {
  description = "Location of the resources"
  type        = string
  default     = "eastus"
}

# Optional if you want to pass Azure DevOps config via environment

variable "azdo_pool" {
  type    = string
  default = "my-agent-pool"
}

variable "admin_username" {
  type    = string
  default = "qwaszx"
}

variable "admin_password" {
  type    = string
  default = "1qaz@WSX1qaz"
}

variable "alert_email" {
  description = "Email to receive alert notifications"
  type        = string
  default     = "antonyxt@gmail.com"
}
