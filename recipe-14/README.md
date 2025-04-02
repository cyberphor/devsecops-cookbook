# Create and Use a Virtual Machine Template in Proxmox with Packer and Terraform

**References**  
* [Packer: Input Variables and local variables](https://developer.hashicorp.com/packer/guides/hcl/variables#assigning-variables)
* [Cloud-Init: Data Sources - NoCloud](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html)
* [phoenixNAP: How to Install Kubernetes on Ubuntu 22.04](https://phoenixnap.com/kb/install-kubernetes-on-ubuntu)
* [Terraform: Cloud Init Guide](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/guides/cloud_init)

**Software Versions**  
| Software                    | Version     |
| --------------------------- | ----------- |
| Proxmox Virtual Environment | `8.2.2`     |
| Proxmmox Packer Plugin      | `1`         |
| Proxmox Terraform Provider  | `3.0.1-rc1` |

**Step 1.** Install Proxmox. 

**Step 2.** Login to your Proxmox server. 

**Step 3.** Upload a copy of the latest Ubuntu image (e.g., `ubuntu-22.04.4-live-server-amd64.iso`) to your Proxmox server. 

**Step 4.** Create an API token for the `root` user (uncheck the "Privilege Separation" box). 

**Step 5.** Determine the IP address of your WSL environment and Windows host. For example, my `eth0` in my WSL environment currently has an IP address of `172.19.27.181`. My Windows host has an IP address of `192.168.1.211`.

**Step 6.** Open an elevated Command Prompt and enter the command below. Make sure to (1) replace `192.168.1.211` with the IP address of your Windows host and (2) replace `172.19.27.181` with the IP address of your WSL environment. Do not close the elevated Command Prompt yet. 
```bash
netsh interface portproxy add v4tov4 listenport=8336 listenaddress=192.168.1.211 connectport=8336 connectaddress=172.19.27.181
```

**Step 7.** With the elevated Command Prompt still open, enter the command below. As before, make sure to (1) replace `192.168.1.211` with the IP address of your Windows host and (2) replace `172.19.27.181` with the IP address of your WSL environment. You can close the elevated Command Prompt now. 
```bash
netsh advfirewall firewall add rule name="Packer" dir=in action=allow protocol=TCP localport=8336
```

**Step 8.** Open a Terminal to your WSL environment and enter the command below to clone this repository. 
```bash
git clone https://github.com/cyberphor/devsecops-cookbook.git
```

**Step 9.** Change directories to this specific recipe. 
```bash
cd recipe-14/
```

**Step 10.** Change directories to the `cloud-init` folder. 
```bash
cd cloud-init/
```

**Step 11.** Enter the command below to invoke a Python-based web server.
```bash
python -m http.server 8336
```

**Step 12.** Change directories to the `packer` folder.
```bash
cd packer/
```

**Step 13.** Create a file and name it `values.auto.pkvars.hcl`. Then, add values similar to below. 
```bash
pve_api_url             = "https://192.168.1.175:8006/api2/json"
pve_api_token_id        = "root@pam!packer"
pve_api_token_secret    = "ced71a2c-8443-4a4c-b952-f3ee872c1234"
pve_target_node_name    = "hypervisor-01"
iso_file                = "local:iso/ubuntu-22.04.4-live-server-amd64.iso"
vm_id                   = "100"
vm_template_name        = "ubuntu-server-22.04"
vm_template_description = "Ubuntu Server 22.04"
vm_admin_username       = "packer" 
vm_admin_password       = "packer" 
```

**Step 14.** Initialize the `packer` directory for Packer-use.
```bash
packer init .
```

**Step 15.** Validate your Packer configuration.
```bash
packer validate .
```

You should get output similar to below. 
```
The configuration is valid.
```

**Step 16.** Run the command below.
```bash
packer build .
```

**Step 17.** Change directories to the `terraform` folder.
```bash
cd ../terraform/
```

**Step 18.** Create a file and name it `values.auto.tfvars`. Then, add values similar to below. 
```bash
pve_api_url          = "https://192.168.1.175:8006/api2/json"
pve_api_token_id     = "root@pam!packer"
pve_api_token_secret = "ced71a2c-8443-4a4c-b952-f3ee872c1234"
pve_target_node_name = "hypervisor-01"
vm_id                = "100"
vm_template_name     = "ubuntu-server-22.04"
vm_name              = "ubuntu-server-22.04"
```

**Step 19.** Initialize the `terraform` directory.
```bash
terraform init .
```

**Step 20.** Run the command below.
```bash
terraform apply
```
