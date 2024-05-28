source "proxmox-iso" "main" {
  node                     = var.proxmox_node_name
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true
  vm_id                    = var.vm_id
  vm_name                  = var.vm_name
  template_description     = var.vm_template_description
  iso_file                 = var.iso_file
  iso_storage_pool         = "local"
  unmount_iso              = true
  qemu_agent               = true
  cores                    = var.vm_cores
  memory                   = var.vm_memory
  scsi_controller          = "virtio-scsi-pci"
  disks {
    type                   = "virtio"
    disk_size              = var.vm_disk_size
    storage_pool           = "local-lvm"
  }
  network_adapters {
    model                  = "virtio"
    bridge                 = "vmbr0"
    firewall               = "false"
  } 
  boot_wait                = "5s"
  boot_command             = [
    "c",
    "<wait>",
    "linux /casper/vmlinuz --- autoinstall ",
    "ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<enter>",
    "<wait3s>initrd /casper/initrd <enter>",
    "<wait3s>boot <enter>",
  ]
  http_directory           = "../cloud-init" 
  ssh_timeout              = "20m"
  ssh_username             = var.vm_admin_username
  ssh_password             = var.vm_admin_password
  cloud_init_storage_pool  = "local-lvm" # specify where to store the Cloud-Init CDROM
  cloud_init               = true       # add an empty Cloud-Init CDROM drive after the virtual machine has been converted to a template
}

build {
  sources                  = [ "source.proxmox-iso.main" ]
  #provisioner "ansible" {
  #  playbook_file          = "../ansible/playbook.yaml"
  #  extra_arguments = [
  #    "--scp-extra-args", "'-O'"
  #  ]
  #}
}