# Step 1. Install the following packages if not already done: gnupg, software-properties-common, and curl. They are required to verify the identity of HashiCorp's package repository.
sudo apt update 
sudo apt install -y gnupg software-properties-common

# Step 2. Install HashiCorp's GPG key.
sudo wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Step 3. Verify HashiCorp's GPG key fingerprint.
sudo gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint

# Step 4. Add HashiCorp's package repository to your list of trusted package repositories.
sudo echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list

# Step 5. Download package information from HashiCorp's package repository.
sudo apt update

# Step 6. Install Terraform.
sudo snap install terraform --classic
