// Generate a random string for resource uniqueness
resource "random_string" "random" {
    length  = 8
    special = false
}

#################
### VM Setup ###
#################

resource "azurerm_virtual_machine" "pbi" {
    name                = "vm-pbi-${random_string.random.result}"
    resource_group_name = azurerm_resource_group.powerbi-integration.name
    location            = var.location
    network_interface_ids = [
        azurerm_network_interface.pbi.id
    ]
    vm_size               = "Standard_DS1_v2"
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true

    // Using a shared image for the VM OS
    storage_image_reference {
        id = data.azurerm_shared_image_version.win2019_latestGoldImage.id
    }

    storage_os_disk {
        name              = "osDiskpbi-${random_string.random.result}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "pbi-vm"
        admin_username = "adminuser"
        admin_password = random_password.pbi.result
    }

    os_profile_windows_config {
        provision_vm_agent       = true
        enable_automatic_upgrades = false
    }

    identity {
        type = "SystemAssigned"
    }
}

// Generate a secure password for the admin user
resource "random_password" "pbi" {
    length  = 32
    special = false
}

// Network Interface
resource "azurerm_network_interface" "pbi" {
    name                = "nic-pbi-${random_string.random.result}"
    location            = var.location
    resource_group_name = azurerm_resource_group.powerbi-integration.name

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

    // Embedded scripts for pbi and Power BI
    protected_settings = <<PROTECTED_SETTINGS
      {
          "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -Command \"
          Write-Output 'Starting pbi and Power BI Installation...';

          # pbi Installation
          Write-Output 'Starting pbi Installation...';
          $pbiDownloadUrl = 'https://<YOUR_pbi_DOWNLOAD_URL>';
          $pbiInstallerPath = 'C:\\Temp\\adf-pbi.exe';
          Invoke-WebRequest -Uri $pbiDownloadUrl -OutFile $pbiInstallerPath;
          Start-Process -FilePath $pbiInstallerPath -ArgumentList '/quiet' -Wait;

          # Power BI Installation
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
