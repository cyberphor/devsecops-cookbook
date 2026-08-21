# Deploy a Kubernetes Cluster Using KinD
* [Setup](#setup)
* [Deploy the Kubernetes Cluster](#deploy-the-kubernetes-cluster)
* [References](#references)

## Setup
***Step 1.** Install `kubectl`.  

**Step 2.** Install `kind`.  

## Deploy the Kubernetes Cluster
**Step 1.** Deploy a Kubernetes cluster called `demo` using `kind`.
```bash
kind create cluster --name "demo-cluster" --image kindest/node:v1.34.0 --config cluster.yaml
```

**Step 2.** Confirm the version of your Kubernetes cluster is `v1.34.0` using `kubectl`.
```bash
kubectl version
```

You should get output similar to below.
```
Client Version: v1.35.0
Kustomize Version: v5.7.1
Server Version: v1.34.0
```

## References
**kind: Local Registry**  
https://kind.sigs.k8s.io/docs/user/local-registry/

**kind: Using WSL2**  
https://kind.sigs.k8s.io/docs/user/using-wsl2/#accessing-a-kubernetes-service-running-in-wsl2
