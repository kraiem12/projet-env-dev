# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup1" {
  name     = "myResourceGroup1"
  location = "eastus"

  tags {
    environment = "Terraform Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork1" {
  name                = "myVnet1"
  address_space       = ["11.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

  tags {
    environment = "Terraform Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet1" {
  name                 = "mySubnet1"
  resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
  virtual_network_name = "${azurerm_virtual_network.myterraformnetwork1.name}"
  address_prefix       = "11.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip1" {
  name                = "myPublicIP1"
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
  allocation_method   = "Dynamic"

  tags {
    environment = "Terraform Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg1" {
  name                = "portadata"
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

  security_rule {
    name                       = "datap"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "datas"
    priority                   = 1030
    direction                  = "outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1251"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Terraform Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic1" {
  name                      = "myNIC1"
  location                  = "eastus"
  resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

  ip_configuration {
    name                          = "myNicConfiguration1"
    subnet_id                     = "${azurerm_subnet.myterraformsubnet1.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip1.id}"
  }

  tags {
    environment = "Terraform Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId1" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.myterraformgroup1.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount1" {
  name                     = "diag${random_id.randomId1.hex}"
  resource_group_name      = "${azurerm_resource_group.myterraformgroup1.name}"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Terraform Demo"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm1" {
  name                  = "dataBDD"
  location              = "eastus"
  resource_group_name   = "${azurerm_resource_group.myterraformgroup1.name}"
  network_interface_ids = ["${azurerm_network_interface.myterraformnic1.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "myOsDisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"

    version = "latest"
  }

  os_profile {
    computer_name  = "myvm1"
    admin_username = "azureuser1"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser1/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmLTbm3lO5+VdKCeXp7xj/NMr11J+b8pRUTNulqXALHKuG0lKfbChjTuhef+0wZvZ6PHQgRI4uX9rkwjFfwnMM7MyGd8za6NuOmf9jSMEtut+eVMSsq+xxRXw8kAlGX4tiYYGQhX4Hyq/hvatFE8YrcGrZbQVneJWJqstOP3bczTEVhviCRYKU0ZHAxmMCvlALzP/o0migLzQpjn0B7QfIDhFX+HBN5UL0E6L76F2VC/Uo64x/YpWsyq8+nqHTKFwlyVrgXhUJEvTT2s/4A6JHPAoOHW+tsEHaYUsERwh4ehyoPgxcAKss/E5yZbqyvydgRt4zHai7ZND55iwuJgIf"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorageaccount1.primary_blob_endpoint}"
  }

  tags {
    environment = "Terraform Demo"
  }
}
