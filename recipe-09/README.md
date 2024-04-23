## Recipe 09: Add Observability to an Kubernetes Cluster Using OpenTelemetry and Elastic 
The purpose of this recipe is to add observability and security to a Kubernetes cluster using OpenTelemetry and Elastic. 
* [References](#references)
* [Notes](#notes)
* [Setup](#setup)

![elastic-and-opentelemetry.png](elastic-and-opentelemetry.png)

## References
If I find any helpful references, I will put them here. 
* [OpenTelemetry: Collector | Configuration](https://opentelemetry.io/docs/collector/configuration/)
* [Elastic: Modern observability and security on Kubernetes with Elastic and OpenTelemetry](https://www.elastic.co/blog/implementing-kubernetes-observability-security-opentelemetry)
* [Elastic: Add a Fleet Server](https://www.elastic.co/guide/en/fleet/8.5/add-fleet-server-on-prem.html)
* [Elastic: Run Elastic Agent Standalone on Kubernetes](https://www.elastic.co/guide/en/fleet/current/running-on-kubernetes-standalone.html)

## Notes
If there are any additional notes, I will put them here. 
* Deploying a Fleet Server onto a Kubernetes cluster involves creating a DaemonSet of Elastic Agents. One Elastic Agent is installed on each node in your Kubernetes Cluster. Then, one is appointed to be the Fleet Server. 

## Setup
This recipe assumes (1) you're using a Linux-based environment (GitHub Codespaces, Azure Shell, Windows Subsystem for Linux, etc.), (2) you've installed the software required for this recipe (i.e., Python, Docker, Kubernetes, Helm, and Azure CLI), (3) you've forked this repository, (4) you've downloaded this repository, and (5) you're running commands from the `recipe-09/` folder. 

**Step 1.** Define environment variables for your infrastructure. I usually save my environment variables in a file called something like `.env` and run `source .env` as needed. This makes it easy to pick up where I left off after leaving my workspace for an extended period of time. If you didn't know, the `source` command reads and executes shell commands from the file you provide it.   
```bash
export APP_NAME="toughalien"
export SUBSCRIPTION_ID="Personal"
export LOCATION="eastus"
export RESOURCE_GROUP_NAME="toughalien"
export ACR_NAME="toughalien"
export ACR_SKU="Basic"
export AKS_CLUSTER_NAME="toughalien"
export AKS_NODE_COUNT=4
```

**Step 2.** Login to Azure using the CLI. 
```bash
az login --use-device-code
```

**Step 3.** Set your subscription.
```bash
az account set --subscription "${SUBSCRIPTION_ID}"
```

**Step 4.** Create a resource group to house the Azure Container Registry (ACR) and Azure Kubernetes Service (AKS) instance you're about to make. 
```bash
az group create --name "${RESOURCE_GROUP_NAME}" --location eastus
```

**Step 5.** Create an ACR. 
```bash
az acr create --resource-group "${RESOURCE_GROUP_NAME}" --name "${ACR_NAME}" --sku "${ACR_SKU}"
```

**Step 6.** Create an AKS instance. This step will (1) create an additional resource group to house Kubernetes nodes and then (2) add an AKS instance to your first resource group. 
```bash
az aks create --resource-group "${RESOURCE_GROUP_NAME}" --name "${AKS_CLUSTER_NAME}" --enable-managed-identity --node-count "${AKS_NODE_COUNT}" --generate-ssh-keys --node-resource-group "${APP_NAME}-kubernetes-nodes"
```

**Step 7.** Attach your ACR to your AKS instance. Do not skip this step. Otherwise, your AKS instance won't have access to your ACR and you'll get `ErrImagePull`, `Failed to pull image`, and `401 Unauthorized` errors when you begin deploying containers. 
```bash
az aks update --resource-group "${RESOURCE_GROUP_NAME}" --name "${AKS_CLUSTER_NAME}" --attach-acr "${ACR_NAME}"
```

**Step 8.** Download credentials from your AKS instance for `kubectl` to use.
```bash
az aks get-credentials --resource-group "${RESOURCE_GROUP_NAME}" --name "${AKS_CLUSTER_NAME}"
```

**Step 9.** Add Elastic's remote Helm repository to your local Helm registry. 
```bash
helm repo add elastic https://helm.elastic.co
```

## Task 01: Deploy Elastic
### Subtask 01: Create an Elasticsearch Service
**Step 1.** Create an Elasticsearch service using Elastic's Elasticsearch Helm chart. 
```bash
helm install elasticsearch elastic/elasticsearch
```

You should get output similar to below. 
```
NAME: elasticsearch
LAST DEPLOYED: Tue Apr 23 22:05:37 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Watch all cluster members come up.
  $ kubectl get pods --namespace=default -l app=elasticsearch-master -w
2. Retrieve elastic user's password.
  $ kubectl get secrets --namespace=default elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. Test cluster health using Helm test.
  $ helm --namespace=default test elasticsearch
```

### Subtask 02: Create a Kibana Service
**Step 1.** Create a Kibana service using Elastic's Kibana Helm chart. 
```bash
helm install kibana elastic/kibana
```

You should get output similar to below. 
```
NAME: kibana
LAST DEPLOYED: Tue Apr 23 22:05:50 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Watch all containers come up.
  $ kubectl get pods --namespace=default -l release=kibana -w
2. Retrieve the elastic user's password.
  $ kubectl get secrets --namespace=default elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. Retrieve the kibana service account token.
  $ kubectl get secrets --namespace=default kibana-kibana-es-token -ojsonpath='{.data.token}' | base64 -d
```

**Step 2.** Expose the Kibana service by deploying a Load Balancer service to route traffic to it. The command sentence creates a Load Balancer service called `siem` (Security Incident and Event Manager). 
```bash
kubectl expose svc kibana-kibana --type=LoadBalancer --name siem
```

### Subtask 03: Create an APM Server Service
**Step 1.** Create a APM Server service using Elastic's APM Server Helm chart. 
```bash
helm install apm-server elastic/apm-server
```

You should get output similar to below. 
```
NAME: apm-server
LAST DEPLOYED: Tue Apr 23 22:30:18 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Watch all containers come up.
  $ kubectl get pods --namespace=default -l app=apm-server-apm-server -w
```

### Subtask 04: Create an API Key for the OpenTelemetry Collector
**Step 1.** Get the password for the `elastic` account. 
```bash
kubectl get secrets --namespace=default elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d && echo ""
```

**Step 2.** Browse to `http://localhost:5601` and login. 

**Step 3.** If you see a splash page that says "Start by adding integrations", click "Explore on my own."

**Step 4.** Click the *hamburger menu* in the top-left corner. Under "Management", click "Stack Management."

**Step 5.** Under "Security", click "API keys." 

**Step 6.** Click "Create API key". Enter `OpenTelemetry Collector` in the "Name" field and then, click "Create API key."

**Step 7.** Copy the base64-encoded API key generated and paste it to [the provided Kubernetes manifest file](kubernetes/opentelemetry.yaml).

## Task 02: Deploy OpenTelemetry
**Step 1.** Add Custom Resource Definitions (CRDs) to your cluster for the following object types: Certificate and Issuer. The OpenTelemetry Operator needs them both. 
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
```

**Step 2.** Deploy an OpenTelemetry Operator to the `opentelemetry-operator-system` namespace in your cluster.
```bash
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
```

**Step 3.** Confirm your OpenTelemetry Operator is running by checking the status of the pods created in the previous step. 
```bash
kubectl get pods -n opentelemetry-operator-system
```

**Step 4.** Apply [the provided Kubernetes manifest file](kubernetes/opentelemetry.yaml). It deploys an OpenTelemetry Collector resource and Instrumentation resource.  
```bash
kubectl apply -f kubernetes/opentelemetry.yaml
```

**Step 5.** Confirm your OpenTelemetry Collector is running by checking the status of the pods created in the previous step. 
```bash
kubectl get pods 
```

**Step 6.** Confirm your OpenTelemetry Instrumentation resource is working by checking the status of the pods created in the previous step. 
```bash
kubectl get instrumentation
```

## Task 03: Configure Your App to Send Telemetry Data
**Step 1.** Login to your ACR. 
```bash
az acr login --name "${ACR_NAME}"
```

**Step 2.** Build, tag, and push a container image to your ACR. Specifying `--platform linux/amd64` forces your local Docker host to build an image using the same CPU architecture as the Docker hosts that will be used in Azure. Also, the command sentence below references a Dockerfile and FastAPI-application in the folder of this recipe, feel free to use whatever image you want. 
```bash
docker build --push --tag ${ACR_NAME}.azurecr.io/${APP_NAME}:latest --platform linux/amd64 -f docker/Dockerfile src/
```

**Step 3.** Deploy your app using [the provided Kubernetes manifest file](kubernetes/service.yaml). It creates two deployments (staging and production) and one Load Balancer service. Both deployments have an annotation the OpenTelemetry Collector uses to decide whether or not to inject telemetry functions. 
```bash
kubectl apply -f kubernetes/service.yaml
```