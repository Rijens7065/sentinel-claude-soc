# ─── Virtual Network ───────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "main" {
  name                = "VNET-SENTINEL-SOC-PROD-CAE-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = merge(var.common_tags, {
    description = "Primary VNet for the sentinel-claude-soc SOC platform"
  })
}

# ─── Subnets ───────────────────────────────────────────────────────────────────

resource "azurerm_subnet" "functions" {
  name                              = "SNET-FUNC-PROD-CAE-001"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [var.subnet_functions_prefix]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"

  delegation {
    name = "functions-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "SNET-PE-PROD-CAE-001"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [var.subnet_private_endpoints_prefix]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "reserved" {
  name                              = "SNET-RES-PROD-CAE-001"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [var.subnet_reserved_prefix]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"
}

# ─── Network Security Groups ──────────────────────────────────────────────────

resource "azurerm_network_security_group" "functions" {
  name                = "NSG-FUNC-PROD-CAE-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "DenyAllInboundFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = merge(var.common_tags, {
    description = "NSG for Functions subnet — deny internet, allow VNet"
  })
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "NSG-PE-PROD-CAE-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "DenyAllInboundFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = merge(var.common_tags, {
    description = "NSG for Private Endpoints subnet — deny internet, allow VNet"
  })
}

resource "azurerm_network_security_group" "reserved" {
  name                = "NSG-RES-PROD-CAE-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "DenyAllInboundFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = merge(var.common_tags, {
    description = "NSG for Reserved subnet — deny internet, allow VNet"
  })
}

# ─── NSG ↔ Subnet Associations ────────────────────────────────────────────────

resource "azurerm_subnet_network_security_group_association" "functions" {
  subnet_id                 = azurerm_subnet.functions.id
  network_security_group_id = azurerm_network_security_group.functions.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

resource "azurerm_subnet_network_security_group_association" "reserved" {
  subnet_id                 = azurerm_subnet.reserved.id
  network_security_group_id = azurerm_network_security_group.reserved.id
}

# ─── Private DNS Zones ────────────────────────────────────────────────────────

locals {
  private_dns_zones = {
    key_vault  = "privatelink.vaultcore.azure.net"
    blob       = "privatelink.blob.core.windows.net"
    servicebus = "privatelink.servicebus.windows.net"
    cosmos     = "privatelink.documents.azure.com"
    monitor    = "privatelink.monitor.azure.com"
  }
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = var.resource_group_name

  tags = merge(var.common_tags, {
    description = "Private DNS zone for ${each.key} private endpoints"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each              = local.private_dns_zones
  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.common_tags
}
