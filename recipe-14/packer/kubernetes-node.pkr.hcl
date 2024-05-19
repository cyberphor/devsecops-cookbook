packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "main" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node_name
  vm_id                    = var.vm_id
  vm_name                  = var.vm_name
  template_description     = var.vm_template_description
  iso_file                 = var.iso_file
  iso_storage_pool         = "local"
  unmount_iso              = true
  qemu_agent               = true
  scsi_controller          = "virtio-scsi-pci"
  disks {
    disk_size              = var.vm_disk_size
    storage_pool           = "local-lvm"
    type                   = "virtio"
  }
  cores                    = var.vm_cores
  memory                   = var.vm_memory
  network_adapters {
    model                  = "virtio"
    bridge                 = "vmbr0"
    firewall               = "false"
  } 
  cloud_init               = true
  cloud_init_storage_pool  = "local-lvm"
  boot                     = "c"
  boot_wait                = "5s"
  boot_command             = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ",
    "ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<enter>",
    "<wait3s>initrd /casper/initrd <enter>",
    "<wait3s>boot <enter>",
  ]
  http_directory           = "http" 
  ssh_username             = var.admin_username
  ssh_timeout              = "20m"
}

build {
  sources                  = [ "source.proxmox-iso.main" ]
  name                     = var.vm_name
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
  # install Docker 
  provisioner "shell" {
    inline = [
      "sudo apt install docker.io -y"
    ]
  }
  # install Kubernetes
  provisioner "shell" {
    inline = [
      "sudo snap install kubeadm --classic",
      "sudo snap install kubelet --classic",
      "sudo snap install kubectl --classic",
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^\\(.*\\)$/#\\1/g' /etc/fstab"
    ]
  }
}