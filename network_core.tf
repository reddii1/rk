# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.location_prefix}-${terraform.workspace}-${var.pdu}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  address_space       = var.vnet_address_spaces[terraform.workspace]
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })

}

# Subnets

## PDU Blueprint Standard
resource "azurerm_subnet" "fe01" {
  name                                           = "front-end-01"
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  resource_group_name                            = azurerm_resource_group.rg_network.name
  address_prefixes                               = var.fe01_subnet_cidr[terraform.workspace]
  service_endpoints                              = ["Microsoft.ContainerRegistry", "Microsoft.AzureActiveDirectory", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.Sql"]
  enforce_private_link_service_network_policies  = var.deploy_modern_data_warehouse == true ? true : false
  enforce_private_link_endpoint_network_policies = var.deploy_modern_data_warehouse == true ? true : false
}
# If Modern Data Warehouse is selected to deploy (var.deploy_modern_data_warehouse set to true), then FE02 and BE02 are delegated to data bricks
resource "azurerm_subnet" "fe02" {
  name                 = "front-end-02"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_network.name
  address_prefixes     = var.fe02_subnet_cidr[terraform.workspace]
  count                = var.deploy_modern_data_warehouse == false ? 1 : 0

  service_endpoints                              = ["Microsoft.ContainerRegistry", "Microsoft.AzureActiveDirectory", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.CognitiveServices"]
  enforce_private_link_service_network_policies  = var.deploy_modern_data_warehouse == true ? true : false
  enforce_private_link_endpoint_network_policies = var.deploy_modern_data_warehouse == true ? true : false
  depends_on                                     = [azurerm_subnet.fe01]
}
resource "azurerm_subnet" "fe02_mdw" {
  name                 = "front-end-02"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_network.name
  address_prefixes     = var.fe02_subnet_cidr[terraform.workspace]
  count                = var.deploy_modern_data_warehouse == true ? 1 : 0

  delegation {
    name = "databricks"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }

  service_endpoints                              = ["Microsoft.ContainerRegistry", "Microsoft.AzureActiveDirectory", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.Sql"]
  enforce_private_link_service_network_policies  = var.deploy_modern_data_warehouse == true ? true : false
  enforce_private_link_endpoint_network_policies = var.deploy_modern_data_warehouse == true ? true : false
  depends_on                                     = [azurerm_subnet.fe01]
}

# If either var.deploy_modern_data_warehouse or var.deploy_fe03_subnet are set to true, then a FE03 subnet is deployed for the App Service Environment (in case of var.deploy_modern_data_warehouse), or vanilla (in the case of var.deploy_fe03_subnet)
# ...MDW adds additional config
resource "azurerm_subnet" "fe03" {
  name                                           = "front-end-03"
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  resource_group_name                            = azurerm_resource_group.rg_network.name
  address_prefixes                               = var.fe03_subnet_cidr[terraform.workspace]
  service_endpoints                              = ["Microsoft.ContainerRegistry", "Microsoft.AzureActiveDirectory", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.Sql"]
  enforce_private_link_service_network_policies  = var.deploy_modern_data_warehouse == true ? true : false
  enforce_private_link_endpoint_network_policies = var.deploy_modern_data_warehouse == true ? true : false
  depends_on                                     = [azurerm_subnet.fe02]
  count                                          = var.deploy_modern_data_warehouse == true || var.deploy_fe03_subnet == true ? 1 : 0
}

resource "azurerm_subnet" "be01" {
  name                                           = "back-end-01"
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  resource_group_name                            = azurerm_resource_group.rg_network.name
  address_prefixes                               = var.be01_subnet_cidr[terraform.workspace]
  service_endpoints                              = ["Microsoft.ContainerRegistry", "Microsoft.AzureActiveDirectory", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.Sql"]
  enforce_private_link_service_network_policies  = var.deploy_modern_data_warehouse == true ? true : false
  enforce_private_link_endpoint_network_policies = var.deploy_modern_data_warehouse == true ? true : false
  depends_on                                     = [azurerm_subnet.fe03]
}

# If Modern Data Warehouse is selected to deploy (var.deploy_modern_data_warehouse set to true)), then FE02 and BE02 is delegated to data bricks
resource "azurerm_subnet" "be02" {
  name                                           = "back-end-02"
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  resource_group_name                            = azurerm_resource_group.rg_network.name
  address_prefixes                               = var.be02_subnet_cidr[terraform.workspace]
  count                                          = var.deploy_modern_data_warehouse == false ? 1 : 0
  service_endpoints                              = ["Microsoft.ContainerRegistry", "Microsoft.AzureActiveDirectory", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.Sql"]
  enforce_private_link_service_network_policies  = var.deploy_modern_data_warehouse == true ? true : false
  enforce_private_link_endpoint_network_policies = var.deploy_modern_data_warehouse == true ? true : false
  depends_on                                     = [azurerm_subnet.be01]
}
resource "azurerm_subnet" "be02_mdw" {
  name                 = "back-end-02"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_network.name
  address_prefixes     = var.be02_subnet_cidr[terraform.workspace]
  count                = var.deploy_modern_data_warehouse == true ? 1 : 0
  delegation {
    name = "databricks"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
  service_endpoints                              = ["Microsoft.ContainerRegistry", "Microsoft.AzureActiveDirectory", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.Sql"]
  enforce_private_link_service_network_policies  = var.deploy_modern_data_warehouse == true ? true : false
  enforce_private_link_endpoint_network_policies = var.deploy_modern_data_warehouse == true ? true : false
  depends_on                                     = [azurerm_subnet.be01]
}

### Additional subnets - deployment of these subnets depends on selector switches in the tfvars file ###
# Azure SQL Managed Instance
resource "azurerm_subnet" "sqlmi01" {
  name                 = "sql-mi-01"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_network.name
  address_prefixes     = var.sqlmi01_subnet_cidr[terraform.workspace]
  delegation {
    name = "sql-mi-01"

    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
  count = var.deploy_sqlmi_subnet == true ? 1 : 0
}

# Redis Cache Subnet
resource "azurerm_subnet" "redis01" {
  name                 = "redis-01"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_network.name
  address_prefixes     = var.redis01_subnet_cidr[terraform.workspace]

  count = var.deploy_redis_subnet == true ? 1 : 0
}

# Azure Bastion Host
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_network.name
  address_prefixes     = var.bastion_subnet_cidr[terraform.workspace]


  count = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
resource "azurerm_public_ip" "bastion" {
  name                = "pip-${local.location_prefix}-${terraform.workspace}-${var.pdu}-bastion"
  location            = azurerm_resource_group.rg_network.location
  resource_group_name = azurerm_resource_group.rg_network.name
  allocation_method   = "Static"
  sku                 = "Standard"

  count = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
  tags  = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-${local.location_prefix}-${terraform.workspace}-${var.pdu}"
  location            = azurerm_resource_group.rg_network.location
  resource_group_name = azurerm_resource_group.rg_network.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[count.index].id
    public_ip_address_id = azurerm_public_ip.bastion[count.index].id
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name bastion-diagnostics --resource ${azurerm_bastion_host.bastion[count.index].id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "BastionAuditLogs", "enabled": true } ]'
    EOF
  }
  count = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0

}
# Network Watcher
resource "azurerm_network_watcher" "network_watcher" {
  name                = "NetworkWatcher_${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
