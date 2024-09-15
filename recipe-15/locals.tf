locals {
  virtual_machines = {
    "vm1" = {
      name               = "${random_pet.main.id}-01"
      private_ip_address = "10.0.0.11"
    },
    "vm2" = {
      name               = "${random_pet.main.id}-02"
      private_ip_address = "10.0.0.12"
    },
    "vm3" = {
      name               = "${random_pet.main.id}-03"
      private_ip_address = "10.0.0.13"
    },
  }
}