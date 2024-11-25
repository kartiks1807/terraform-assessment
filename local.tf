locals {
  resource_group   = "tomcat-app-grp"
  location         = "North Europe"
  first_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvWwK7RdzsSjy3aibDo+A8FrmhX7dkVwdmUFJqlIrATyz3pa4TWH3PeriWObLPFLE7cJ+P34TwvBhpKkbAZrb2MW3vydBrYcIXpdh8J2CZAMIQguz8c03TH13WolYJVjTGZDY/MHxHxUJgjSBxfmAdpnc20B/ENkvsbTn1R2qfKRMI57Dq4wXGL8rHfpwiEn0XY1Y104edZI2K+Hi0e1kUymmBc96gMgJVaeEYNbxhL0c6itjOWwM6lVaMLahX4xqWH3yHzKHRFh3JA49aL5x2oI8d5fKZc3bYSxF85YsogCn+grQwd00mowAK76BXcc0iqbBw8GSGcYf4rAQrtkkL karti@Kartik"
  data_inputs = {
    heading_one = var.heading_one
  }
}