resource "random_string" "powerbi" {
    length  = 8
    special = false
}

##############################
### Storage for Power BI VM ###
###############################
resource "azurerm_storage_account" "powerbi" {
  name                     = "struks${terraform.workspace}dccnvpbi"
  resource_group_name      = azurerm_resource_group.powerbi-integration.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT", "PATCH"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 200
    }
  }
  tags = merge(var.tags, local.tags)
}

resource "azurerm_storage_container" "powerbi" {
  name                 = "powerbi-gateway"
  storage_account_name = azurerm_storage_account.powerbi.name
}

resource "azurerm_storage_blob" "powerbi" {
  name                   = "powerbi-gateway.ps1"
  storage_account_name   = azurerm_storage_account.powerbi.name
  storage_container_name = azurerm_storage_container.powerbi.name
  type                   = "Block"
  access_tier            = "Cool"
  source                 = "../scripts/powerbi_gateway_install.ps1"
}

#################
### VM Setup ###
#################
resource "random_password" "powerbi" {
  length  = 32
  special = false
}

resource "azurerm_key_vault_secret" "powerbi" {
  name         = "powerbi-password"
  value        = random_password.powerbi.result
  key_vault_id = azurerm_key_vault.app.id
}

resource "azurerm_virtual_machine" "powerbi" {
  name                = "uksuccpowerbi-${random_string.powerbi.result}"
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  location            = var.location
  network_interface_ids = [azurerm_network_interface.powerbi.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_shared_image_version.win2019_latestGoldImage.id
  }

  storage_os_disk {
    name              = "osDiskPowerBI-${random_string.powerbi.result}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = random_password.powerbi.result
  }

  os_profile_windows_config {
    provision_vm_agent = true
    enable_automatic_upgrades = false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, local.tags, { "Persistence" = "Ignore" })
}

resource "azurerm_network_interface" "powerbi" {
  name                = "nic-powerbi"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  ip_configuration {
    name                          = "powerbi"
    subnet_id                     = azurerm_subnet.be02[0].id
    private_ip_address_allocation = "Dynamic"
  }
  tags = merge(var.tags, local.tags)
}

resource "time_sleep" "wait_120_seconds_powerbi" {
  depends_on = [ azurerm_virtual_machine.powerbi ]
  create_duration = "120s"
}

resource "azurerm_virtual_machine_extension" "powerbi" {
  name                       = "powerbi-installation"
  virtual_machine_id         = azurerm_virtual_machine.powerbi.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  depends_on = [ time_sleep.wait_120_seconds_powerbi ]

  protected_settings = <<PROTECTED_SETTINGS
      {
          "fileUris": ["${format("https://%s.blob.core.windows.net/%s/%s", azurerm_storage_account.powerbi.name, azurerm_storage_container.powerbi.name, azurerm_storage_blob.powerbi.name)}"],
          "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ${azurerm_storage_blob.powerbi.name} -installPowerBI",
          "storageAccountName": "${azurerm_storage_account.powerbi.name}",
          "storageAccountKey": "${azurerm_storage_account.powerbi.primary_access_key}"
      }
  PROTECTED_SETTINGS
  
  tags = merge(var.tags, local.tags)
}
