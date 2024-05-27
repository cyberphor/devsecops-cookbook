# Create a Proxmox-based Kubernetes Node Virtual Machine Template Using Packer

**References**  
* [Packer: Input Variables and local variables](https://developer.hashicorp.com/packer/guides/hcl/variables#assigning-variables)
* [Cloud-Init: Data Sources - NoCloud](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html)
* [phoenixNAP: How to Install Kubernetes on Ubuntu 22.04](https://phoenixnap.com/kb/install-kubernetes-on-ubuntu)
* [Terraform: Cloud Init Guide](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/guides/cloud_init)

**Software Versions**  
* Proxmox Virtual Environment: 8.2.2
* Proxmmox Packer Plugin: 1 
* Proxmox Terraform Provider: 3.0.1-rc1

**Notes**  
Your virtual machine template needs a way of telling future instances where to boot from. This is the purpose of the `99-pve.cfg` file. It defines where to look for cloud-init data. 

**Step 1.** Install Proxmox. 

**Step 2.** Login to your Proxmox server. 

**Step 3.** Upload a copy of the latest Ubuntu image to your Proxmox server. 

**Step 4.** Create an API token for the `root` user (uncheck the "Privilege Separation" box). 

**Step 5.** Text goes here.
```bash
cd packer/
vim .env
```

**Step 6.** Text goes here.
```bash
export proxmox_api_url="http://192.168.1.175:8006/api2/json"
export proxmox_api_token_id="root@pam!packer"
export proxmox_api_token_secret="a02c7183-da32-4f33-bd56-18ed7b4f4666"
export PKR_VAR_proxmox_api_url=$proxmox_api_url
export PKR_VAR_proxmox_api_token_id=$proxmox_api_token_id
export PKR_VAR_proxmox_api_token_secret=$proxmox_api_token_secret
export TF_VAR_proxmox_api_url=$proxmox_api_url
export TF_VAR_proxmox_api_token_id=$proxmox_api_token_id
export TF_VAR_proxmox_api_token_secret=$proxmox_api_token_secret
```

**Step 6.** Initialize the `packer` directory for Packer-use.
```bash
packer init .
```

**Step 7.** Validate your Packer configuration.
```bash
packer validate .
```

You should get output similar to below. 
```
The configuration is valid.
```

**Step 8.** Text goes here.
```bash
packer build .
```
