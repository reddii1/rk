terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id[terraform.workspace]
  tenant_id       = var.tenant_id
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.pdu}-${terraform.workspace}-rg"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.pdu}-${terraform.workspace}-vnet"
  address_space       = var.vnet_address_spaces[terraform.workspace]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.fe01_subnet_cidr[terraform.workspace]
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.pdu}-${terraform.workspace}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "${var.pdu}-${terraform.workspace}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.pdu}-${terraform.workspace}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.pdu}-${terraform.workspace}-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_B2ms"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-pro"
    version   = "latest"
  }

  admin_username = "azureuser"
  admin_password = "P@ssw0rd12345!"
  tags           = var.tags
}

# Custom Script Extension to Install Power BI
resource "azurerm_virtual_machine_extension" "powerbi" {
  name                 = "PowerBIInstaller"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"Invoke-WebRequest -Uri 'https://download.microsoft.com/download/2/1/4/214a204f-15a6-421d-b8c7-8c567f4a41a8/PowerBIDesktop.msi' -OutFile 'C:\\PowerBIDesktop.msi'; Start-Process msiexec.exe -ArgumentList '/i C:\\PowerBIDesktop.msi /quiet /norestart' -Wait\""
    }
  SETTINGS
}
