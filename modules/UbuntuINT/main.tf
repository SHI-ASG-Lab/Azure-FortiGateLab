# Reference Existing Image

data "azurerm_image" "custom" {
  resource_group_name = "LAB-PackerImages"
  name                = var.ExistingImageName
}

# Create a public IP for the system to use

resource "azurerm_public_ip" "azPubIp" {
  name = "${var.UbuntuName}-PubIp1"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  allocation_method = "Static"
}

# Create NIC for the VM

resource "azurerm_network_interface" "main" {
  name                = "${var.UbuntuName}-nic"
  location            = var.RGlocation
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.UbuntuName}-IP"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "static"
    private_ip_address = "10.0.2.${var.ipnum}"
    primary = true
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = var.UbuntuName
  location              = var.RGlocation
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  primary_network_interface_id = azurerm_network_interface.main.id
  vm_size               = "Standard_D2s_v3"
 

  # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
 /*   publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "20.04.202112020"*/
    id = "${data.azurerm_image.custom.id}"
  }
  storage_os_disk {
    name              = "${var.UbuntuName}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.UbuntuName
    admin_username = var.user
    admin_password = var.pass
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
/*
  plan {
    name      = "20_04-lts"
    publisher = "canonical"
    product   = "0001-com-ubuntu-server-focal"
  }
  */
  tags     = var.tags
}

# Configure Auto-Shutdown for the AD Server for each night at 10pm CST.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "UbuntuShutdown" {
  virtual_machine_id = azurerm_virtual_machine.main.id
  location           = var.RGlocation
  enabled            = true
  daily_recurrence_time = "2100"
  timezone              = "Central Standard Time"

  notification_settings {
    enabled         = false
  }
}
