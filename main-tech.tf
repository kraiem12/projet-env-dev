resource "azurerm_resource_group" "test" {
  name     = "acctestrg12"
  location = "West US 2"
}

resource "azurerm_virtual_network" "test" {
  name                = "acctvn1"
  address_space       = ["12.0.0.0/16"]
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "acctsub1"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "12.0.2.0/24"
}

resource "azurerm_public_ip" "test" {
  name                         = "publicIPForLB1"
  location                     = "${azurerm_resource_group.test.location}"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "test" {
  name                = "port"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  security_rule {
    name                       = "OK-HTTP-entrant1"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OK-HTTP-entrant2"
    priority                   = 1010
    direction                  = "outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OK-HTTP-sortant"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7050"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#esource "azurerm_lb" "test" {
#name                = "loadBalancer"
#location            = "${azurerm_resource_group.test.location}"
#resource_group_name = "${azurerm_resource_group.test.name}"

#frontend_ip_configuration {
#name                 = "publicIPAddress"
#public_ip_address_id = "${azurerm_public_ip.test.id}"
#}
#}

#resource "azurerm_lb_backend_address_pool" "test" {
#resource_group_name = "${azurerm_resource_group.test.name}"
#loadbalancer_id     = "${azurerm_lb.test.id}"
#name                = "BackEndAddressPool"
#}

resource "azurerm_network_interface" "test" {
  count               = 2
  name                = "acctni${count.index}"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"

    #load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.test.id}"]
  }
}

resource "azurerm_managed_disk" "test" {
  count                = 2
  name                 = "datadisk_existing_${count.index}"
  location             = "${azurerm_resource_group.test.location}"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

#resource "azurerm_availability_set" "avset" {
# name                         = "avset"
# location                     = "${azurerm_resource_group.test.location}"
#resource_group_name          = "${azurerm_resource_group.test.name}"
#platform_fault_domain_count  = 2
#platform_update_domain_count = 2
#anaged                      = true
#}

resource "azurerm_virtual_machine" "test" {
  count    = 2
  name     = "tech${count.index}"
  location = "${azurerm_resource_group.test.location}"

  #availability_set_id   = "${azurerm_availability_set.avset.id}"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${element(azurerm_network_interface.test.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmLTbm3lO5+VdKCeXp7xj/NMr11J+b8pRUTNulqXALHKuG0lKfbChjTuhef+0wZvZ6PHQgRI4uX9rkwjFfwnMM7MyGd8za6NuOmf9jSMEtut+eVMSsq+xxRXw8kAlGX4tiYYGQhX4Hyq/hvatFE8YrcGrZbQVneJWJqstOP3bczTEVhviCRYKU0ZHAxmMCvlALzP/o0migLzQpjn0B7QfIDhFX+HBN5UL0E6L76F2VC/Uo64x/YpWsyq8+nqHTKFwlyVrgXhUJEvTT2s/4A6JHPAoOHW+tsEHaYUsERwh4ehyoPgxcAKss/E5yZbqyvydgRt4zHai7ZND55iwuJgIf"
    }
  }
  tags {
    environment = "staging"
  }
}
