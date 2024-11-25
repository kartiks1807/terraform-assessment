resource "azurerm_resource_group" "tomcat-rg" {
  name     = local.resource_group
  location = local.location
}
resource "azurerm_virtual_network" "vnet" {
  name                = "apache-app-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = azurerm_resource_group.tomcat-rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "apache-app-subnet"
  resource_group_name  = azurerm_resource_group.tomcat-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_linux_virtual_machine_scale_set" "app_vmss" {
  name                = "tomcat-app-vmss"
  resource_group_name = azurerm_resource_group.tomcat-rg.name
  location            = local.location
  sku                 = "Standard_B1ms"
  instances           = 2
  admin_username      = "kartik"
  user_data           = base64encode(templatefile("install_apache", local.data_inputs))


  admin_ssh_key {
    username   = "kartik"
    public_key = local.first_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"

  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }


  network_interface {
    name    = "primary"
    primary = true
    ip_configuration {
      name                                   = "internal"
      subnet_id                              = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.app_lb_backend.id]
    }
  }

}

resource "azurerm_monitor_autoscale_setting" "app_autoscale" {
  name                = "apache-autoscale"
  resource_group_name = azurerm_resource_group.tomcat-rg.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.app_vmss.id
  enabled             = true
  location            = local.location


  profile {
    name = "scale-profile"

    capacity {
      minimum = "2"
      maximum = "5"
      default = "2"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.app_vmss.id
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        time_window        = "PT5M"
        time_grain         = "PT1M"
        statistic          = "Average"
        threshold          = 75
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.app_vmss.id
        time_aggregation   = "Average"
        operator           = "LessThan"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
resource "azurerm_network_security_group" "nsg" {
  name                = "tomcat-app-nsg"
  location            = local.location
  resource_group_name = azurerm_resource_group.tomcat-rg.name
  depends_on          = [azurerm_linux_virtual_machine_scale_set.app_vmss]


  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"

  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

