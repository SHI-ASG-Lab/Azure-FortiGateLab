# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.88.0"
    }
  }
}

provider "azurerm" {
  features {}
/*  subscription_id = var.TF_VAR_ARM_SUBSCRIPTION_ID
  client_id       = var.TF_VAR_ARM_CLIENT_ID
  client_secret   = var.TF_VAR_ARM_CLIENT_SECRET
  tenant_id       = var.TF_VAR_ARM_TENANT_ID */
}

# Variable Declarations
/*
variable "TF_VAR_ARM_CLIENT_ID" {
  type = string
  sensitive = true
}

variable "TF_VAR_ARM_CLIENT_SECRET" {
  type = string
  sensitive = true
}

variable "TF_VAR_ARM_SUBSCRIPTION_ID" {
  type = string
  sensitive = true
}

variable "TF_VAR_ARM_TENANT_ID" {
  type = string
  sensitive = true
}
*/
variable "region" {
  type = string
}

variable "RG_Env_Tag" {
    type = string
}

variable "RG_SP_Name" {
  type = string
}

variable "Requestor" {
  type = string
  default = "LAB"
}

variable "Owner" {
  type = string
  default = "JWilliams"
}

variable "Customer" {
  type = string
  default = "lab"
}

variable "pword" {
  type = string
  default = "SHIisNumber1!"
}
/*
variable "ubuntu_int" {
  type = number
  default = 1
}

variable "ubuntu_ext" {
  type = number
  default = 1
}

variable "Win19DC_int" {
  type = number
  default = 1
}

variable "Win19DC_ext" {
  type = number
  default = 1
}
*/
variable "mgmt_Subnet1_name" {
  type = string
  default = "mgmtSubnet"
}

variable "int_Subnet2_name" {
  type = string
  default = "internalSubnet"
}

variable "ext_Subnet3_name" {
  type = string
  default = "externalSubnet"
}

locals {
  common_tags = {
    Owner       = var.Owner
    Requestor   = var.Requestor
    Environment = var.RG_Env_Tag
    SP          = var.RG_SP_Name
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${var.Customer}-FortiLab-RG"
  location = var.region

  tags = local.common_tags
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.Customer}-FortiLab-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = "${var.Customer}-FortiLab-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Create subnets within the virtual network
resource "azurerm_subnet" "mgmtsubnet" {
    name           = var.mgmt_Subnet1_name
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "intsubnet" {
    name           = var.int_Subnet2_name
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "extsubnet" {
    name           = var.ext_Subnet3_name
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.3.0/24"]
}

# Associate Subnets with NSG
resource "azurerm_subnet_network_security_group_association" "mgmtSubAssocNsg" {
  subnet_id                 = azurerm_subnet.mgmtsubnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_subnet_network_security_group_association" "intSubAssocNsg" {
  subnet_id                 = azurerm_subnet.intsubnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_subnet_network_security_group_association" "extSubAssocNsg" {
  subnet_id                 = azurerm_subnet.extsubnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Create Route Tables and specify routes
resource "azurerm_route_table" "mgmtRtable" {
  #count = signum(local.Fortinet)
  name                          = "mgmtRouteTable"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true

  route {
    name           = "mgmt2internal"
    address_prefix = "10.0.2.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
  route {
    name           = "mgmt2ext"
    address_prefix = "10.0.3.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.3.4"
  }
}

resource "azurerm_route_table" "intRtable" {
  #count = signum(local.Fortinet)
  name                          = "intRouteTable"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true

  route {
    name           = "int2mgmt"
    address_prefix = "10.0.1.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }
  route {
    name           = "int2ext"
    address_prefix = "10.0.3.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.3.4"
  }
}

resource "azurerm_route_table" "extRtable" {
  #count = signum(local.Fortinet + local.Sophos + local.Cisco + local.Juniper + local.PaloAlto + local.Watchguard)
  name                          = "extRouteTable"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true

  route {
    name           = "ext2internal"
    address_prefix = "10.0.2.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
  route {
    name           = "ext2mgmt"
    address_prefix = "10.0.1.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }
}
/*
# Associate Route Tables with Subnets
resource "azurerm_subnet_route_table_association" "mgmtassoc" {
  subnet_id      = azurerm_subnet.mgmtsubnet.id
  route_table_id = azurerm_route_table.mgmtRtable.id
}
resource "azurerm_subnet_route_table_association" "intassoc" {
  subnet_id      = azurerm_subnet.intsubnet.id
  route_table_id = azurerm_route_table.intRtable.id
}
resource "azurerm_subnet_route_table_association" "extassoc" {
  subnet_id      = azurerm_subnet.extsubnet.id
  route_table_id = azurerm_route_table.extRtable.id
}
*/
module "Fortinet" {
    source = "./modules/Fortinet"
    #count = local.Fortinet ? 1 : 0 

    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location
 
    customer_id        = var.Customer
    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}
/*
# Add any number of Ubuntu servers
module "UbuntuINT" {
  source = "./modules/UbuntuINT"
  count = var.ubuntu_int

  UbuntuName = "${var.Customer}-UbEXT-${count.index}-FortiLab"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id = azurerm_subnet.intsubnet.id

  ipnum = count.index + 20

  user = var.Customer
  pass = "${var.Customer}-${var.pword}"

  tags = local.common_tags

}

# Add any number of Ubuntu servers
module "UbuntuEXT" {
  source = "./modules/UbuntuEXT"
  count = var.ubuntu_ext

  UbuntuName = "${var.Customer}-UbINT-${count.index}-FortiLab"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id = azurerm_subnet.extsubnet.id

  ipnum = count.index + 20

  user = var.Customer
  pass = "${var.Customer}-${var.pword}"

  tags = local.common_tags

}

# Add in any number of "Windows 2019 Datacenter" Servers
module "win19int" {
  source = "./modules/win19int"
  count = var.Win19DC_int

  VmName = "${var.Customer}-Win19INT-${count.index}-FortiLab"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.intsubnet.id

  user = var.Customer
  pass = "${var.Customer}-${var.pword}"

  tags = local.common_tags

  ipnum = count.index + 30
  
}

# Add in any number of "Windows 2019 Datacenter" Servers
module "win19ext" {
  source = "./modules/win19ext"
  count = var.Win19DC_ext

  VmName = "${var.Customer}-Win19EXT-${count.index}-FortiLab"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.extsubnet.id

  user = var.Customer
  pass = "${var.Customer}-${var.pword}"

  tags = local.common_tags

  ipnum = count.index + 30
  
}
*/
