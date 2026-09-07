# Create multiple Linux virtual machines in Azure using Terraform

## Ingredients
Text goes here.

## Recipe
**Step 1.** Text goes here.
```bash
terraform -chdir=terraform init
```

**Step 2.** Text goes here.
```bash
terraform -chdir=terraform apply -auto-approve
```

**Step 3.** Text goes here.
```bash
ansible-playbook ansible/playbook.yaml -i ansible/inventory.yaml --ssh-common-args='-o StrictHostKeyChecking=no'
```

## Cleaning Up
Text goes here.

## References
* [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)