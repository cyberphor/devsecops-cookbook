resource "random_pet" "main" {
  length    = 2
  separator = ""
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = random_pet.main.id
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = random_pet.main.id
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                         = random_pet.main.id
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  security_rule {
    name                       = "SSH"
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

resource "azurerm_public_ip" "main" {
  for_each            = local.virtual_machines
  name                = each.value.name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  for_each                        = local.virtual_machines
  name                            = each.value.name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.main.name
  ip_configuration {
    name                          = each.value.name
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip_address
    public_ip_address_id          = azurerm_public_ip.main[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  for_each                  = local.virtual_machines
  network_interface_id      = azurerm_network_interface.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  for_each                        = local.virtual_machines
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  size                            = var.vm_size
  network_interface_ids           = [ 
    azurerm_network_interface.main[each.key].id
  ]
  disable_password_authentication = false
  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  admin_ssh_key {
    username                      = var.vm_admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching                       = "ReadWrite"
    storage_account_type          = "Standard_LRS"
    name                          = each.value.name
  }
  source_image_reference {
    publisher                     = var.vm_image_publisher
    offer                         = var.vm_image_offer
    sku                           = var.vm_image_sku
    version                       = var.vm_image_version
  }
}