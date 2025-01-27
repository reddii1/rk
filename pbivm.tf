# Define a random string to avoid naming conflicts
resource "random_string" "random" {
  length  = 8
  special = false
}

# Define the virtual machine
resource "azurerm_virtual_machine" "pbisvc" {
  count                = length(local.cpenvprefix[terraform.workspace])
  name                 = "vm-${local.cpenvprefix[terraform.workspace][count.index]}${random_string.random.result}"
  resource_group_name  = azurerm_resource_group.powerbi-integration.name
  location             = var.location
  network_interface_ids = [azurerm_network_interface.pbisvc[count.index].id]
  vm_size              = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_shared_image_version.win2019_latestGoldImage.id
  }

  storage_os_disk {
    name              = "osDisk-${local.cpenvprefix[terraform.workspace][count.index]}${random_string.random.result}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "admin@123"
  }

  os_profile_windows_config {
    provision_vm_agent          = true
    enable_automatic_upgrades   = false
  }

  identity {
    type = "SystemAssigned"
  }
}

# Define the network interface
resource "azurerm_network_interface" "pbisvc" {
  count = length(local.cpenvprefix[terraform.workspace])
  name                = "nic-${local.cpenvprefix[terraform.workspace][count.index]}mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.fe02[0].id
    private_ip_address_allocation = "Dynamic"
  }
}
