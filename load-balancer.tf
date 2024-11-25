resource "azurerm_public_ip" "public_ip_lb" {
  name                = "LB-public-ip"
  location            = local.location
  resource_group_name = azurerm_resource_group.tomcat-rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "app_lb" {
  name                = "apache-app-lb"
  location            = local.location
  resource_group_name = azurerm_resource_group.tomcat-rg.name

  frontend_ip_configuration {
    name                 = "publicIP"
    public_ip_address_id = azurerm_public_ip.public_ip_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "app_lb_backend" {
  name            = "tomcat-vms"
  loadbalancer_id = azurerm_lb.app_lb.id
}


resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "publicIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_lb_backend.id]
}