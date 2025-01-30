
// this random var is just so that things can be built and destroyed without residual namespace errors. This can be removed later.
resource "random_string" "random" {
    length = 8
    special = false
}

#########################
### variables for VM ###
########################
resource "azuread_application" "pbi_vm" {
  display_name = "pbi_vm"
}

resource "azuread_application_password" "pbivm" {
  application_object_id = azuread_application.pbivm.object_id
  display_name          = "pbivm-password"
  end_date             = "2099-01-01T00:00:00Z"
}

resource "azurerm_key_vault_secret" "pbivm" {
  name         = "pbivm-password"
  value        = azuread_application_password.pbivm.value  # Use the generated password
  key_vault_id = azurerm_key_vault.app.id
}

#################
### VM setup ###
################

// this vm has to be windows since pbivm only supports it
resource "azurerm_virtual_machine" "pbivm" {
  // The prefix "uksucc" is important for internal naming policies
  name                = "uksuccpbivm-${random_string.random.result}"
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  location            = var.location
  
  network_interface_ids = [azurerm_network_interface.pbivm.id,]

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
    name              = "osDiskpbivm-${random_string.random.result}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    // This MUST be randomised and stored in kv eventually
    admin_password = azurerm_key_vault_secret.pbivm.result
  }

  os_profile_windows_config {
    provision_vm_agent = true
    enable_automatic_upgrades = false

  }
  identity {
    type = "SystemAssigned"
  }
  tags = merge(var.tags, local.tags, {
    "Persistence" = "Ignore"
  })

}

// this NIC is to be associated within the Fe02 Subnet as this is where MySQL has exposure and where tableau currently connects from

resource "azurerm_network_interface" "pbivm" {

  name                = "nic-pbivm-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  ip_configuration {
    name                          = "pbivm"
    subnet_id                     = azurerm_subnet.be02[0].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.tags, local.tags)
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [ azurerm_virtual_machine.pbivm]
  create_duration = "120s"
}
