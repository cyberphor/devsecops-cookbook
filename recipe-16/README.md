## Recipe 16
The purpose of this recipe is to TEXT GOES HERE. It assumes you have `terraform` and `az` installed.

**Step 1.** Text goes here.
```bash
echo 'tenant_id = "..."' > terraform.tfvars
echo 'subscription_id = "..."' >> terraform.tfvars
```

**Step 2.** Identify your tenant and subscription IDs and save them as environment variables. 
```bash
echo 'export TENANT_ID="..."' > .env
echo 'export SUBSCRIPTION_ID="..."' >> .env
```

**Step 3.** Text goes here.
```bash
source .env
```

**Step 4.** Enter the command below and authenticate when prompted. 
```bash
az login --tenant "${TENANT_ID}" --use-device-code
```

**Step 5.** Text goes here.
```bash
terraform -chdir=terraform init
```

**Step 6.** Text goes here.
```bash
terraform -chdir=terraform plan
```

**Step 7.** Text goes here.
```bash
terraform -chdir=terraform apply
```

## Troubleshooting
```bash
rm -rf .terraform && rm .terraform* && rm *.tfstate
```