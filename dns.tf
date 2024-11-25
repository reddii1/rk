# Private DNS Zone (Non-Production)

resource "azurerm_private_dns_zone" "dns" {
  name                = "${var.pdu}-${terraform.workspace}${local.dnsenv[terraform.workspace]}az.dwpcloud.uk"
  resource_group_name = azurerm_resource_group.rg_core.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "dns-link-${azurerm_virtual_network.vnet.name}"
  resource_group_name   = azurerm_resource_group.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
  tags                  = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
resource "azurerm_private_dns_zone_virtual_network_link" "core_uks" {
  name                  = "dns-link-${data.azurerm_virtual_network.vnet_dwp_shared_services_core_uks.name}"
  resource_group_name   = azurerm_resource_group.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = data.azurerm_virtual_network.vnet_dwp_shared_services_core_uks.id
  count                 = terraform.workspace != "sbox" ? 1 : 0
  tags                  = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
resource "azurerm_private_dns_zone_virtual_network_link" "vpn_uks" {
  name                  = "dns-link-${data.azurerm_virtual_network.vnet_dwp_shared_services_vpn_uks.name}"
  resource_group_name   = azurerm_resource_group.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = data.azurerm_virtual_network.vnet_dwp_shared_services_vpn_uks.id
  count                 = terraform.workspace != "sbox" ? 1 : 0
  tags                  = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

resource "azurerm_private_dns_zone_virtual_network_link" "core_ukw" {
  name                  = "dns-link-${data.azurerm_virtual_network.vnet_dwp_shared_services_core_ukw.name}"
  resource_group_name   = azurerm_resource_group.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = data.azurerm_virtual_network.vnet_dwp_shared_services_core_ukw.id
  count                 = terraform.workspace != "sbox" ? 1 : 0
  tags                  = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
