# Initialize Zarf on a Kubernetes Cluster

**Step 1.** Provision a Kubernetes cluster. 

**Step 2.** Install the Zarf CLI. 

**Step 3.** Download the dependencies needed to configure the Kubernetes cluster. They will be downloaded in the shape of a Zarf package. 
```bash
zarf tools download-init
```

**Step 4.** Configure the Kubernetes cluster to support Zarf-based deployments.  
```bash
zarf init --confirm
```

**Step 5.** Delete the Zarf package you downloaded. 
```bash
rm zarf-init-*.zst
```

**Step 6.** Validate your Kubernetes cluster is configured as expected. 
```bash
zarf tools monitor
```

**Step 7.** To remove the additional configurations added, run the command below. 
```bash
zarf destroy --confirm
```
