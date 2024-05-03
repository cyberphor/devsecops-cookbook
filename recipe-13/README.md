## Recipe 13: Elastic Defend
The purpose of this recipe is TBD.
* [References](#references)
* [Notes](#notes)
* [Setup](#setup)
* [Task 01: Deploy Elastic](#task-01-deploy-elastic)

## References
If I find any helpful references, I will put them here. 
* [OpenTelemetry: Collector | Configuration](https://opentelemetry.io/docs/collector/configuration/)
* [Elastic: Modern observability and security on Kubernetes with Elastic and OpenTelemetry](https://www.elastic.co/blog/implementing-kubernetes-observability-security-opentelemetry)
* [Elastic: Add a Fleet Server](https://www.elastic.co/guide/en/fleet/8.5/add-fleet-server-on-prem.html)
* [Elastic: Run Elastic Agent Standalone on Kubernetes](https://www.elastic.co/guide/en/fleet/current/running-on-kubernetes-standalone.html)
* [Elastic APM Server Helm Chart: values.yaml example](https://github.com/elastic/helm-charts/blob/main/apm-server/examples/security/values.yaml)
* [OpenTelemetry TLS Configuration Settings](https://github.com/open-telemetry/opentelemetry-collector/blob/main/config/configtls/README.md)
* [Azure: Configure a federated identity credential on an app](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions)
* [Azure: Configure a GitHub Action to create a container instance](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-github-action?tabs=openid)

## Notes
If there are any additional notes, I will put them here. 

## Setup
This recipe assumes (1) you're using a Linux-based environment (GitHub Codespaces, Azure Shell, Windows Subsystem for Linux, etc.), (2) you've installed the software required for this recipe (i.e., Python, Docker, Kubernetes, Helm, and Azure CLI), (3) you've forked this repository, (4) you've downloaded this repository, and (5) you're running commands from the `recipe-13/` folder. 

**Step 1.** Define environment variables for your infrastructure. I usually save my environment variables in a file called something like `.env` and run `source .env` as needed. This makes it easy to pick up where I left off after leaving my workspace for an extended period of time. If you didn't know, the `source` command reads and executes shell commands from the file you provide it.   
```bash
export APP_NAME="squidfall"
export SUBSCRIPTION_ID="449b777a-56a9-4ce8-853d-7cd824d7118f"
export LOCATION="eastus"
export RESOURCE_GROUP_NAME="${APP_NAME}"
```
 
**Step 2.** Login to Azure using the CLI. 
```bash
az login --use-device-code
```

**Step 3.** Set your subscription.
```bash
az account set --subscription "${SUBSCRIPTION_ID}"
```

**Step 4.** Create a virtual environment to house the `scripts/init_azure.py` script's Python dependencies. 
```bash
python -m venv .venv
```

**Step 5.** Activate the `scripts/init_azure.py` script's Python virtual environment. 
```bash
source .venv/bin/activate
```

**Step 6.** Install the `scripts/init_azure.py` script's Python dependencies.
```bash
python -m pip install -r scripts/requirements.txt
```

**Step 7.** Run the `scripts/init_azure.py` script. 
```bash
python scripts/init_azure.py --app-name "${APP_NAME}" --subscription-id "${SUBSCRIPTION_ID}" --location "${LOCATION}"
```

You should get output similar to below.
```
[*] Created Terraform state resource group
[*] Created Terraform state storage account
[*] Created Terraform state blob container
[!] Copy and paste the commands below into your shell environment:

terraform -chdir=terraform init -backend-config="storage_account_name=squidfall449b777a56a9666" -backend-config="access_key=DMYijJgcDcmPMUFWJe8fWLV0tt/8+2J+c7rKU4lFjdAQDOFj9HhQnulZwA2Ui+m8tmtKSLp8b6Rb+ASt+Rr666=="
terraform -chdir=terraform apply
```

**Step 8.** Copy and paste the commands printed by the previous step (enter `yes` when prompted). You should get output similar to below. It creates the following resources: resource group, container registry, Kubernetes cluster, and role assignment. 
```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

**Step 9.** Copy and paste the commands below to your terminal session to declare and initialize the remaining environment variables needed.
```bash
export ACR_NAME=$(terraform -chdir=terraform output -raw ACR_NAME)
export AKS_NAME=$(terraform -chdir=terraform output -raw AKS_NAME)
```

**Step 10.** Download credentials from your AKS instance for `kubectl` to use. 
```bash
az aks get-credentials --resource-group "${RESOURCE_GROUP_NAME}" --name "${AKS_NAME}"
```

## Task 01: Deploy Elastic
**Step 1.** Install Elastic's Custom Resource Definitions (CRDs).
```bash
kubectl create -f https://download.elastic.co/downloads/eck/2.12.1/crds.yaml
```

You should get output similar to below.
```
customresourcedefinition.apiextensions.k8s.io/agents.agent.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/apmservers.apm.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/beats.beat.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/elasticmapsservers.maps.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/elasticsearchautoscalers.autoscaling.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/elasticsearches.elasticsearch.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/enterprisesearches.enterprisesearch.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/kibanas.kibana.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/logstashes.logstash.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/stackconfigpolicies.stackconfigpolicy.k8s.elastic.co created
```

**Step 2.** Install the Elastic Operator.
```bash
kubectl apply -f https://download.elastic.co/downloads/eck/2.12.1/operator.yaml
```

You should get output similar to below.
```
namespace/elastic-system created
serviceaccount/elastic-operator created
secret/elastic-webhook-server-cert created
configmap/elastic-operator created
clusterrole.rbac.authorization.k8s.io/elastic-operator created
clusterrole.rbac.authorization.k8s.io/elastic-operator-view created
clusterrole.rbac.authorization.k8s.io/elastic-operator-edit created
clusterrolebinding.rbac.authorization.k8s.io/elastic-operator created
service/elastic-webhook-server created
statefulset.apps/elastic-operator created
validatingwebhookconfiguration.admissionregistration.k8s.io/elastic-webhook.k8s.elastic.co created
```

**Step 3.** Apply the provided Kubernetes manifest. 
```bash
kubectl apply -f kubernetes/elastic.yaml
```

**Step 4.** Expose the Kibana service by deploying a Load Balancer service to route traffic to it. The command sentence below creates a Load Balancer service called `siem`. SIEM is an acronym for Security Incident and Event Manager. 
```bash
kubectl expose svc kibana-kb-http --type=LoadBalancer --name siem
```

**Step 5.** Get the external IP address of the `siem` service. 
```bash
kubectl get svc/siem
```

You should get output similar to below. 
```
NAME   TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)          AGE
siem   LoadBalancer   10.0.114.32   4.156.15.102   5601:30301/TCP   4m34s
```

**Step 6.** Get the password for the `elastic` account. 
```bash
kubectl get secrets elasticsearch-es-elastic-user -ojsonpath="{.data.elastic}" | base64 -d && echo ""
```

**Step 5.** Open a browser and go to TCP port 5601 on the external IP address of the `siem` service (e.g., `https://4.156.15.102:5601`). Then, login. For the username field, enter `elastic`. For the password field, use the one you printed to the console in the previous step.