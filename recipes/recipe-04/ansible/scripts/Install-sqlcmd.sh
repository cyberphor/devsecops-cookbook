# Step 1. Import the GPG keys for Microsoft's Ubuntu package repository.
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

# Step 2. Register Microsoft's Ubuntu package repository to your list of trusted package repositories. 
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Step 3 Download package information from HashiCorp's package repository. 
sudo apt update

# Step 4. Install `sqlcmd`. 
sudo apt install mssql-tools18 unixodbc-dev

# Step 5. Update your execution path environment variable to include `sqlcmd`. 
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc