# Setup Guides
* [Create SSH Keys](#how-to-create-ssh-keys)
* [Setup Single Sign-On (SSO) Using SSH](#how-to-setup-single-sign-on-using-ssh)
* [Add Your SSH Public Key to GitHub](#how-to-add-your-ssh-public-key-to-github)
* [Create a GitHub Personal Access Token](#how-to-create-a-github-personal-access-token)
* [Create an Azure DevOps Personal Access Token](#how-to-create-an-azure-devops-personal-access-token)
* [Install the Azure CLI](#how-to-install-the-azure-cli)
* [Install Terraform](#how-to-install-terraform)
* [Install Ansible](#how-to-install-ansible)
* [Install sqlcmd](#how-to-install-sqlcmd)
* [Install Packer](#install-packer)


## How to Create SSH Keys 
**Step 1.** Generate an SSH key pair.  
```bash
# -t: defines the key pair type
# -b: defines the key lengths (i.e., the number of bits)
# -C: used to include a comment 
ssh-keygen -t rsa -b 4096 -C "for DevOps"
```

**Step 2.** Press "Enter" to save your private key to the default location (i.e., under `.ssh/id_rsa` within your home directory).  
  
**Step 3.** Enter a passphrase to encrypt the private key.  

## How to Setup Single Sign-On Using SSH
Setting up SSH-based Single Sign-On (SSO) allows you to present your SSH private key automatically during authentication (e.g., when authenticating with GitHub). 

**Step 1.** Open your BASH configuration file using your favorite text-editor
```bash
vim .bashrc
```

**Step 2.** Append the commands below to your BASH configuration file so they are be executed every time you login. 
```bash
eval "$(ssh-agent -s)" # starts the SSH authentication agent
ssh-add ~/.ssh/id_rsa  # adds your SSH private key to the SSH authentication agent
```

## How to Add Your SSH Public Key to GitHub
**Step 1.** Print and copy your SSH public key.
```bash
cat ~/.ssh/id_rsa.pub
```

**Step 2.** Open a browser and login to GitHub.  

**Step 3.** Click your profile (top-right icon) and click "Settings."  

**Step 4.** Click "SSH and GPG keys" in the pane on the left-hand side.  

**Step 5.** Click "New SSH key."  

**Step 6.** Enter a "Title" (e.g., "for DevOps").  

**Step 7.** Click "Add SSH key."

## How to Create a GitHub Personal Access Token
**Step 1.** Login to GitHub.  

**Step 2.** Click your profile (top-right icon) and click "Settings."  

**Step 3.** Click "Developer Settings" at the bottom of the pane on the left-hand side.  

**Step 4.** Click "Personal access tokens" > "Tokens (classic)."  

**Step 5.** Click "Generate new token" > "Generate new token (classic)."  

**Step 6.** Enter a "Note" (e.g., AI2C-DevOps-Week03).  

**Step 7.** Set the "Expiration" date (e.g., 60 days).  

**Step 8.** Select "repo" as the scope.  

**Step 9.** Click "Generate token."  

## How to Create an Azure DevOps Personal Access Token
**Step 1.** Browse to [http://dev.azure.com/](http://dev.azure.com/).  

**Step 2.** Click your Azure DevOps project.  

**Step 3.** Click your profile (the person-and-gear icon in the top-right corner).  

**Step 4.** Click "Personal access tokens."  

**Step 5.** Click "New Token."  

**Step 6.** Enter a "Name."  

**Step 7.** Set the "Scopes" field to "Custom defined."  

**Step 8.** Under the "Build" section, select "Read."  

**Step 9.** Click "Create."  

**Step 10.** Record your PAT and use it as necessary.

## How to Install the Azure CLI
**Step 1.** Enter the command below. 
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Step 2.** Identify your tenant and subscription IDs and save them as environment variables. 
```bash
# your tentant and subscription IDs are NOT secrets
export TENANT_ID="da3cb2a3-95dd-4a37-b857-c1264e363deb"
export SUBSCRIPTION_ID="17408d59-f3b6-43a5-a48c-c3667527f330"
```

**Step 3.** Enter the command below and authenticate when prompted. 
```bash
az login --tenant "${TENANT_ID}" --use-device-code
```

**Step 4.** Set your default subscription. 
```bash
az account set --subscription "${SUBSCRIPTION_ID}"
```

## How to Install Terraform
**Step 1.** Install the following packages if not already done: `gnupg`, `software-properties-common`, and `curl`. They are required to verify the identity of HashiCorp's package repository. 
```bash
sudo apt-get update 
sudo apt-get install -y gnupg software-properties-common
```

**Step 2.** Install HashiCorp's GPG key.
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

**Step 3.** Verify HashiCorp's GPG key fingerprint.
```bash
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
```

**Step 4.** Add HashiCorp's package repository to your list of trusted package repositories. 
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
```

**Step 5.** Download package information from HashiCorp's package repository. 
```bash
sudo apt update
```

**Step 6.** Install Terraform. 
```bash
sudo apt install terraform
```

## How to Install Ansible
**Step 1.** Install Ansible.
```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

## How to Install sqlcmd
**Step 1.** Import the GPG keys for Microsoft's Ubuntu package repository.
```bash
sudo su
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
```

**Step 2.** Register Microsoft's Ubuntu package repository to your list of trusted package repositories. 
```bash
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
exit
```

**Step 3.** Download package information from HashiCorp's package repository. 
```bash
sudo apt update
```

**Step 4.** Install `sqlcmd`. 
```bash
sudo apt install mssql-tools18 unixodbc-dev
```

**Step 5.** Update your execution path environment variable to include `sqlcmd`. 
```bash
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

## Install Homebrew on macOS
**Step 1.** Install the Command Line Tools for macOS if you haven't already. 
```bash
xcode-select --install 
```

**Step 2.** Install Homebrew.
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Step 3.** Run the two command sentences it mentions after installation. 

**Step 4.** Run Homebrew to make sure it's working. 
```bash
brew --version
```

## Install Packer
```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
```

## Install Kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Install KinD
```bash
go install sigs.k8s.io/kind@v0.31.0
```

```bash
kind delete cluster -n demo-cluster
```

## Install Zarf
```bash
ZARF_VERSION=$(curl -sIX HEAD https://github.com/zarf-dev/zarf/releases/latest | grep -i ^location: | grep -Eo 'v[0-9]+.[0-9]+.[0-9]+')
curl -sL "https://github.com/zarf-dev/zarf/releases/download/${ZARF_VERSION}/zarf_${ZARF_VERSION}_Linux_amd64" -o zarf
chmod +x zarf
sudo mv zarf /usr/local/bin/zarf
```

## Install k3d
k3d allows you to provision a multi-node k3s cluster on a single machine using docker. k3s is a lightweight Kubernetes distribution by Rancher. 
```bash
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

```bash
k3d cluster list
```

```bash
k3d cluster delete <cluster_name>
```

## Install the UDS CLI
```bash
wget -O uds https://github.com/defenseunicorns/uds-cli/releases/download/v0.30.0/uds-cli_v0.30.0_Linux_amd64 &&\
chmod +x uds &&\
sudo mv uds /usr/local/bin/
```

```bash
uds version
```

```
v0.30.0
```