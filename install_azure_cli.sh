# Step 1. Enter the command below.
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Step 2. Identify your tenant and subscription IDs and save them as environment variables.
# your tentant and subscription IDs are NOT secrets
export TENANT_ID="da3cb2a3-95dd-4a37-b857-c1264e363deb"
export SUBSCRIPTION_ID="17408d59-f3b6-43a5-a48c-c3667527f330"

# Step 3. Enter the command below and authenticate when prompted.
az login --tenant "${TENANT_ID}" --use-device-code

# Step 4. Set your default subscription.
az account set --subscription "${SUBSCRIPTION_ID}"