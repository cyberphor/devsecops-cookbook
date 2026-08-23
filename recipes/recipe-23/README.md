# Deploy UDS Core on a Kubernetes Cluster

**Step 1.** Install [k3d](../setup/README.md#install-k3d). 

**Step 2.** Install the [UDS CLI](../setup/README.md#install-the-uds-cli). 

**Step 3.** 

**Step 4.**
```bash
sudo sysctl -w fs.inotify.max_user_instances=8192
```

**Step 3.** Deploy a k3s cluster with UDS Core installed using the UDS CLI. The UDS CLI will invoke `k3d` to deploy a k3s cluster. 
```bash
uds deploy k3d-core-demo:latest
```

When prompted, enter `y` to deploy the UDS Core bundle. When the command finishes, you should see output similar to below. 
```bash
2026-08-22 22:42:32 INF running health checks chart=uds-portal

     Connect Command           | Description                                      
     zarf connect keycloak     | Directly connect to the Keycloak HTTP service    
     zarf connect alertmanager | Directly connect to the Alertmanager HTTP service
     zarf connect prometheus   | Directly connect to the Prometheus HTTP service 
```

**Step 4.** To verify all UDS Core pods are working, run the command below. *There should be no output.*
```bash
uds zarf tools kubectl get pods -A --no-headers | grep -Ev '(Running|Completed)'
```

**Troubleshooting**. If you're doing this in WSL and it hangs at `INFO[0015] Injecting records for hostAliases (incl. host.k3d.internal) and for 2 network members into CoreDNS configmap...`, try updating WSL to the latest version. 

If it hangs at `2026-08-22 22:32:02 INF performing Helm install chart=falco`, it may be because your kernel's `fs.inotify.max_user_instances` limit is too low. To investigate this, first check the status of your Falco pods. 
```bash
uds zarf tools kubectl get pods -n falco
```

If the status of any of your Falco pods are failing, check the logs.
```bash
uds zarf tools kubectl logs -n falco <pod_name>
```

If you see an error similar to below, check what the limit is by running `cat /proc/sys/fs/inotify/max_user_instances`. 
```bash
Sun Aug 23 02:32:44 2026: Hostname value has been overridden via environment variable to: k3d-uds-server-0
Events detected: 0
Rule counts by severity:
Triggered rules by rule name:
Error: could not initialize inotify handler
```

If your `fs.inotify.max_user_instances` limit is 128, increase it using `sysctl`. 
```bash
sudo sysctl -w fs.inotify.max_user_instances=8192
```

**Clean Up.** When you're done, use `k3d` to delete the k3s cluster created. 
```bash
k3d cluster delete uds
```
