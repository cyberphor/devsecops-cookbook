# Deploy UDS Core on a Kubernetes Cluster

**Step 1.** Install [k3d](../setup/README.md#install-k3d). 

**Step 2.** Install the [UDS CLI](../setup/README.md#install-the-uds-cli). 

**Step 3.** Deploy a k3s cluster with UDS Core installed using the UDS CLI. The UDS CLI will invoke `k3d` to deploy a k3s cluster. 
```bash
uds deploy k3d-core-demo:latest
```

When prompted, enter `y` to deploy the UDS Core bundle. If you're doing this in WSL and it hangs at `INFO[0015] Injecting records for hostAliases (incl. host.k3d.internal) and for 2 network members into CoreDNS configmap...`, try updating WSL to the latest version. 

**Step 4.** To verify all UDS Core pods are working, run the command below. *There should be no output.*
```bash
uds zarf tools kubectl get pods -A --no-headers | grep -Ev '(Running|Completed)'
```

**Clean Up.** When you're done, use `k3d` to delete the k3s cluster created. 
```bash
k3d cluster delete uds
```
