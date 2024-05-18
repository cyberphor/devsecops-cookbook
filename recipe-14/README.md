# Create a Proxmox-based Kubernetes Node Virtual Machine Template Using Packer

**Step 1.** Install Proxmox. 

**Step 2.** Login to your Proxmox server. 

**Step 3.** Upload a copy of the latest Ubuntu image to your Proxmox server. 

**Step 4.** Create an API token for the `root` user (uncheck the "Privilege Separation" box). 

**Step 3.** Add the API token information to the `secrets.pkr.hcl` file. 