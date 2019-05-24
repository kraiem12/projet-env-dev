# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "myResourceGroup"
  location = "eastus"

  tags {
    environment = "Terraform Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

  tags {
    environment = "Terraform Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "mySubnet"
  resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
  virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myPublicIP"
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
  allocation_method   = "Dynamic"

  tags {
    environment = "Terraform Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "portapps"
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

  security_rule {
    name                       = "portapp"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1251"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "portapp1"
    priority                   = 1002
    direction                  = "outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7050"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Terraform Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  name                      = "myNIC"
  location                  = "eastus"
  resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
  network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
  }

  tags {
    environment = "Terraform Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.myterraformgroup.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.myterraformgroup.name}"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Terraform Demo"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
  name                  = "apps"
  location              = "eastus"
  resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
  network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "myOsDisk"
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
    computer_name  = "myvm"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmLTbm3lO5+VdKCeXp7xj/NMr11J+b8pRUTNulqXALHKuG0lKfbChjTuhef+0wZvZ6PHQgRI4uX9rkwjFfwnMM7MyGd8za6NuOmf9jSMEtut+eVMSsq+xxRXw8kAlGX4tiYYGQhX4Hyq/hvatFE8YrcGrZbQVneJWJqstOP3bczTEVhviCRYKU0ZHAxmMCvlALzP/o0migLzQpjn0B7QfIDhFX+HBN5UL0E6L76F2VC/Uo64x/YpWsyq8+nqHTKFwlyVrgXhUJEvTT2s/4A6JHPAoOHW+tsEHaYUsERwh4ehyoPgxcAKss/E5yZbqyvydgRt4zHai7ZND55iwuJgIf"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
  }

  tags {
    environment = "Terraform Demo"
  }
}
