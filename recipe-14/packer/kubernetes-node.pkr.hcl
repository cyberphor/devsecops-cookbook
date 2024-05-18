source "proxmox" "main" {
  proxmox_url             = var.proxmox_api_url
  username                = var.proxmox_api_token_id
  token                   = var.proxmox_api_token_secret
  node                    = var.proxmox_node
  vm_id                   = var.vm_id
  vm_name                 = var.vm_name
  template_description    = var.vm_template_description
  iso_file                = var.iso_file
  iso_storage_pool        = var.iso_storage_pool
  unmount_iso             = true
  qemu_agent              = true
  scsi_controller         = "virtio-scsi-pci"
  disks {
    disk_size             = var.vm_disk_size
    format                = "qcow2"
    storage_pool          = "local-lvm"
    storage_pool_type     = "lvm"
    type                  = "virtio"
  }
  cores                   = var.vm_cores
  memory                  = var.vm_memory
  network_adapters {
    model                 = "virtio"
    bridge                = "vmbr0"
    firewall              = "false"
  } 
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  boot_command            = [
    "<esc><wait><esc><wait>",
    "<f6><wait><esc><wait>",
    "<bs><bs><bs><bs><bs>",
    "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    "--- <enter>"
  ]
  boot                    = "c"
  boot_wait               = "5s"
  http_directory          = "http" 
  ssh_username            = var.admin_username
  ssh_timeout             = "20m"
}

build {
  sources                 = [ "source.proxmox.main" ]
  name                    = var.vm_name
  # prepare virtual machine template for cloud-init integration
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }
  # prepare virtual machine template for cloud-init integration
  provisioner "file" {
    source = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  # prepare virtual machine template for cloud-init integration
  provisioner "shell" {
    inline = [
      "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"
    ]
  }
  # install Docker and Kubernetes
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }
}