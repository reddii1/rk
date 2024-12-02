### Key Vault

## Azure Key Vaults
# Azure Key Vault Core
resource "azurerm_key_vault" "keyvault_dwp_core" {
  name                            = "kv-${local.location_prefix}-${terraform.workspace}-${var.pdu}-core"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg_core.name
  sku_name                        = "premium"
  tenant_id                       = var.tenant_id
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = false
  tags                            = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
# Azure Key Vault Encrypt
resource "azurerm_key_vault" "keyvault_dwp_encrypt" {
  name                            = "kv-${local.location_prefix}-${terraform.workspace}-${var.pdu}-encpt"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg_core.name
  sku_name                        = "premium"
  tenant_id                       = var.tenant_id
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = false
  tags                            = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })

}
## Azure Monitor Diagnostic Settings
# Azure Monitor Diagnostic Setting - Key Vault DWP Core
resource "azurerm_monitor_diagnostic_setting" "keyvault_dwp_core" {
  name                       = "key-vault-diagnostics"
  target_resource_id         = azurerm_key_vault.keyvault_dwp_core.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.oms.id
  log {
    category = "AuditEvent"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "AzurePolicyEvaluationDetails"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = true
    }
  }
}
# Azure Monitor Diagnostic Setting - Key Vault DWP Encrypt
resource "azurerm_monitor_diagnostic_setting" "keyvault_dwp_encrypt" {
  name                       = "key-vault-diagnostics"
  target_resource_id         = azurerm_key_vault.keyvault_dwp_encrypt.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.oms.id
  log {
    category = "AuditEvent"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "AzurePolicyEvaluationDetails"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = true
    }
  }
}
## VM Key Vault Secrets
# VM Default Username Secret
resource "azurerm_key_vault_secret" "keyvault_secret_dwp_vm_username" {
  name         = "default-username"
  value        = "azureuser"
  content_type = "default vm username (1 per VM recommended)"
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  tags         = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  depends_on = [azurerm_role_assignment.dwp_pdu_key_vault_secrets_officer,
  azuread_group_member.dwp_pdu_key_vault_secrets_officer, ]
}

# VM Default Password Secret
resource "random_password" "vm_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-=+[]{}<>:"
}

resource "azurerm_key_vault_secret" "keyvault_secret_dwp_vm_password" {
  name         = "default-password"
  value        = random_password.vm_password.result
  content_type = "default vm password (1 per VM recommended)"
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  tags         = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  depends_on = [azurerm_role_assignment.dwp_pdu_key_vault_secrets_officer,
  azuread_group_member.dwp_pdu_key_vault_secrets_officer, ]
}

# Windows VM Encryption Key
resource "azurerm_key_vault_key" "keyvault_key_dwp_vm_encryption" {
  name = "windowsEncryption"
  depends_on = [azurerm_role_assignment.dwp_pdu_key_vault_crypto_officer,
  azuread_group_member.dwp_pdu_key_vault_crypto_officer, ]
  key_vault_id = azurerm_key_vault.keyvault_dwp_encrypt.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  tags = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# App Connector SSH Key Pair

resource "azurerm_key_vault_secret" "app-connector-private-key" {
  name       = "app-connector-private-key"
  value      = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  depends_on = [azurerm_key_vault.keyvault_dwp_core]

  tags         = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  count      = terraform.workspace == "prod" ? 1 : 0
}

resource "azurerm_key_vault_secret" "app-connector-public-key" {
  name       = "app-connector-public-key"
  value      = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  depends_on = [azurerm_key_vault.keyvault_dwp_core]

  tags         = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  count      = terraform.workspace == "prod" ? 1 : 0
}
