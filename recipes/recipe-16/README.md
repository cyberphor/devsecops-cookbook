## Recipe 16
The purpose of this recipe is to demonstrate the idea of "Dashboards-as-Code." It assumes you have `terraform` and `az` installed.

**Step 1.** Save your environment variables to a file called `.env` for `az` to use.
```bash
echo 'export TENANT_ID="..."' > .env
echo 'export SUBSCRIPTION_ID="..."' >> .env
```

**Step 2.** Feed your `.env` file to `source` so it can add your environment variables to your current shell session.
```bash
source .env
```

**Step 3.** Save your environment variables to a file called `terraform.tfvars` for `terraform` to use.
```bash
echo 'tenant_id = "..."' > terraform.tfvars
echo 'subscription_id = "..."' >> terraform.tfvars
```

**Step 4.** Enter the command below and authenticate when prompted. 
```bash
az login --tenant "${TENANT_ID}" --use-device-code
```

**Step 5.** Enter the command sentence below so you can deploy an Azure Monitor Workspace instance.
```bash
az provider register --namespace Microsoft.Monitor
```

**Step 6.** Enter the command sentence below so you can deploy an Azure Managed Grafana instance.
```bash
az provider register --namespace Microsoft.Dashboard
```

**Step 7.** Change directories to `terraform`.
```bash
cd terraform
```

**Step 8.** Init the `terraform` directory (i.e., download all the external modules required).
```bash
terraform init
```

**Step 9.** Create a Terraform plan.
```bash
terraform plan
```

**Step 10.** Apply the Terraform plan you just created. When it's done, browser to the URL printed by `terraform`. 
```bash
terraform apply
```

## Troubleshooting
**How to Remove a Specific Resource From Your Terraform State**  
```bash
terraform state list | grep GrafanaDashboard
terraform state rm module.GrafanaDashboard.grafana_dashboard.performance
```

**How to Clear Your Terraform State**  
```bash
rm -rf .terraform && rm .terraform* && rm *.tfstate
```

## References
* [Grafana: Azure Monitor data source](https://grafana.com/docs/grafana/latest/datasources/azure-monitor/)
* [Microsoft Kusto Tutorial: Learn common operators](https://learn.microsoft.com/en-us/kusto/query/tutorials/learn-common-operators?view=microsoft-fabric)
* [Hashicorp (YouTube): Terraforming Grafana for next-gen dashboards](https://youtu.be/qGdGMnQ83SA?si=8ujM0IACCRUY3iZr)