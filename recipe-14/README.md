# Create a Proxmox-based Kubernetes Node Virtual Machine Template Using Packer

**Step 1.** Install Proxmox. 

**Step 2.** Login to your Proxmox server. 

**Step 3.** Upload a copy of the latest Ubuntu image to your Proxmox server. 

**Step 4.** Create an API token for the `root` user (uncheck the "Privilege Separation" box). 

**Step 5.** Add the API token information to the `secrets.pkrvars.hcl` file. 

**Step 6.** Initialize the `packer` directory for Packer-use.
```bash
packer init packer/
```

**Step 7.** Validate your Packer configuration.
```bash
packer validate -var-file="secrets.pkrvars.hcl" .
```

You should get output similar to below. 
```
The configuration is valid.
```

**Step 8.** Validate your Packer configuration.
```bash
packer build -var-file="secrets.pkrvars.hcl" .
```
