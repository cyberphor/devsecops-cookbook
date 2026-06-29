"""Creates resources needed to store Terraform state in Azure"""

# import built-in module
import argparse

# import third-party modules
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.storage import StorageManagementClient


# define main
def main(app_name: str, subscription_id: str, location: str):
    """
    Creates resources needed to store Terraform state in Azure
    """
    # define variables
    resource_group_name = f"{app_name}-terraform-state"
    storage_account_name = f"{app_name}{subscription_id}".replace("-", "")[0:24]
    blob_container_name = "terraform"

    # init the Azure objects and clients required
    credential = DefaultAzureCredential()
    resource_client = ResourceManagementClient(credential, subscription_id)
    storage_client = StorageManagementClient(credential, subscription_id)

    # make sure resource group exists
    resource_groups = [
        resource_group.name for resource_group in resource_client.resource_groups.list()
    ]
    if resource_group_name in resource_groups:
        print("[+] Skipping creation of Terraform state resource group")
    else:
        resource_client.resource_groups.create_or_update(
            resource_group_name, {"location": location}
        )
        print("[*] Created Terraform state resource group")

    # make sure storage account exists
    storage_accounts = [
        storage_account.name
        for storage_account in storage_client.storage_accounts.list()
    ]
    if storage_account_name in storage_accounts:
        print("[+] Skipping creation of Terraform state storage account")
    else:
        storage_account = storage_client.storage_accounts.check_name_availability(
            {"name": storage_account_name}
        )
        if not storage_account.name_available:
            raise ValueError("[x] The storage account name requested is not available")
        else:
            poller = storage_client.storage_accounts.begin_create(
                resource_group_name,
                storage_account_name,
                {
                    "location": location,
                    "kind": "StorageV2",
                    "sku": {"name": "Standard_LRS"},
                },
            )
            storage_account = poller.result()
            print("[*] Created Terraform state storage account")

    # get access key to storage account
    storage_account_keys = storage_client.storage_accounts.list_keys(
        resource_group_name, storage_account_name
    )
    storage_account_key = storage_account_keys.keys[0].value

    # make sure blob container exists
    blob_containers = [
        blob_container.name
        for blob_container in storage_client.blob_containers.list(
            resource_group_name, storage_account_name
        )
    ]
    if blob_container_name in blob_containers:
        print("[+] Skipping creation of Terraform state blob container")
    else:
        storage_client.blob_containers.create(
            resource_group_name, storage_account_name, blob_container_name, {}
        )
        print("[*] Created Terraform state blob container")

    # return what's needed
    print("[!] Copy and paste the commands below into your shell environment:\n")
    print(
        f'terraform -chdir=terraform init -backend-config="storage_account_name={storage_account_name}" -backend-config="access_key={storage_account_key}"'
    )
    print("terraform -chdir=terraform apply")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-name", type=str, required=True)
    parser.add_argument("--subscription-id", type=str, required=True)
    parser.add_argument("--location", type=str, required=True)
    args = parser.parse_args()
    main(
        app_name=args.app_name,
        subscription_id=args.subscription_id,
        location=args.location,
    )

# reference: https://learn.microsoft.com/en-us/python/api/overview/azure/?view=azure-python)