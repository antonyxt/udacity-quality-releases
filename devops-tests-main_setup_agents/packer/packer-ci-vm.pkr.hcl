packer {
  required_plugins {
    azure = {
      version = ">= 1.7.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
  sensitive = true
}

source "azure-arm" "ubuntu" {
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  tenant_id                         = var.tenant_id
  subscription_id                   = var.subscription_id

  managed_image_resource_group_name = "Azuredevops"
  managed_image_name                = "linux-agent-image"
  location                          = "eastus"
  vm_size                           = "Standard_B2s"

  os_type        = "Linux"
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"
  image_version   = "latest"

  ssh_username = "azureuser"
}

build {
  name    = "ubuntu-selenium-agent"
  sources = ["source.azure-arm.ubuntu"]

  provisioner "shell" {
    inline = [
      "set -e",

      "# -----------------------------",
      "# Basic tools & dependencies",
      "# -----------------------------",
      "sudo apt-get update -y",
      "sudo apt-get install -y wget zip unzip curl software-properties-common apt-transport-https ca-certificates git",

      "# -----------------------------",
      "# Install Python 3 and venv",
      "# -----------------------------",
      "sudo add-apt-repository -y ppa:deadsnakes/ppa",
      "sudo apt-get update -y",
      "sudo apt-get install -y python3 python3-pip python3-venv python3.7-distutils",

      "# -----------------------------",
      "# Install Google Chrome",
      "# -----------------------------",
      "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb",
      "sudo apt-get install -y ./google-chrome-stable_current_amd64.deb || sudo apt --fix-broken install -y",
      "rm -f google-chrome-stable_current_amd64.deb",

      "# -----------------------------",
      "# Install ChromeDriver",
      "# -----------------------------",
      "CHROME_VERSION=$(google-chrome --version | awk '{print $3}')",
      "MAJOR_VERSION=$(echo \"$CHROME_VERSION\" | cut -d '.' -f 1)",
      "DRIVER_VERSION=$(curl -s https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json | jq -r \".versions[] | select(.version | startswith(\\\"$MAJOR_VERSION.\\\")) | .version\" | tail -n1)",
      "wget -q \"https://storage.googleapis.com/chrome-for-testing-public/$DRIVER_VERSION/linux64/chromedriver-linux64.zip\"",
      "unzip chromedriver-linux64.zip",
      "sudo mv chromedriver-linux64/chromedriver /usr/local/bin/chromedriver",
      "sudo chmod +x /usr/local/bin/chromedriver",
      "rm -rf chromedriver-linux64 chromedriver-linux64.zip",

      "# -----------------------------",
      "# Install Java 11",
      "# -----------------------------",
      "sudo apt-get install -y openjdk-11-jdk",
      "echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' | sudo tee -a /etc/profile",
      "echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee -a /etc/profile",

      "# -----------------------------",
      "# Install JMeter 5.6.3",
      "# -----------------------------",
      "JMETER_VERSION=5.6.3",
      "cd /opt",
      "sudo wget https://downloads.apache.org/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz",
      "sudo tar -xf apache-jmeter-$JMETER_VERSION.tgz",
      "sudo mv apache-jmeter-$JMETER_VERSION /opt/jmeter",
      "sudo ln -s /opt/jmeter/bin/jmeter /usr/local/bin/jmeter",
      "sudo rm -f apache-jmeter-$JMETER_VERSION.tgz",

      "# -----------------------------",
      "# Install Azure DevOps Agent prerequisites",
      "# -----------------------------",
      "sudo apt-get install -y libssl-dev libffi-dev build-essential",

      "# -----------------------------",
      "# Cleanup",
      "# -----------------------------",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}
