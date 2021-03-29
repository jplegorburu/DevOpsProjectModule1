provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = {
    task = "udacityModuleProject"
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = {
    task = "udacityModuleProject"
  }
}

resource "azurerm_network_security_rule" "first" {
  name                        = "HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "second" {
  name                        = "DenyInternetAccess"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "third" {
  name                        = "AllowVNet"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}


resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pIp"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku = "Standard"
  tags = {
    task = "udacityModuleProject"
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku = "Standard"
  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  tags = {
    task = "udacityModuleProject"
  }
}

resource  "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.prefix}-bap"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "http-running-probe"
  protocol                = "TCP"
  port                = 80
}

resource "azurerm_lb_rule" "main" {
  resource_group_name            = data.azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "LBRule"
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  probe_id = azurerm_lb_probe.main.id
  frontend_ip_configuration_name = "primary"
}

resource "azurerm_network_interface" "main" {
  count = var.numberOfVms
  name                = "${var.prefix}-${count.index}-nic"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    task = "udacityModuleProject"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                = var.numberOfVms
  network_interface_id    = azurerm_network_interface.main.*.id[count.index]
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_network_interface_security_group_association" "main" {
  count = var.numberOfVms
  network_interface_id      = azurerm_network_interface.main.*.id[count.index]
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-aset"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = {
    task = "udacityModuleProject"
  }
}

data "azurerm_image" "packerImage" {
  name                = "module01ProjectImage"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
  count                 = var.numberOfVms
  name                            = "${var.prefix}-${count.index}-vm"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  availability_set_id   = azurerm_availability_set.main.id
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  source_image_id = data.azurerm_image.packerImage.id

  network_interface_ids = [
    azurerm_network_interface.main.*.id[count.index]
  ]
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  tags = {
    task = "udacityModuleProject"
  }
}


resource "azurerm_managed_disk" "main" {
  count                = var.numberOfVms
  name                 = "${var.prefix}-${count.index}-md"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
  tags = {
    task = "udacityModuleProject"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = var.numberOfVms
  managed_disk_id    = azurerm_managed_disk.main.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.main.*.id[count.index]
  lun                = count.index + 10
  caching            = "ReadWrite"
}