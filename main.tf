#main file for my web app
resource "azurerm_resource_group" "rg" {
    name = "web_app_rg"
    location= "eastus"
}

resource "azurerm_virtual_network" "vnet" {
    name = "vnet"
    location = "eastus"
    address_space = ["10.0.0.0/16"]
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    name = "subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix = "10.0.1.0/24"
}

resource "azurerm_public_ip" "public_ip" {
    name = "public_ip"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Dynamic"
    sku = "Basic"
}

/*
resource "azurerm_network_security_group" "nsg" {
    name = "nsg"
    resource_group_name = azurerm_resource_group.rg.name
    location = "eastus"
    security_rule{
        name = "SSH"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
  
}
*/

resource "azurerm_network_security_group" "nsg" {
    name = "nsg"
    resource_group_name = azurerm_resource_group.rg.name
    location = "eastus"
}

resource "azurerm_network_security_rule" "nsg" {
  for_each                    = local.nsgrules 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
    network_interface_id = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "nic" {
    name = "nic"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
      name = "ipconfig"
      subnet_id = azurerm_subnet.subnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.public_ip.id
        }
  
}

resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
    name = "linux_vm"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    size = "Standard_B1ls"

    os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

    source_image_reference {
      publisher = "Canonical"
      offer = "0001-com-ubuntu-server-jammy"
      sku = "22_04-lts-gen2"
      version = "latest"
    }

    computer_name = "webAppVM"
    admin_username = "tapan"
    disable_password_authentication = true

    admin_ssh_key {
    username   = "tapan"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }
    user_data = "${file("encodedscript.sh")}"

                                
}
/*
provisioner "file" {
  connection {
    type     = "ssh"
    user     = "tapan"
    password = "@Password123"
    host     = self.public_ip_address
  }

    source      = "/myWebApp/script.sh"
    destination = "/home/tapan/script.sh"
  }

  provisioner "remote-exec" {
  connection {
    type     = "ssh"
    user     = "tapan"
    password = "@Password123"
    host     = self.public_ip_address
  }
    inline = [
      "sudo chmod +x /home/tapan/script.sh",
      "/tmp/script.sh args",
    ]
  }
  */

#some change to test
#final test