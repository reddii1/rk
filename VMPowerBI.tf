#################
### VM Setup ###
#################

# Generate a random password for the VM
resource "random_password" "pbi_password" {
  count   = length(local.cpenvprefix[terraform.workspace])
  length  = 32
  special = false
}

# Store the password in Azure Key Vault
resource "azurerm_key_vault_secret" "pbi_password" {
  count        = length(local.cpenvprefix[terraform.workspace])
  name         = "pbi-pwd-${local.cpenvprefix[terraform.workspace][count.index]}password"
  value        = random_password.pbi_password[count.index].result
  key_vault_id = azurerm_key_vault.app.id
}

# Generate a random string for resource naming
resource "random_string" "random_lower" {
  length  = 8
  special = false
  upper   = false
}

# Define a Windows VM for pbi
resource "azurerm_virtual_machine" "pbi" {
  count                = length(local.cpenvprefix[terraform.workspace])
  name                 = "uksuccpbi-${local.cpenvprefix[terraform.workspace][count.index]}${random_string.random_lower.result}"
  resource_group_name  = azurerm_resource_group.powerbi_integration.name
  location             = var.location
  network_interface_ids = [azurerm_network_interface.pbi[count.index].id]
  vm_size              = "Standard_DS1_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_shared_image_version.win2019_latestGoldImage.id
  }

  storage_os_disk {
    name              = "osDiskpbi-${local.cpenvprefix[terraform.workspace][count.index]}${random_string.random_lower.result}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "pbi-vm"
    admin_username = "adminuser"
    admin_password = random_password.pbi_password[count.index].result
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Network Interface for pbi VM
resource "azurerm_network_interface" "pbi" {
  count                = length(local.cpenvprefix[terraform.workspace])
  name                 = "nic-pbi-${local.cpenvprefix[terraform.workspace][count.index]}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.powerbi_instance.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.fe02[0].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.tags, local.tags)
}

# Custom Script to install Power BI on the VM
resource "azurerm_virtual_machine_extension" "pbi" {
  name                       = "pbi-powerbi-installation"
  virtual_machine_id         = azurerm_virtual_machine.pbi[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = <<PROTECTED_SETTINGS
  {
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -Command \"
    Write-Output 'Starting Power BI Installation...';

    $powerBiDownloadUrl = 'https://download.microsoft.com/download/8/9/7/8972a0b2-6c35-4f96-b3a3-0249c2e0b1b4/PowerBIDesktopSetup_x64.exe';
    $powerBiInstallerPath = 'C:\\Temp\\PowerBIDesktopSetup_x64.exe';
    Invoke-WebRequest -Uri $powerBiDownloadUrl -OutFile $powerBiInstallerPath;
    Start-Process -FilePath $powerBiInstallerPath -ArgumentList '/quiet', '/norestart' -Wait;

    Write-Output 'Installation Completed Successfully.';
    \""
  }
  PROTECTED_SETTINGS
}

# Delay resource to ensure VM setup completion
resource "time_sleep" "wait_120_seconds" {
  depends_on      = [azurerm_virtual_machine.pbi]
  create_duration = "120s"
}
