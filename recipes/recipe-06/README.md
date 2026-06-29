## Recipe 06

### Usage
```bash
az login
az account set --subscription "Personal"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve
```