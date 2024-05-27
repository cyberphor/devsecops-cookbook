resource "proxmox_vm_qemu" "main" {
  # https://github.com/Telmate/terraform-provider-proxmox/blob/master/examples/pxe_example.tf
  target_node             = var.proxmox_node_name
  clone                   = var.vm_template_name
  name                    = var.vm_name
  agent                   = 1
  os_type                 = "cloud-init"  
  cloudinit_cdrom_storage = "local-lvm" # https://github.com/Telmate/terraform-provider-proxmox/issues/944  
}