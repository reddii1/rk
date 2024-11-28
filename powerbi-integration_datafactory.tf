resource "azurerm_resource_group" "powerbi-integration" {
  name     = "rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-datafactory-mi"
  location = var.location
  tags     = merge(var.tags, local.tags)
}

## Azure Data factory powerBI integration
resource "azurerm_data_factory" "adf" {
  count = length(local.cpenvprefix[terraform.workspace])
  name                = "${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}-mi"
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
  name            = "shir-${local.cpenvprefix[terraform.workspace][count.index]}mi"
  data_factory_id = azurerm_data_factory.adf[count.index].id
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
  name              = "curated"
  integration_runtime_name = azurerm_data_factory_integration_runtime_self_hosted.shir[count.index].name
  data_factory_id   = azurerm_data_factory.adf[count.index].id
  connection_string = "data source=${azurerm_mssql_server.curated[count.index].fully_qualified_domain_name};initial catalog=${azurerm_mssql_database.curated[count.index].name};user id=${azurerm_mssql_server.curated[count.index].administrator_login};integrated security=False;encrypt=True;connection timeout=30;"
  use_managed_identity     = true

  key_vault_password {
    linked_service_name  = azurerm_data_factory_linked_service_key_vault.keyvault-link[count.index].name
    secret_name = azurerm_key_vault_secret.adf-sql_admin_password[count.index].name
  }

  depends_on = [ azurerm_data_factory_linked_service_key_vault.keyvault-link, azurerm_data_factory_integration_runtime_self_hosted.shir]
} 

# connecting replica mysql database to data factory for etl to azure sql
# source db


// this custom service is presumably required as there is a linked service MySQL 
// link but not a *MySQL for Azure* link, which are different as one is on site and one is PaaS
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
