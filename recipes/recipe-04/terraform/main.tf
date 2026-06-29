resource "random_pet" "main" {
  length    = 2
  separator = ""
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                = random_pet.main.id
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                 = random_pet.main.id
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                = random_pet.main.id
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  name                            = random_pet.main.id
  location                        = var.location
  resource_group_name             = var.resource_group_name
  ip_configuration {
    name                          = random_pet.main.id
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.5"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_security_group" "main" {
  name                = random_pet.main.id
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = random_pet.main.id
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  network_interface_ids           = [
    azurerm_network_interface.main.id
  ]
  admin_username                  = var.local_admin_username
  admin_ssh_key {
    username                      = var.local_admin_username
    public_key                    = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching                       = "ReadWrite"
    storage_account_type          = "Standard_LRS"
    name                          = random_pet.main.id
  }
  source_image_reference {
    publisher                     = var.vm_image_publisher
    offer                         = var.vm_image_offer
    sku                           = var.vm_image_sku
    version                       = var.vm_image_version
  }
}

