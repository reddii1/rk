# App Connector Image Marketplace Agreement
resource "azurerm_marketplace_agreement" "zpa" {
  publisher = "zscaler"
  offer     = "zscaler-private-access"
  plan      = "zpa-con-azure"
  count = terraform.workspace == "prod" ? 1:0
}

# Declare azapi_resource to create SSH key pair
resource "azapi_resource" "ssh_public_key" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name        = "example-ssh-key"
  location    = azurerm_resource_group.rg_app.location
  parent_id   = azurerm_resource_group.rg_app.id
}

# Generate SSH Key Pair
resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"
  response_export_values = ["publicKey", "privateKey"]
}

# Network
resource "azurerm_network_interface" "app_connector_nic" {
  name                = "nic-${local.location_prefix}-${terraform.workspace}-${var.pdu}-app-connector-0${count.index}"
  location            = azurerm_resource_group.rg_app.location
  resource_group_name = azurerm_resource_group.rg_app.name
  ip_configuration {
    name                          = "zpa-ip"
    subnet_id                     = azurerm_subnet.fe01.id
    private_ip_address_allocation = "Dynamic"
  }
  count = terraform.workspace == "prod" ? 2:0
  tags = merge(var.tags, local.tags)
}

resource "azurerm_network_interface_security_group_association" "app_connector_nic_nsg" {
  network_interface_id      = azurerm_network_interface.app_connector_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.fe01.id
  count = terraform.workspace == "prod" ? 2:0
}

# VM
resource "azurerm_virtual_machine" "app_connector" {
  name                = "${local.location_prefix}-${terraform.workspace}-${var.pdu}-app-connector-0${count.index}"
  resource_group_name = azurerm_resource_group.rg_app.name
  location            = azurerm_resource_group.rg_app.location
  vm_size             = "Standard_F4s_v2"
  count = terraform.workspace == "prod" ? 2:0
  network_interface_ids = [
    azurerm_network_interface.app_connector_nic[count.index].id,
  ]
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  os_profile {
    computer_name  = "${local.location_prefix}-${terraform.workspace}-${var.pdu}-app-connector-0${count.index}"
    admin_username = "azureuser"

    custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      echo "10.86.154.20 cp.services.aks-prod-int.az.dwpcloud.uk" | sudo tee -a /etc/hosts
      echo "10.86.154.20 analytics.services.aks-prod-int.az.dwpcloud.uk" | sudo tee -a /etc/hosts
    CUSTOM_DATA
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWdi/DiYUFPuFmH/XYP8kW4vPOIqa14RdmpZAd0tS/HbSsSybQY+jTlBt9RxRTxiMqSc/OO/N3UYwBPGD/4KjtWG1dKfiLhoQlRqZKNHRAtnEqdWwQIk+vXTznznW1NoRu8OPmnNZGR9o0ANksHAVk+ivd87NqftWEc3GQQTHZpc3SmrVdScCWe41JDLkSZVSpCJ0w32fsJ8FW7q2lKIH3gZIxytmb6O1qX3kocU35jS7De+QxeV0GPRLFIXuWPKgHlvZmBI2xVcpQu2IdJWU6M7D9xrlvOyJAq73YXuvhWwMoucoTBDEgDR6cAXrOV+rfHcbHYra4eLOI5jGM9HSp6vd4FpSrQCN3hK/wZgTkVUlf6JEPW697t1MGf3Ywny9cx6owKXhFy7rQbzKG4IGdS8OPUCk6SyEVF9rsNQAdKMjcQCox3IPJnn26DyP60qan+AjITDpoe9F/O869RpTLEUnQkd+2yDujmBYIIapSFHwncyD33YKhK7YAmuga4W0= shafiq.alibhai4@DEM-C02GX042MD6M"
      path     = "/home/azureuser/.ssh/authorized_keys"
    }
  }
  storage_os_disk {
    name              = "${local.location_prefix}-${terraform.workspace}-${var.pdu}-app-connector-0${count.index}_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  plan {
    publisher = "zscaler"
    product   = "zscaler-private-access"
    name      = "zpa-con-azure"
  }

  storage_image_reference {
    publisher = "zscaler"
    offer     = "zscaler-private-access"
    sku       = "zpa-con-azure"
    version   = "latest"
  }
  
  tags = merge(var.tags, local.tags, {
    "Persistence" = "Ignore"
  })
}


# Configure Provisioning Key 
# (Uncomment after the provisioning key has been manually added to the core key vault in Prod)

resource "azurerm_virtual_machine_extension" "app_connector_provisioning_key" {
  name                 = "app-connector-provisioning-key"
  virtual_machine_id   = azurerm_virtual_machine.app_connector[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  settings = <<SETTINGS
 {
  "script": "${base64encode(templatefile("../scripts/apply_app_connector_provisioning_key.sh", {provisioning-key="${data.azurerm_key_vault_secret.app-connector-provisioning-key[0].value}"}))}"
 }
SETTINGS
  count = terraform.workspace == "prod" ? 2:0
  tags = merge(var.tags, local.tags)
}
