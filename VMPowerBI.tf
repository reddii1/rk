#################
### VM Setup ###
#################

resource "random_password" "pbi_password" {
  count   = length(local.cpenvprefix[terraform.workspace])
  length  = 32
  special = false
}

resource "azurerm_key_vault_secret" "pbi_password" {
  count        = length(local.cpenvprefix[terraform.workspace])
  name         = "adf-sql-${local.cpenvprefix[terraform.workspace][count.index]}password"
  value        = random_password.pbi_password[count.index].result
  key_vault_id = azurerm_key_vault.app.id
}

// Random string for naming (lowercase as per naming policies)
resource "random_string" "random_lower" {
  length  = 8
  special = false
  upper   = false
}

// Resource group for the VM
resource "azurerm_resource_group" "pbi" {
  name     = "rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-pbi"
  location = var.location
  tags     = merge(var.tags, local.tags)
}

// Virtual Machine
resource "azurerm_virtual_machine" "pbi" {
  name                = "vm-pbi-${random_string.random_lower.result}"
  resource_group_name = azurerm_resource_group.pbi.name
  location            = var.location
  network_interface_ids = [
    azurerm_network_interface.pbi.id
  ]
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_shared_image_version.win2019_latestGoldImage.id
  }

  storage_os_disk {
    name              = "osDiskpbi-${random_string.random_lower.result}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "pbi-vm"
    admin_username = "adminuser"
    admin_password = random_password.pbi_password[0].result
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
  }

  identity {
    type = "SystemAssigned"
  }
}

// Network Interface
resource "azurerm_network_interface" "pbi" {
  name                = "nic-pbi-${random_string.random_lower.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.pbi.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.fe02[0].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

#######################
### VM Custom Script ###
#######################
resource "azurerm_virtual_machine_extension" "pbi" {
  name                       = "pbi-powerbi-installation"
  virtual_machine_id         = azurerm_virtual_machine.pbi.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = <<PROTECTED_SETTINGS
  {
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -Command \"
    Write-Output 'Starting pbi and Power BI Installation...';

    # Power BI Installation
    $powerBiDownloadUrl = 'https://download.microsoft.com/download/8/9/7/8972a0b2-6c35-4f96-b3a3-0249c2e0b1b4/PowerBIDesktopSetup_x64.exe';
    $powerBiInstallerPath = 'C:\\Temp\\PowerBIDesktopSetup_x64.exe';
    Invoke-WebRequest -Uri $powerBiDownloadUrl -OutFile $powerBiInstallerPath;
    Start-Process -FilePath $powerBiInstallerPath -ArgumentList '/quiet', '/norestart' -Wait;

    Write-Output 'Installation Completed Successfully.';
    \""
  }
  PROTECTED_SETTINGS
}
