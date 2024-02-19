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
    name                       = "AllowRDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowWinRM"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_windows_virtual_machine" "main" {
  name                      = random_pet.main.id
  location                  = var.location
  resource_group_name       = var.resource_group_name
  size                      = var.vm_size
  admin_username            = var.local_admin_username
  admin_password            = var.local_admin_password
  network_interface_ids     = [
    azurerm_network_interface.main.id
  ]
  os_disk {
    caching                 = "ReadWrite"
    storage_account_type    = "Standard_LRS"
    name                    = random_pet.main.id
  }
  source_image_reference {
    publisher               = var.vm_image_publisher
    offer                   = var.vm_image_offer
    sku                     = var.vm_image_sku
    version                 = var.vm_image_version
  }
  computer_name             = var.computer_name
  timezone                  = "UTC"
  additional_unattend_content {
    setting      = "AutoLogon"
    content      = <<-EOF
      <AutoLogon>
        <Enabled>true</Enabled>
        <Username>${var.local_admin_username}</Username>
        <Password>
          <Value>${var.local_admin_password}</Value>
        </Password>
        <LogonCount>1</LogonCount>
      </AutoLogon>
    EOF
  }
  additional_unattend_content {
    setting      = "FirstLogonCommands"
    content      = <<-EOF
      <FirstLogonCommands>
        <SynchronousCommand>
          <Order>1</Order>
          <Description>Set PowerShell Execution Policy</Description>
          <RequiresUserInput>false</RequiresUserInput>
          <CommandLine>powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Force"</CommandLine>
        </SynchronousCommand>
        <SynchronousCommand>
          <Order>2</Order>
          <Description>Configure WinRM</Description>
          <RequiresUserInput>false</RequiresUserInput>
          <CommandLine>powershell.exe -EncodedCommand ${textencodebase64(file("${path.module}/Enable-WinRM.ps1"), "UTF-16LE")}</CommandLine>
        </SynchronousCommand>
      </FirstLogonCommands>
    EOF
  }
}
