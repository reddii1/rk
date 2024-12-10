resource "azurerm_resource_group" "powerbi-integration" {
  name     = "rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-powerbi-mi"
  location = var.location
  tags     = merge(var.tags, local.tags)
}
resource "random_password" "pbisvc" {
  length           = 32
  special          = false
}

resource "azurerm_key_vault_secret" "pbisvc" {
  name         = "pbisvc-password"
  value        = random_password.pbisvc.result
  key_vault_id = azurerm_key_vault.app.id
}
resource "azurerm_network_interface" "pbisvc" {
  name                = "nic-pbisvc-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  ip_configuration {
    name                          = "pbisvc"
    subnet_id                     = azurerm_subnet.fe02[0].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.tags, local.tags)
}

resource "azurerm_virtual_machine" "pbisvc" {
  // The prefix "uksucc" is important for internal naming policies
  name                = "uksuccpbisvc"
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  location            = var.location
  
  network_interface_ids = [azurerm_network_interface.pbisvc.id,]

  // The size of the VM will probably need to be changed in time
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  // This picks up the image from the GoldImagesDevGallery/GoldImagesGallery depending on the environment
  storage_image_reference {
    id = data.azurerm_shared_image_version.win2019_latestGoldImage.id
  }

// if the virtual machine OS options are changed, for example, provision_vm_agent, then terraform may get stuck on deployment with an error similar to below:
// Message="Changing property 'windowsConfiguration.provisionVMAgent' is not allowed."
// to fix this error just delete stuff manually. Apparently this is fixed in 2.0 but we're outdated. 
  storage_os_disk {
    name              = "osDiskpbisvc"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    // This MUST be randomised and stored in kv eventually
    admin_password = random_password.pbisvc.result
  }

  os_profile_windows_config {
    provision_vm_agent = true
    enable_automatic_upgrades = false

  }
  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_virtual_machine_extension" "pbisvc" {
  name                       = "ssms-installation"
  virtual_machine_id         = azurerm_virtual_machine.pbisvc.id
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

}
