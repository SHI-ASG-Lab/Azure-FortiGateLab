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

variable "ExistingImageName" {
    type = string
}
variable "VmName" {
    type = string
}
variable "NumUbuntu" {
    type = number
    default = 1
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

# Create NSG rules

resource "azurerm_network_security_rule" "ngsrule" {
  name                        = "ANY"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
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
  depends_on               = [azurerm_subnet.mgmtsubnet]
}

resource "azurerm_subnet_network_security_group_association" "intSubAssocNsg" {
  subnet_id                 = azurerm_subnet.intsubnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  depends_on               = [azurerm_subnet.intsubnet]
}

resource "azurerm_subnet_network_security_group_association" "extSubAssocNsg" {
  subnet_id                 = azurerm_subnet.extsubnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  depends_on               = [azurerm_subnet.extsubnet]
}

# Create Route Tables and specify routes
resource "azurerm_route_table" "mgmtRtable" {
  #count = signum(local.Fortinet)
  name                          = "mgmtRouteTable"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true
  depends_on                    = [azurerm_subnet_network_security_group_association.mgmtSubAssocNsg]

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
  depends_on                    = [azurerm_subnet_network_security_group_association.intSubAssocNsg]

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
  depends_on                    = [azurerm_subnet_network_security_group_association.extSubAssocNsg]

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

module "Fortinet" {
    source = "./modules/Fortinet"
    #count = local.Fortinet ? 1 : 0 
    depends_on = [azurerm_subnet_route_table_association.mgmtassoc]

    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location
 
    customer_id        = var.Customer
    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}

# Add any number of Ubuntu servers
module "UbuntuINT" {
  source = "./modules/UbuntuINT"
  count = var.ubuntu_int
  depends_on = [azurerm_subnet_route_table_association.intassoc]

  UbuntuName = "${var.Customer}-UbINT-${count.index}"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location
  pimage = var.ExistingImageName

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
  depends_on = [azurerm_subnet_route_table_association.extassoc]

  UbuntuName = "${var.Customer}-UbEXT-${count.index}"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location
  pimage = var.ExistingImageName

  subnet_id = azurerm_subnet.extsubnet.id

  ipnum = count.index + 20

  user = var.Customer
  pass = "${var.Customer}-${var.pword}"

  tags = local.common_tags

}

    
# Reference Existing Image
/*
data "azurerm_image" "custom" {
  resource_group_name = "LAB-PackerImages"
  name                = var.ExistingImageName
}

# Create a public IP for the system to use

resource "azurerm_public_ip" "azPubIp" {
  name = "${var.VmName}-PubIp1"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  allocation_method = "Static"
}

# Create NIC for the VM

resource "azurerm_network_interface" "main" {
  name                = "${var.VmName}-nic1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  depends_on = [azurerm_subnet_route_table_association.intassoc]

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.intsubnet.id
    private_ip_address_allocation = "Dynamic"
    # private_ip_address            = "10.28.0.10"
    public_ip_address_id          = azurerm_public_ip.azPubIp.id
    primary                       = true
  }
}

# Create Virtual Machine

resource "azurerm_virtual_machine" "main" {
  name                         = var.VmName
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  network_interface_ids        = [azurerm_network_interface.main.id]
  primary_network_interface_id = azurerm_network_interface.main.id
  vm_size                     = "Standard_E2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.custom.id}"
  }
  storage_os_disk {
    name              = "${var.VmName}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.VmName
    admin_username = "testuser"
    admin_password = "SHIisNumber1!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  
  tags     = local.common_tags
}*/
  
# Add in any number of "Windows 2019 Datacenter" Servers
module "win19int" {
  source = "./modules/win19int"
  count = var.Win19DC_int
  depends_on = [azurerm_subnet_route_table_association.intassoc]

  VmName = "${var.Customer}-Win19INT-${count.index}"
  
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
  depends_on = [azurerm_subnet_route_table_association.extassoc]

  VmName = "${var.Customer}-Win19EXT-${count.index}"
  
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  subnet_id                 = azurerm_subnet.extsubnet.id

  user = var.Customer
  pass = "${var.Customer}-${var.pword}"

  tags = local.common_tags

  ipnum = count.index + 30
  
}
