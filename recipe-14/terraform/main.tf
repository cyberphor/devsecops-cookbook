resource "proxmox_vm_qemu" "controller" {
  target_node     = var.proxmox_node_name
  clone           = var.vm_template_name
  vmid            = 200
  name            = "controller"
  agent           = 1 # enable the QEMU agent service
  cpu             = "host"
  sockets         = 1
  cores           = 2
  memory          = 4096
  os_type         = "clout-init"
  disks {
    virtio {
      virtio0 {
        disk {
          size    = 20
          storage = "local-lvm"
        }
      }
    }
  }
  ipconfig0       = "ip=192.168.1.200/24,gw=192.168.1.1"
}

resource "proxmox_vm_qemu" "worker_01" {
  target_node     = var.proxmox_node_name
  clone           = var.vm_template_name
  vmid            = 201
  name            = "worker-01"
  agent           = 1 # enable the QEMU agent service
  cpu             = "host"
  sockets         = 1
  cores           = 2
  memory          = 4096
  os_type         = "clout-init"
  disks {
    virtio {
      virtio0 {
        disk {
          size    = 20
          storage = "local-lvm"
        }
      }
    }
  }
  ipconfig0       = "ip=192.168.1.201/24,gw=192.168.1.1"
}

resource "proxmox_vm_qemu" "worker_02" {
  target_node     = var.proxmox_node_name
  clone           = var.vm_template_name
  vmid            = 202
  name            = "worker-02"
  agent           = 1 # enable the QEMU agent service
  cpu             = "host"
  sockets         = 1
  cores           = 2
  memory          = 4096
  os_type         = "clout-init"
  disks {
    virtio {
      virtio0 {
        disk {
          size    = 20
          storage = "local-lvm"
        }
      }
    }
  }
  ipconfig0       = "ip=192.168.1.202/24,gw=192.168.1.1"
}