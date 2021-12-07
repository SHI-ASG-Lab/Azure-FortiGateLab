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
}


# Variable Declarations

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
  default = "nil"
}
variable "Owner" {
  type = string
  default = "Morpheus"
}

variable "Customer" {
  type = string
  default = "enpro"
}
variable "Vendor" {
  type = string
  default = "cs"
}

variable "win10" {
  type = number
  default = 0
}
variable "win7" {
  type = number
  default = 0
}
variable "Ubuntu" {
  type = number
  default = 0
}
variable "Win19DC" {
  type = number
  default = 0
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
  name     = "SP-SEC-${var.Customer}-${var.Vendor}"
  location = var.region

  tags = local.common_tags
}

resource "azurerm_network_security_group" "NSG1" {
  name                = "EDR-NSG"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = "EDR-vNet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Create subnets within the virtual network
resource "azurerm_subnet" "edrsubnet" {
    name           = "EDRinternal"
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.1.0/24"]
}

# Associate Subnets with NSG
resource "azurerm_subnet_network_security_group_association" "mgmtSubAssocNsg" {
  subnet_id                 = azurerm_subnet.edrsubnet.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}


# Add any number of Ubuntu servers
module "Ubuntu" {
  source = "./modules/Ubuntu"
  count = var.Ubuntu

  UbuntuVmName = "Ubuntu-${count.index}"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.edrsubnet.id

  ipnum = count.index + 20

  user = var.Customer
  pass = "${var.Customer}EDRTest123$"

  tags = local.common_tags

}
# Add in any number of Endpoint Win7 systems from Marketplace as desired
module "Win7" {
  source = "./modules/Win7"
  count = var.win7

  win7vmName = "Win7-${count.index}"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.edrsubnet.id

  user = var.Customer
  pass = "${var.Customer}EDRTest123$"

  tags = local.common_tags

  ipnum = count.index + 40
  
}
# Add in any number of Endpoint Win10 systems from Marketplace as desired
module "Win10" {
  source = "./modules/Win10"
  count = var.win10

  w10vmName = "Win10-${count.index}"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.edrsubnet.id

  user = var.Customer
  pass = "${var.Customer}EDRTest123$"

  tags = local.common_tags

  ipnum = count.index + 10
  
}

# Add in any number of "Windows 2019 Datacenter" Servers
module "win19" {
  source = "./modules/win19"
  count = var.Win19DC

  VmName = "Win19-${count.index}"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.edrsubnet.id

  user = var.Customer
  pass = "${var.Customer}EDRTest123$"

  tags = local.common_tags

  ipnum = count.index + 30
  
}

# Win10 Jumpbox from Marketplace
module "Win10JumpBox" {
  source = "./modules/Win10JumpBox"

  w10vmName  = "Win10-Jumpbox"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.edrsubnet.id

  DNS_Name = "${var.Customer}${var.Vendor}jump"

  user = var.Customer
  pass = "${var.Customer}EDRTest123$"

  tags = local.common_tags

  ipnum = 5
  
}

# Kali Attacker from Marketplace
module "Kali" {
  source = "./modules/Kali"

  kaliVmName = "Kali-Attacker"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.edrsubnet.id

  user = var.Customer
  pass = "${var.Customer}EDRTest123$"

  tags = local.common_tags

  ipnum = 4
  
}
