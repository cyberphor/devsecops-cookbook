resource "proxmox_vm_qemu" "main" {
  target_node     = var.proxmox_node_name
  clone           = var.vm_template_name
  name            = var.vm_name
  agent           = 1 # enable the QEMU agent service
  cpu             = "host"
  sockets         = 1
  cores           = 2
  memory          = 4096
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