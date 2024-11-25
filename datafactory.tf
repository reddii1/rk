resource "azurerm_resource_group" "powerbi-integration" {
  name     = "rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-datafactory-mi"
  location = var.location
  tags     = merge(var.tags, local.tags)
}

## Azure Data factory powerBI integration
resource "azurerm_data_factory" "adf" {
  count = length(local.cpenvprefix[terraform.workspace])
  name                = "adf-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  managed_virtual_network_enabled = true
  identity {
    type = "SystemAssigned"
  }
}


# creating self hosted integration runtime for data factory 
 resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  count = length(local.cpenvprefix[terraform.workspace])
  name            = "shir-adf-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}"
  data_factory_id = azurerm_data_factory.adf[count.index].id
}


#####################################
### endpoint private connectivity ##
####################################

# Private Endpoint for Data Factory
resource "azurerm_private_endpoint" "datafactory" {
  count = length(local.cpenvprefix[terraform.workspace])
  name                = "adf-private-endpoint-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  subnet_id           = azurerm_subnet.fe02[0].id //in a subnet accessible to mysqlfs
 
  private_service_connection {
    name                           = "adf-connection"
    private_connection_resource_id = azurerm_data_factory.adf[count.index].id
    subresource_names              = ["dataFactory"]
    is_manual_connection           = false
  }
    private_dns_zone_group {
    name                 = "datafactory-dzg-${terraform.workspace}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.datafactory.id]
  }
}

data "azurerm_private_dns_zone" "datafactory" {
  name                 = "privatelink.datafactory.azure.net" // no prefix can be added to this link.
  resource_group_name  = local.uks_shared_services_dns_resourcegroup[terraform.workspace]
  provider             = azurerm.shared_services_uks
}

// write about why this isn't necassary when using shared services data block. 
# resource "azurerm_private_dns_zone_virtual_network_link" "datafactory" {
#   count = length(local.cpenvprefix[terraform.workspace])

#   name                  = "datafactory-link-${azurerm_virtual_network.vnet.name}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}"
#   resource_group_name  = local.uks_shared_services_dns_resourcegroup[terraform.workspace]
#   private_dns_zone_name = data.azurerm_private_dns_zone.datafactory.name
#   virtual_network_id    = data.azurerm_virtual_network.vnet_dwp_shared_services_vpn_uks.id


# }

resource "azurerm_private_endpoint" "curated" {
  count = length(local.cpenvprefix[terraform.workspace])
  name                = "ep-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}-curated"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  subnet_id           = azurerm_subnet.fe02[0].id

  private_service_connection {
    name                           = "psc-curated-${terraform.workspace}"
    private_connection_resource_id = azurerm_mssql_server.curated_server[count.index].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "privatelink-database-windows-net-${terraform.workspace}"
    private_dns_zone_ids = [azurerm_private_dns_zone.curated.id]
  }
}

resource "azurerm_private_dns_zone" "curated" {
  name                 = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg_network.name
}

#######################################
### Linked services to data factory ###
######################################


// linking the curated/azSQL datebase to data factory so it can be accessed by the az sql linked service
resource "azurerm_data_factory_linked_service_key_vault" "keyvault-link" {
  count = length(local.cpenvprefix[terraform.workspace])
  name            = "adf-curated-password-link"
  integration_runtime_name = azurerm_data_factory_integration_runtime_self_hosted.shir[count.index].name
  data_factory_id = azurerm_data_factory.adf[count.index].id
  key_vault_id    = azurerm_key_vault.app.id
}

// link for sink database (curated) to PaaS az sql
resource "azurerm_data_factory_linked_service_azure_sql_database" "curated-link" {
  count = length(local.cpenvprefix[terraform.workspace])
  name              = "curated-db-1"
  integration_runtime_name = azurerm_data_factory_integration_runtime_self_hosted.shir[count.index].name
  data_factory_id   = azurerm_data_factory.adf[count.index].id
  connection_string = "data source=${azurerm_mssql_server.curated_server[count.index].fully_qualified_domain_name};initial catalog=${azurerm_mssql_database.curateddb[count.index].name};user id=${azurerm_mssql_server.curated_server[count.index].administrator_login};integrated security=False;encrypt=True;connection timeout=30;"
  use_managed_identity     = true

  key_vault_password {
    linked_service_name  = azurerm_data_factory_linked_service_key_vault.keyvault-link[count.index].name
    secret_name = azurerm_key_vault_secret.adf-sql_admin_password[count.index].name
  }

  depends_on = [ azurerm_data_factory_linked_service_key_vault.keyvault-link, azurerm_data_factory_integration_runtime_self_hosted.shir]
} 

# connecting replica mysql database to data factory for etl to azure sql
# source db

resource "azurerm_data_factory_linked_custom_service" "replica" {
  count = length(local.cpenvprefix[terraform.workspace])
  name                 = "replica"
  data_factory_id      = azurerm_data_factory.adf[count.index].id
  integration_runtime {
    name = azurerm_data_factory_integration_runtime_self_hosted.shir[count.index].name
  } 
  
  type                 = "AzureMySql"
  type_properties_json = <<JSON
    {
      "connectionString": "server=${azurerm_mysql_flexible_server.replica[count.index].fqdn};port=3306;database=mysql;uid=${azurerm_mysql_flexible_server.replica[count.index].administrator_login};sslmode=1;usesystemtruststore=0",
      "password": {
                "secretName": "${azurerm_key_vault_secret.mysql_admin_password[count.index].name}",
                "store": {
                    "referenceName": "${azurerm_data_factory_linked_service_key_vault.keyvault-link[count.index].name}",
                    "type": "LinkedServiceReference"
                },
                "type": "AzureKeyVaultSecret"
            }    
    }
    JSON
}  
