# Deploy an App Using Terraform, Azure Container Instances, and Azure Functions

Using Terraform, deploy a containerized application to Azure Container Instances and a Python-based serverless function to Azure Functions (the containerized application is a Minecraft Server while the serverless function can start and stop the application). 

```bash
az login
az account set --subscription "Personal"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve
```
