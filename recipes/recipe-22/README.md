# Initialize Zarf on a Kubernetes Cluster

## Ingredients
* [Deploy a Kubernetes Cluster Using k3d](../recipe-22/README.md)  
* [Install Zarf](../setup/README.md#install-zarf)  

## Recipe
**Step 1.** Download the dependencies needed to configure the Kubernetes cluster. They will be downloaded in the shape of a Zarf package. 
```bash
zarf tools download-init
```

**Step 2.** Configure the Kubernetes cluster to support Zarf-based deployments.  
```bash
zarf init --confirm
```

**Step 3.** Delete the Zarf package you downloaded. 
```bash
rm zarf-init-*.zst
```

**Step 4.** Validate your Kubernetes cluster is configured as expected. 
```bash
zarf tools monitor
```

**Step 5.** To remove the additional configurations added, run the command below. 
```bash
zarf destroy --confirm
```
