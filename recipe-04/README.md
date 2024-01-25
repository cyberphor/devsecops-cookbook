## Recipe 04

**Step 1.** Install [Terraform](https://developer.hashicorp.com/terraform/install) if you don't already have it installed. 

**Step 2.** Install Ansible if you don't already have it installed.
```bash
# this command is meant to be ran on your personal computer from any directory
python -m pip install ansible
```

**Step 3.** Start an SSH authentication agent and add your SSH private key to it. The commands below show how you would do this in Linux. 
```bash
# these commands are meant to be ran on your personal computer from any directory
eval "$(ssh-agent -s)" # starts the SSH authentication agent
ssh-add ~/.ssh/id_rsa  # adds your SSH private key to the SSH authentication agent
```

**Step 4.** Download this GitHub repository and change directories to `recipe-04`. 
```bash
# this command is meant to be ran on your personal computer from any directory
git clone https://github.com/cyberphor/devops-cookbook
cd devops-cookbook/recipe-04/
```

**Step 5.** Deploy a virtual machine in Azure using the commands below and the [provided Terraform files](terraform). 
```bash
# these commands are meant to be ran on your personal computer from the "devops-cookbook/recipe-04/" directory
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply -auto-approve
```

**Step 6.** Save the username and IP address values printed by Terraform as environment variables. They will be used in the next step. 
```bash
export USERNAME=$(terraform -chdir=terraform output -raw username)
export IP_ADDRESS=$(terraform -chdir=terraform output -raw ip_address)
```

**Step 7.** Configure the virtual machine you just created using the commands below and the provided [Ansible playbook](ansible/playbook.yaml). The playbook references scripts in the [`ansible/scripts`](ansible/scripts/) folder. These scripts automate installing Terraform, Packer, Azure CLI, Docker, Kubectl, Helm, etc. If you want to add or remove scripts, (1) add/remove the script in the [`ansible/scripts`](ansible/scripts/) folder and then (2) update the [Ansible playbook](ansible/playbook.yaml). 
```bash
# this command is meant to be ran on your personal computer from the "devops-cookbook/recipe-04/" directory
ansible-playbook ansible/playbook.yaml -u $USERNAME -i ansible/inventory.yaml --ssh-common-args='-o StrictHostKeyChecking=no'
```

**Step 8.** Login to the virtual machine created by Terraform during Step 5 above. 
```bash
# this command is meant to be ran on your personal computer (from any directory)
ssh $USERNAME@$IP_ADDRESS
```

**Step 9.** (optional) Login to the Azure CLI from the virtual machine and set your subscription.
```bash
# this command is meant to be ran on the virtual machine created by Terraform during Step 5 above
az login --use-device-code
az account set --subscription "Personal"
```