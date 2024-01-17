
resource "azurerm_public_ip" "prod_server_1" {
  name                = "${var.prod_server_1}-publicip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "prod_server_1" {
  name                = "${var.prod_server_1}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "${var.prod_server_1}-ipconfig"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.prod_server_1.id
  }
}

resource "azurerm_network_interface_security_group_association" "prod_server_1" {
  network_security_group_id = azurerm_network_security_group.main.id
  network_interface_id      = azurerm_network_interface.prod_server_1.id
}

resource "azurerm_linux_virtual_machine" "prod_server_1" {
  name                            = var.prod_server_1
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.server_size
  admin_username                  = var.admin_username
  admin_ssh_key {
    username                      = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching                       = var.os_disk_caching              
    storage_account_type          = var.os_disk_storage_account_type
  }
  source_image_reference {
    publisher                     = var.source_image_publisher
    offer                         = var.source_image_offer
    sku                           = var.source_image_sku
    version                       = var.source_image_version
  }
  network_interface_ids = [
    azurerm_network_interface.prod_server_1.id,
  ]
}