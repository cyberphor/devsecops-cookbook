# Deploy UDS Core onto a Kubernetes Cluster

## Recipe
**Step 1.** Install [k3d](../setup/README.md#install-k3d). 

**Step 2.** Install the [UDS CLI](../setup/README.md#install-the-uds-cli). 

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

**Step 4.** To verify all UDS Core pods are working, run the command below. NOTE: There should be no output.
```bash
uds zarf tools kubectl get pods -A --no-headers | grep -Ev '(Running|Completed)'
```

**Step 5.** If they are not already in your `/etc/hosts` file, add DNS entries for each of the UDS Core services you just deployed. 
```bash
echo "127.0.0.1 keycloak.admin.uds.dev" | sudo tee -a /etc/hosts
echo "127.0.0.1 grafana.admin.uds.dev" | sudo tee -a /etc/hosts
echo "127.0.0.1 sso.uds.dev" | sudo tee -a /etc/hosts
echo "127.0.0.1 portal.uds.dev" | sudo tee -a /etc/hosts
```

If you completed this recipe using WSL, make sure to also add the DNS entries to your Windows host. NOTE: this will require opening a Terminal window as an administrator.  
```powershell
powershell_ise.exe C:\Windows\System32\drivers\etc\hosts
```

## Troubleshooting
**Injecting records for hostAliases**  
If you're doing this in WSL and it hangs at `Injecting records for hostAliases (incl. host.k3d.internal) and for 2 network members into CoreDNS configmap...`, try updating WSL to the latest version. 

**Performing Helm install chart=falco**  
If it hangs at `performing Helm install chart=falco`, it may be because your kernel's `fs.inotify.max_user_instances` limit is too low. To investigate this, first check the status of your Falco pods. 
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

To increase your `fs.inotify.max_user_instances` limit, use `sysctl`. 
```bash
sudo sysctl -w fs.inotify.max_user_instances=8192
```

## Cleaning Up
When you're done, use `k3d` to delete the k3s cluster created. 
```bash
k3d cluster delete uds
```
